import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../borsh/transaction_serializer.dart' show sha256Hash;
import '../../crypto/key_pair.dart';
import '../../diagnostics/near_diagnostics.dart';
import '../../diagnostics/near_errors.dart';
import '../../encoding/base58.dart';
import '../../types/primitives.dart';
import '../key_store.dart';
import '../nep413.dart';
import '../wallet_adapter.dart' show WalletAccount;

/// Configuration for [IntearWalletAdapter].
class IntearWalletConfig {
  const IntearWalletConfig({
    required this.networkId,
    required this.origin,
    this.bridgeUrl = 'wss://logout-bridge-service.intear.tech',
    this.contractId,
    this.methodNames,
    this.responseTimeout = const Duration(minutes: 5),
  });

  /// `mainnet` or `testnet` (any string works for a custom localnet).
  final String networkId;

  /// How this app is presented inside Intear Wallet (a URL or name).
  final String origin;

  /// The Intear logout-bridge service that relays requests to the wallet app.
  final String bridgeUrl;

  /// When set, the wallet is asked to add the app key as a function-call key
  /// for this contract.
  final AccountId? contractId;

  /// Method names allowed for the function-call key (null = any).
  final List<String>? methodNames;

  /// How long to wait for the user to approve in the wallet.
  final Duration responseTimeout;
}

/// The result of [IntearWalletAdapter.signIn].
class IntearConnectionResult {
  const IntearConnectionResult({
    required this.account,
    required this.functionCallKeyAdded,
    required this.walletUrl,
    this.signedMessage,
  });

  final WalletAccount account;

  /// Whether the wallet added the app key as a function-call key.
  final bool functionCallKeyAdded;

  /// The wallet origin to use for subsequent (web popup) requests.
  final String walletUrl;

  /// Present when [IntearWalletAdapter.signIn] was given a `messageToSign`.
  final Nep413SignedMessage? signedMessage;
}

/// Connects to the Intear Wallet native app (mobile/desktop) via its
/// WebSocket bridge + `intear://` deep links.
///
/// Protocol: https://github.com/INTEARnear/wallet/blob/main/POSTMESSAGE_PROTOCOL.md
///
/// Each operation opens a bridge session, sends a signed request, launches
/// the wallet with `intear://<method>?session_id=…`, and awaits the wallet's
/// response over the same WebSocket — no inbound deep link is needed.
///
/// At [signIn] the adapter generates an ephemeral **app key**; the wallet
/// binds it to the session and every subsequent request is authenticated by
/// signing `sha256("{nonce}|{payload}")` with it.
///
/// **Android note:** the bridge session lives only as long as this app's
/// WebSocket. Android restricts background network shortly after the wallet
/// app comes to the foreground, so the user must approve before the OS cuts
/// the socket (about a minute for battery-exempted apps, less otherwise).
/// Long approvals — e.g. accepting the function-call-key grant, which sends
/// an on-chain transaction — may exceed that window; the connect itself
/// completes in seconds and is unaffected in practice.
class IntearWalletAdapter {
  IntearWalletAdapter({
    required this.config,
    required this.keyStore,
    required this.launchUrl,
    WebSocketChannel Function(Uri)? connectWebSocket,
    this.logger,
  }) : _connect = connectWebSocket ?? WebSocketChannel.connect;

  final IntearWalletConfig config;

  /// Persists the app session key across restarts (keyed by account id).
  final KeyStore keyStore;

  /// Opens the `intear://` deep link (e.g. url_launcher's `launchUrl`).
  final Future<bool> Function(Uri uri) launchUrl;

  /// Receives safe operational diagnostics for wallet flows.
  final NearLogger? logger;

  final WebSocketChannel Function(Uri) _connect;

