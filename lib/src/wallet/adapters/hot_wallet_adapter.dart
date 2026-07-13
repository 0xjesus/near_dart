import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' show sha1;
import 'package:http/http.dart' as http;

import '../../diagnostics/near_diagnostics.dart';
import '../../diagnostics/near_errors.dart';
import '../../encoding/base58.dart';
import '../../types/primitives.dart';
import '../nep413.dart';
import '../wallet_adapter.dart' show WalletAccount;

/// Configuration for [HotWalletAdapter].
class HotWalletConfig {
  const HotWalletConfig({
    required this.origin,
    this.proxyUrl = 'https://h4n.app',
    this.timeUrl = 'https://api0.herewallet.app/api/v1/web/time',
    this.requestDeadline = const Duration(minutes: 1),
    this.pollInterval = const Duration(seconds: 3),
    this.responseTimeout = const Duration(minutes: 5),
  });

  /// Shown to the user in HOT Wallet as the requesting app (a URL or name).
  final String origin;

  /// The HOT relay that queues requests/responses between app and wallet.
  final String proxyUrl;

  /// HOT's time service (keeps deadlines correct despite clock skew).
  final String timeUrl;

  /// How long the queued request stays valid for the wallet to pick up.
  final Duration requestDeadline;

  /// How often to poll the relay for the wallet's response.
  final Duration pollInterval;

  /// How long to wait for the user to approve in the wallet.
  final Duration responseTimeout;
}

/// Connects to HOT Wallet (ex-HERE) via its HTTP relay + deep links.
///
/// **Mainnet only** — HOT Wallet does not support testnet.
///
/// Flow per operation: the request is base58-encoded and queued on the relay
/// (`POST {proxy}/{sha1(query)}/request`), the wallet app is opened with
/// `hotwallet://hotcall-{requestId}` (Telegram fallback:
/// `https://t.me/hot_wallet/app?startapp=hotcall-{requestId}`), and the
/// response is polled from `GET {proxy}/{requestId}/response` — no inbound
/// deep link is needed.
class HotWalletAdapter {
  HotWalletAdapter({
    required this.config,
    required this.launchUrl,
    http.Client? httpClient,
    this.logger,
  }) : _http = httpClient ?? http.Client();

  final HotWalletConfig config;

  /// Opens the `hotwallet://` deep link (e.g. url_launcher's `launchUrl`).
  final Future<bool> Function(Uri uri) launchUrl;

  /// Receives safe operational diagnostics for wallet flows.
  final NearLogger? logger;

  final http.Client _http;

  /// Asks HOT Wallet for the connected account.
  Future<WalletAccount> signIn() => _runWalletFlow('signIn', (flow) async {
    final payload = await _request(
      'near:signIn',
      const <String, dynamic>{},
      flow,
    );
    return WalletAccount(
      accountId: _accountId(payload['accountId']),
      publicKey: _publicKey(payload['publicKey']),
    );
  });

  /// Signs a NEP-413 message with the user's wallet key.
  Future<Nep413SignedMessage> signMessage({required Nep413Payload payload}) =>
      _runWalletFlow('signMessage', (flow) async {
        final res = await _request('near:signMessage', {
          'message': payload.message,
          'nonce': payload.nonce,
          'recipient': payload.recipient,
          if (payload.callbackUrl != null) 'callbackUrl': payload.callbackUrl,
        }, flow);
        final signed = _signedMessage(res);
        try {
          if (!await verifyNep413Signature(payload: payload, signed: signed)) {
            throw const HotWalletException.signatureVerification();
          }
        } on HotWalletException {
          rethrow;
        } catch (_) {
          throw const HotWalletException.signatureVerification();
        }
        return signed;
      });

  Nep413SignedMessage _signedMessage(Map<String, dynamic> response) {
    final signature = response['signature'];
    if (signature is! String || signature.isEmpty) {
      throw const HotWalletException.invalidResponse();
    }
    return Nep413SignedMessage(
      accountId: _accountId(response['accountId']),
      publicKey: _publicKey(response['publicKey']),
      signature: signature,
    );
  }

  AccountId _accountId(Object? value) {
    try {
      if (value is! String || value.isEmpty) throw const FormatException();
      return AccountId(value);
    } catch (_) {
      throw const HotWalletException.invalidResponse();
    }
  }

  PublicKey _publicKey(Object? value) {
    try {
      if (value is! String || value.isEmpty) throw const FormatException();
      return PublicKey(value);
    } catch (_) {
      throw const HotWalletException.invalidResponse();
    }
  }

