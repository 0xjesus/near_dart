import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' show sha1;
import 'package:http/http.dart' as http;

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
  }) : _http = httpClient ?? http.Client();

  final HotWalletConfig config;

  /// Opens the `hotwallet://` deep link (e.g. url_launcher's `launchUrl`).
  final Future<bool> Function(Uri uri) launchUrl;

  final http.Client _http;

  /// Asks HOT Wallet for the connected account.
  Future<WalletAccount> signIn() async {
    final payload = await _request('near:signIn', const <String, dynamic>{});
    return WalletAccount(
      accountId: AccountId(payload['accountId'] as String),
      publicKey: PublicKey(
        (payload['publicKey'] ?? 'ed25519:11111111111111111111111111111111')
            as String,
      ),
    );
  }

  /// Signs a NEP-413 message with the user's wallet key.
  Future<Nep413SignedMessage> signMessage({
    required Nep413Payload payload,
  }) async {
    final res = await _request('near:signMessage', {
      'message': payload.message,
      'nonce': payload.nonce,
      'recipient': payload.recipient,
      if (payload.callbackUrl != null) 'callbackUrl': payload.callbackUrl,
    });
    return Nep413SignedMessage(
      accountId: AccountId(res['accountId'] as String),
      publicKey: PublicKey(res['publicKey'] as String),
      signature: res['signature'] as String,
    );
  }

  /// Signs and sends transactions (wallet-selector JSON shape:
  /// `[{"receiverId": ..., "actions": [...]}]`). Returns the outcomes.
  Future<List<dynamic>> signAndSendTransactions({
    required List<Map<String, dynamic>> transactions,
  }) async {
    final res = await _request('near:signAndSendTransactions', {
      'transactions': transactions,
    });
    return (res['transactions'] ?? const []) as List<dynamic>;
  }

  // ── internals ────────────────────────────────────────────────────────────

  /// Relay clock (falls back to the local clock).
  Future<int> _timestampMs() async {
    try {
      final res = await _http
          .get(Uri.parse(config.timeUrl))
          .timeout(const Duration(seconds: 10));
      final ts = BigInt.parse('${(jsonDecode(res.body) as Map)['ts']}');
      return (ts ~/ BigInt.from(10).pow(12)).toInt() * 1000;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<Map<String, dynamic>> _request(String method, Object request) async {
    final ts = await _timestampMs();
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

    final created = await _http.post(
      Uri.parse('${config.proxyUrl}/$requestId/request'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'data': query}),
    );
    if (created.statusCode >= 300) {
      throw StateError('HOT relay rejected the request: ${created.body}');
    }

    final launched = await launchUrl(
      Uri.parse('hotwallet://hotcall-$requestId'),
    );
    if (!launched) {
      throw StateError('Could not open the HOT Wallet app');
    }

    final deadline = DateTime.now().add(config.responseTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(config.pollInterval);
      final res = await _http.get(
        Uri.parse('${config.proxyUrl}/$requestId/response'),
        headers: {'content-type': 'application/json'},
      );
      if (res.statusCode != 200) continue;
      final data =
          jsonDecode((jsonDecode(res.body) as Map)['data'] as String)
              as Map<String, dynamic>;
      if (data['success'] == true) {
        final payload = data['payload'];
        return payload is Map<String, dynamic>
            ? payload
            : <String, dynamic>{'value': payload};
      }
      throw HotWalletException('${data['payload'] ?? 'Request rejected'}');
    }
    throw HotWalletException('Timed out waiting for HOT Wallet');
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

/// The wallet returned an error (e.g. the user rejected the request).
class HotWalletException implements Exception {
  HotWalletException(this.message);
  final String message;

  @override
  String toString() => 'HotWalletException: $message';
}