  /// Connects to the wallet. Optionally signs a NEP-413 [messageToSign]
  /// during the same approval (single user interaction).
  Future<IntearConnectionResult> signIn({
    Nep413Payload? messageToSign,
    String? state,
  }) => _runWalletFlow('signIn', (flow) async {
    final appKey = await KeyPairEd25519.generate();

    // V2 connect message: `origin` is required by the wallet;
    // `functionCallPublicKey` is used by newer wallets and ignored by older
    // ones (which use the auth key as the function-call key).
    final messagePayload = <String, dynamic>{
      'origin': config.origin,
      if (messageToSign != null)
        'messageToSign': _nep413Json(messageToSign, state),
      if (config.contractId != null)
        'functionCallPublicKey': appKey.publicKey.value,
    };
    final message = jsonEncode(messagePayload);
    final nonce = DateTime.now().millisecondsSinceEpoch;

    final data = <String, dynamic>{
      'publicKey': appKey.publicKey.value,
      'networkId': config.networkId,
      'nonce': nonce,
      'message': message,
      'signature': await _signRequest(appKey, nonce, message),
      'version': 'V2',
      'actualOrigin': config.origin,
      if (config.contractId != null) 'contractId': config.contractId!.value,
      if (config.methodNames != null) 'methodNames': config.methodNames,
    };

    final response = await _bridgeRequest(
      method: 'connect',
      type: 'signIn',
      data: data,
      successType: 'connected',
      flow: flow,
    );
    final accountId = _connectedAccount(response);
    final signed = messageToSign == null
        ? null
        : await _verifiedSignedMessage(
            response['signedMessage'],
            payload: messageToSign,
            expectedAccountId: accountId,
            required: true,
          );
    final functionCallKeyAdded = response['functionCallKeyAdded'] ?? false;
    final walletUrl = response['walletUrl'] ?? 'https://wallet.intear.tech';
    if (functionCallKeyAdded is! bool ||
        walletUrl is! String ||
        walletUrl.isEmpty) {
      throw const IntearWalletException.invalidResponse();
    }

    await keyStore.setKey(accountId, appKey);
    return IntearConnectionResult(
      account: WalletAccount(accountId: accountId, publicKey: appKey.publicKey),
      functionCallKeyAdded: functionCallKeyAdded,
      walletUrl: walletUrl,
      signedMessage: signed,
    );
  });

  /// Signs a NEP-413 message with the user's wallet (full-access key).
  Future<Nep413SignedMessage> signMessage({
    required AccountId accountId,
    required Nep413Payload payload,
    String? state,
  }) => _runWalletFlow('signMessage', (flow) async {
    final appKey = await _appKeyFor(accountId);
    final message = _nep413Json(payload, state);
    final nonce = DateTime.now().millisecondsSinceEpoch;

    final response = await _bridgeRequest(
      method: 'sign-message',
      type: 'signMessage',
      data: {
        'message': message,
        'accountId': accountId.value,
        'publicKey': appKey.publicKey.value,
        'nonce': nonce,
        'signature': await _signRequest(appKey, nonce, message),
      },
      successType: 'signed',
      flow: flow,
    );

    return (await _verifiedSignedMessage(
      response['signature'],
      payload: payload,
      expectedAccountId: accountId,
      required: true,
    ))!;
  });

  AccountId _connectedAccount(Map<String, dynamic> response) {
    try {
      final accounts = response['accounts'];
      if (accounts is! List || accounts.isEmpty || accounts.first is! Map) {
        throw const FormatException();
      }
      final value = (accounts.first as Map)['accountId'];
      if (value is! String || value.isEmpty) {
        throw const FormatException();
      }
      return AccountId(value);
    } catch (_) {
      throw const IntearWalletException.invalidResponse();
    }
  }

  Future<Nep413SignedMessage?> _verifiedSignedMessage(
    Object? value, {
    required Nep413Payload? payload,
    required AccountId expectedAccountId,
    required bool required,
  }) async {
    if (value == null && !required) return null;
    if (value is! Map || payload == null) {
      throw const IntearWalletException.invalidResponse();
    }

    late final Nep413SignedMessage signed;
    try {
      final accountId = value['accountId'];
      final publicKey = value['publicKey'];
      final signature = value['signature'];
      if (accountId is! String ||
          accountId.isEmpty ||
          publicKey is! String ||
          publicKey.isEmpty ||
          signature is! String ||
          signature.isEmpty) {
        throw const FormatException();
      }
      signed = Nep413SignedMessage(
        accountId: AccountId(accountId),
        publicKey: PublicKey(publicKey),
        signature: signature,
      );
    } catch (_) {
      throw const IntearWalletException.invalidResponse();
    }

    if (signed.accountId != expectedAccountId) {
      throw const IntearWalletException.accountMismatch();
    }
    try {
      if (!await verifyNep413Signature(payload: payload, signed: signed)) {
        throw const IntearWalletException.signatureVerification();
      }
    } on IntearWalletException {
      rethrow;
    } catch (_) {
      throw const IntearWalletException.signatureVerification();
    }
    return signed;
  }