  /// Signs and sends transactions (wallet-selector JSON shape:
  /// `[{"receiverId": ..., "actions": [...]}]`). Returns the outcomes.
  Future<List<dynamic>> signAndSendTransactions({
    required List<Map<String, dynamic>> transactions,
  }) => _runWalletFlow('signAndSendTransactions', (flow) async {
    final res = await _request('near:signAndSendTransactions', {
      'transactions': transactions,
    }, flow);
    final outcomes = res['transactions'] ?? const <dynamic>[];
    if (outcomes is! List) {
      throw const HotWalletException.invalidResponse();
    }
    return outcomes;
  });

  // ── internals ────────────────────────────────────────────────────────────

  /// Relay clock (falls back to the local clock).
  Future<int> _timestampMs(_HotWalletFlow flow) async {
    try {
      final timeout = _remaining(flow);
      final res = await _http.get(Uri.parse(config.timeUrl)).timeout(timeout);
      final ts = BigInt.parse('${(jsonDecode(res.body) as Map)['ts']}');
      return (ts ~/ BigInt.from(10).pow(12)).toInt() * 1000;
    } on HotWalletException {
      rethrow;
    } catch (_) {
      _remaining(flow);
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Object request,
    _HotWalletFlow flow,
  ) async {
    final ts = await _timestampMs(flow);
    final query = base58Encode(
      utf8.encode(
        jsonEncode({
          'method': method,
          'request': request,
          'deadline': ts + config.requestDeadline.inMilliseconds,
          'id': _uuid4(),
          r'$hot': true,
          'origin': config.origin,
        }),
      ),
    );
    final requestId = sha1.convert(utf8.encode(query)).toString();

    late final http.Response created;
    try {
      final timeout = _remaining(flow);
      created = await _http
          .post(
            Uri.parse('${config.proxyUrl}/$requestId/request'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'data': query}),
          )
          .timeout(timeout);
    } on HotWalletException {
      rethrow;
    } on TimeoutException {
      throw const HotWalletException.timeout();
    } catch (_) {
      throw const HotWalletException.transport();
    }
    if (created.statusCode < 200 || created.statusCode >= 300) {
      throw _relayHttpFailure(created.statusCode);
    }

    late final bool launched;
    try {
      final timeout = _remaining(flow);
      launched = await launchUrl(
        Uri.parse('hotwallet://hotcall-$requestId'),
      ).timeout(timeout);
    } on HotWalletException {
      rethrow;
    } on TimeoutException {
      throw const HotWalletException.timeout();
    } catch (_) {
      throw const HotWalletException.deepLink();
    }
    if (!launched) {
      throw const HotWalletException.deepLink();
    }

    while (true) {
      final beforeDelay = _remaining(flow);
      final delay = config.pollInterval < beforeDelay
          ? config.pollInterval
          : beforeDelay;
      await Future<void>.delayed(delay);
      late final http.Response res;
      try {
        final timeout = _remaining(flow);
        res = await _http
            .get(
              Uri.parse('${config.proxyUrl}/$requestId/response'),
              headers: {'content-type': 'application/json'},
            )
            .timeout(timeout);
      } on HotWalletException {
        rethrow;
      } on TimeoutException {
        throw const HotWalletException.timeout();
      } catch (_) {
        throw const HotWalletException.transport();
      }
      if (res.statusCode == 204 || res.statusCode == 404) continue;
      _callbackReceived(flow);
      if (res.statusCode != 200) throw _relayHttpFailure(res.statusCode);
      final data = _decodeRelayResponse(res.body);
      if (data['success'] == true) {
        final payload = data['payload'];
        if (payload is! Map) {
          throw const HotWalletException.invalidResponse();
        }
        return payload.cast<String, dynamic>();
      }
      if (data['success'] == false) {
        final payload = data['payload'];
        final reason = payload is String ? payload.toLowerCase() : '';
        if (reason.contains('unsupported')) {
          throw const HotWalletException.unsupported();
        }
        throw const HotWalletException.rejected();
      }
      throw const HotWalletException.invalidResponse();
    }
  }

  Duration _remaining(_HotWalletFlow flow) {
    final remaining = config.responseTimeout - flow.stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw const HotWalletException.timeout();
    }
    return remaining;
  }

  Map<String, dynamic> _decodeRelayResponse(String body) {
    try {
      final envelope = jsonDecode(body);
      if (envelope is! Map || envelope['data'] is! String) {
        throw const FormatException();
      }
      final decoded = jsonDecode(envelope['data'] as String);
      if (decoded is! Map) throw const FormatException();
      return decoded.cast<String, dynamic>();
    } catch (_) {
      throw const HotWalletException.invalidResponse();
    }
  }

  HotWalletException _relayHttpFailure(int statusCode) {
    if (statusCode == 408) return const HotWalletException.timeout();
    if (statusCode == 429) return const HotWalletException.rateLimited();
    if (statusCode >= 500) return const HotWalletException.transport();
    return const HotWalletException.invalidResponse();
  }

  Future<T> _runWalletFlow<T>(
    String operation,
    Future<T> Function(_HotWalletFlow flow) action,
  ) async {
    final flow = _HotWalletFlow(operation);
    _emitWalletEvent(
      NearLogEventType.walletFlowOpened,
      operation: operation,
      stopwatch: flow.stopwatch,
      outcome: 'opened',
    );
    try {
      final result = await action(flow);
      _emitWalletEvent(
        NearLogEventType.walletFlowSucceeded,
        operation: operation,
        stopwatch: flow.stopwatch,
        outcome: 'success',
      );
      return result;
    } catch (error, stackTrace) {
      final normalized = _normalizeHotError(error);
      _emitWalletEvent(
        NearLogEventType.walletFlowFailed,
        operation: operation,
        stopwatch: flow.stopwatch,
        outcome: 'failure',
        failureCode: normalized.code,
      );
      Error.throwWithStackTrace(normalized, stackTrace);
    }
  }

  NearSdkException _normalizeHotError(Object error) {
    if (error is NearSdkException) return error;
    if (error is TimeoutException) return const HotWalletException.timeout();
    if (error is UnsupportedError) {
      return const HotWalletException.unsupported();
    }
    if (error is FormatException ||
        error is TypeError ||
        error is ArgumentError) {
      return const HotWalletException.invalidResponse();
    }
    return const HotWalletException.unknown();
  }

  void _callbackReceived(_HotWalletFlow flow) {
    if (flow.callbackReceived) return;
    flow.callbackReceived = true;
    _emitWalletEvent(
      NearLogEventType.walletCallbackReceived,
      operation: flow.operation,
      stopwatch: flow.stopwatch,
      outcome: 'received',
    );
  }

  void _emitWalletEvent(
    NearLogEventType type, {
    required String operation,
    required Stopwatch stopwatch,
    required String outcome,
    NearErrorCode? failureCode,
  }) {
    emitNearLog(
      logger,
      NearLogEvent(
        level: failureCode == null ? NearLogLevel.info : NearLogLevel.error,
        type: type,
        operation: operation,
        metadata: <String, Object?>{
          'walletId': 'hot',
          'durationMs': stopwatch.elapsedMilliseconds,
          'outcome': outcome,
          if (failureCode != null) 'failureCode': failureCode.name,
        },
      ),
    );
  }

  static String _uuid4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class _HotWalletFlow {
  _HotWalletFlow(this.operation) : stopwatch = (Stopwatch()..start());

  final String operation;
  final Stopwatch stopwatch;
  bool callbackReceived = false;
}

/// The wallet returned an error (e.g. the user rejected the request).
class HotWalletException extends NearSdkException {
  const HotWalletException(
    String message, {
    NearErrorCode code = NearErrorCode.userRejected,
    bool retryable = false,
  }) : super(code: code, message: message, retryable: retryable);

  const HotWalletException.rejected()
    : super(
        code: NearErrorCode.userRejected,
        message: 'The HOT Wallet request was rejected.',
      );

  const HotWalletException.invalidResponse()
    : super(
        code: NearErrorCode.walletResponseInvalid,
        message: 'HOT Wallet returned an invalid response.',
      );

  const HotWalletException.signatureVerification()
    : super(
        code: NearErrorCode.signatureVerificationFailed,
        message: 'The HOT Wallet signature could not be verified.',
      );

  const HotWalletException.deepLink()
    : super(
        code: NearErrorCode.deepLinkUnavailable,
        message: 'The HOT Wallet app could not be opened.',
      );

  const HotWalletException.timeout()
    : super(
        code: NearErrorCode.rpcTimeout,
        message: 'The HOT Wallet request timed out.',
        retryable: true,
      );

  const HotWalletException.transport()
    : super(
        code: NearErrorCode.rpcUnavailable,
        message: 'The HOT Wallet relay is unavailable.',
        retryable: true,
      );

  const HotWalletException.rateLimited()
    : super(
        code: NearErrorCode.rateLimited,
        message: 'The HOT Wallet relay rate limit was reached.',
        retryable: true,
      );

  const HotWalletException.unsupported()
    : super(
        code: NearErrorCode.unsupportedOperation,
        message: 'The HOT Wallet operation is unsupported.',
      );

  const HotWalletException.unknown()
    : super(
        code: NearErrorCode.unknown,
        message: 'The HOT Wallet request failed.',
      );

  @override
  String toString() => 'HotWalletException(code: $code, retryable: $retryable)';
}