  Future<T> _runWalletFlow<T>(
    String operation,
    Future<T> Function(_IntearWalletFlow flow) action,
  ) async {
    final flow = _IntearWalletFlow(operation);
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
      final normalized = _normalizeIntearError(error);
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

  /// Signs and sends transactions through the wallet.
  ///
  /// [transactions] use the wallet-selector JSON shape:
  /// `[{"receiverId": "...", "actions": [{"type": "FunctionCall", "params":
  /// {...}}]}]`. Returns the RPC execution outcomes.
  Future<List<dynamic>> signAndSendTransactions({
    required AccountId accountId,
    required List<Map<String, dynamic>> transactions,
  }) => _runWalletFlow('signAndSendTransactions', (flow) async {
    final appKey = await _appKeyFor(accountId);
    final txJson = jsonEncode(transactions);
    final nonce = DateTime.now().millisecondsSinceEpoch;

    final response = await _bridgeRequest(
      method: 'send-transactions',
      type: 'signAndSendTransactions',
      data: {
        'accountId': accountId.value,
        'publicKey': appKey.publicKey.value,
        'nonce': nonce,
        'signature': await _signRequest(appKey, nonce, txJson),
        'transactions': txJson,
        'mode': 'Send',
      },
      successType: 'sent',
      flow: flow,
    );

    final outcomes = response['outcomes'] ?? const <dynamic>[];
    if (outcomes is! List) {
      throw const IntearWalletException.invalidResponse();
    }
    return outcomes;
  });

  /// Forgets the stored session key for [accountId].
  Future<void> signOut(AccountId accountId) => keyStore.removeKey(accountId);

  // ── internals ────────────────────────────────────────────────────────────

  Future<KeyPairEd25519> _appKeyFor(AccountId accountId) async {
    final key = await keyStore.getKey(accountId);
    if (key == null) {
      throw IntearWalletNotConnectedException._at(StackTrace.current);
    }
    return key;
  }

  /// `ed25519:<base58 sig>` over `sha256(utf8("{nonce}|{payload}"))`.
  Future<String> _signRequest(
    KeyPairEd25519 key,
    int nonce,
    String payload,
  ) async {
    final hash = sha256Hash(utf8.encode('$nonce|$payload'));
    final signature = await key.sign(hash);
    return 'ed25519:${base58Encode(signature)}';
  }

  /// NEP-413 payload as Intear's stringified JSON (nonce as a 32-int array).
  String _nep413Json(Nep413Payload payload, String? state) => jsonEncode({
    'message': payload.message,
    'nonce': payload.nonce,
    'recipient': payload.recipient,
    'callbackUrl': payload.callbackUrl,
    'state': state,
  });

  /// Creates a bridge session, sends the request, opens the wallet deep link
  /// and awaits the wallet's response.
  Future<Map<String, dynamic>> _bridgeRequest({
    required String method,
    required String type,
    required Map<String, dynamic> data,
    required String successType,
    required _IntearWalletFlow flow,
  }) async {
    WebSocketChannel? channel;
    try {
      channel = _connect(Uri.parse('${config.bridgeUrl}/api/session/create'));
      final messages = StreamIterator(channel.stream);

      if (!await messages.moveNext().timeout(const Duration(seconds: 30))) {
        throw const IntearWalletException.transport();
      }
      late final Map<String, dynamic> session;
      try {
        final current = messages.current;
        if (current is! String) throw const FormatException();
        session = (jsonDecode(current) as Map).cast<String, dynamic>();
      } catch (_) {
        throw const IntearWalletException.invalidResponse();
      }
      final sessionId = session['session_id'];
      if (sessionId is! String || sessionId.isEmpty) {
        throw const IntearWalletException.invalidResponse();
      }
      channel.sink.add(jsonEncode({'type': type, 'data': data}));

      late final bool launched;
      try {
        launched = await launchUrl(
          Uri.parse('intear://$method?session_id=$sessionId'),
        );
      } catch (_) {
        throw const IntearWalletException.deepLink();
      }
      if (!launched) {
        throw const IntearWalletException.deepLink();
      }

      if (!await messages.moveNext().timeout(config.responseTimeout)) {
        throw const IntearWalletException.transport();
      }
      _callbackReceived(flow);
      late final Map<String, dynamic> response;
      try {
        final current = messages.current;
        if (current is! String) throw const FormatException();
        response = (jsonDecode(current) as Map).cast<String, dynamic>();
      } catch (_) {
        throw const IntearWalletException.invalidResponse();
      }
      if (response['type'] == 'error') {
        final message = response['message'];
        final normalized = message is String ? message.toLowerCase() : '';
        if (normalized.contains('unsupported')) {
          throw const IntearWalletException.unsupported();
        }
        if (normalized.contains('reject') ||
            normalized.contains('declin') ||
            normalized.contains('cancel') ||
            normalized.contains('denied') ||
            normalized.contains('deny')) {
          throw const IntearWalletException.rejected();
        }
        throw const IntearWalletException.invalidResponse();
      }
      if (response['type'] != successType) {
        throw const IntearWalletException.invalidResponse();
      }
      return response;
    } on IntearWalletException {
      rethrow;
    } on TimeoutException {
      throw const IntearWalletException.timeout();
    } catch (_) {
      throw const IntearWalletException.transport();
    } finally {
      try {
        await channel?.sink.close();
      } catch (_) {
        // Closing diagnostics must not replace the operation result.
      }
    }
  }

  NearSdkException _normalizeIntearError(Object error) {
    if (error is NearSdkException) return error;
    if (error is TimeoutException) {
      return const IntearWalletException.timeout();
    }
    if (error is UnsupportedError) {
      return const IntearWalletException.unsupported();
    }
    if (error is FormatException ||
        error is TypeError ||
        error is ArgumentError) {
      return const IntearWalletException.invalidResponse();
    }
    return const IntearWalletException.unknown();
  }

  void _callbackReceived(_IntearWalletFlow flow) {
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
          'walletId': 'intear',
          'durationMs': stopwatch.elapsedMilliseconds,
          'outcome': outcome,
          if (failureCode != null) 'failureCode': failureCode.name,
        },
      ),
    );
  }
}

class _IntearWalletFlow {
  _IntearWalletFlow(this.operation) : stopwatch = (Stopwatch()..start());

  final String operation;
  final Stopwatch stopwatch;
  bool callbackReceived = false;
}

/// No app key is stored for the requested Intear account.
class IntearWalletNotConnectedException extends IntearWalletException
    implements StateError {
  const IntearWalletNotConnectedException()
    : _capturedStackTrace = null,
      super(
        'No Intear wallet session is available.',
        code: NearErrorCode.notConnected,
      );

  IntearWalletNotConnectedException._at(this._capturedStackTrace)
    : super(
        'No Intear wallet session is available.',
        code: NearErrorCode.notConnected,
      );

  final StackTrace? _capturedStackTrace;

  @override
  StackTrace? get stackTrace => _capturedStackTrace;
}

/// The wallet returned an error (e.g. the user rejected the request).
class IntearWalletException extends NearSdkException {
  const IntearWalletException(
    String message, {
    NearErrorCode code = NearErrorCode.userRejected,
    bool retryable = false,
  }) : super(code: code, message: message, retryable: retryable);

  const IntearWalletException.rejected()
    : super(
        code: NearErrorCode.userRejected,
        message: 'The Intear Wallet request was rejected.',
      );

  const IntearWalletException.invalidResponse()
    : super(
        code: NearErrorCode.walletResponseInvalid,
        message: 'Intear Wallet returned an invalid response.',
      );

  const IntearWalletException.accountMismatch()
    : super(
        code: NearErrorCode.accountMismatch,
        message: 'Intear Wallet returned a different account.',
      );

  const IntearWalletException.signatureVerification()
    : super(
        code: NearErrorCode.signatureVerificationFailed,
        message: 'The Intear Wallet signature could not be verified.',
      );

  const IntearWalletException.deepLink()
    : super(
        code: NearErrorCode.deepLinkUnavailable,
        message: 'The Intear Wallet app could not be opened.',
      );

  const IntearWalletException.timeout()
    : super(
        code: NearErrorCode.rpcTimeout,
        message: 'The Intear Wallet request timed out.',
        retryable: true,
      );

  const IntearWalletException.transport()
    : super(
        code: NearErrorCode.rpcUnavailable,
        message: 'The Intear Wallet bridge is unavailable.',
        retryable: true,
      );

  const IntearWalletException.unsupported()
    : super(
        code: NearErrorCode.unsupportedOperation,
        message: 'The Intear Wallet operation is unsupported.',
      );

  const IntearWalletException.unknown()
    : super(
        code: NearErrorCode.unknown,
        message: 'The Intear Wallet request failed.',
      );

  @override
  String toString() =>
      'IntearWalletException(code: $code, retryable: $retryable)';
}
