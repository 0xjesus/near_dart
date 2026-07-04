import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../borsh/transaction_serializer.dart' show sha256Hash;
import '../../crypto/key_pair.dart';
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
  }) : _connect = connectWebSocket ?? WebSocketChannel.connect;

  final IntearWalletConfig config;

  /// Persists the app session key across restarts (keyed by account id).
  final KeyStore keyStore;

  /// Opens the `intear://` deep link (e.g. url_launcher's `launchUrl`).
  final Future<bool> Function(Uri uri) launchUrl;

  final WebSocketChannel Function(Uri) _connect;

  /// Connects to the wallet. Optionally signs a NEP-413 [messageToSign]
  /// during the same approval (single user interaction).
  Future<IntearConnectionResult> signIn({
    Nep413Payload? messageToSign,
    String? state,
  }) async {
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
    );

    final accounts = (response['accounts'] ?? const []) as List<dynamic>;
    if (accounts.isEmpty) {
      throw StateError('Intear Wallet returned no accounts');
    }
    final accountId = AccountId((accounts.first as Map)['accountId'] as String);
    await keyStore.setKey(accountId, appKey);

    Nep413SignedMessage? signed;
    final sm = response['signedMessage'];
    if (sm is Map) {
      signed = Nep413SignedMessage(
        accountId: AccountId(sm['accountId'] as String),
        publicKey: PublicKey(sm['publicKey'] as String),
        signature: sm['signature'] as String,
      );
    }

    return IntearConnectionResult(
      account: WalletAccount(accountId: accountId, publicKey: appKey.publicKey),
      functionCallKeyAdded: (response['functionCallKeyAdded'] ?? false) as bool,
      walletUrl:
          (response['walletUrl'] ?? 'https://wallet.intear.tech') as String,
      signedMessage: signed,
    );
  }

  /// Signs a NEP-413 message with the user's wallet (full-access key).
  Future<Nep413SignedMessage> signMessage({
    required AccountId accountId,
    required Nep413Payload payload,
    String? state,
  }) async {
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
    );

    final sig = response['signature'] as Map;
    return Nep413SignedMessage(
      accountId: AccountId(sig['accountId'] as String),
      publicKey: PublicKey(sig['publicKey'] as String),
      signature: sig['signature'] as String,
    );
  }

  /// Signs and sends transactions through the wallet.
  ///
  /// [transactions] use the wallet-selector JSON shape:
  /// `[{"receiverId": "...", "actions": [{"type": "FunctionCall", "params":
  /// {...}}]}]`. Returns the RPC execution outcomes.
  Future<List<dynamic>> signAndSendTransactions({
    required AccountId accountId,
    required List<Map<String, dynamic>> transactions,
  }) async {
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
    );

    return (response['outcomes'] ?? const []) as List<dynamic>;
  }

  /// Forgets the stored session key for [accountId].
  Future<void> signOut(AccountId accountId) => keyStore.removeKey(accountId);

  // ── internals ────────────────────────────────────────────────────────────

  Future<KeyPairEd25519> _appKeyFor(AccountId accountId) async {
    final key = await keyStore.getKey(accountId);
    if (key == null) {
      throw StateError(
        'No Intear session for ${accountId.value} — call signIn() first.',
      );
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
  }) async {
    final channel = _connect(
      Uri.parse('${config.bridgeUrl}/api/session/create'),
    );
    try {
      final messages = StreamIterator(channel.stream);

      if (!await messages.moveNext().timeout(const Duration(seconds: 30))) {
        throw StateError('Intear bridge closed before issuing a session');
      }
      final session =
          jsonDecode(messages.current as String) as Map<String, dynamic>;
      final sessionId = session['session_id'] as String?;
      if (sessionId == null) {
        throw StateError('Intear bridge did not return a session_id');
      }
      channel.sink.add(jsonEncode({'type': type, 'data': data}));

      final launched = await launchUrl(
        Uri.parse('intear://$method?session_id=$sessionId'),
      );
      if (!launched) {
        throw StateError('Could not open the Intear Wallet app');
      }

      if (!await messages.moveNext().timeout(config.responseTimeout)) {
        throw StateError('Intear bridge closed without a wallet response');
      }
      final response =
          jsonDecode(messages.current as String) as Map<String, dynamic>;
      if (response['type'] == 'error') {
        throw IntearWalletException(
          (response['message'] ?? 'Unknown wallet error') as String,
        );
      }
      if (response['type'] != successType) {
        throw StateError('Unexpected wallet response: ${response['type']}');
      }
      return response;
    } finally {
      await channel.sink.close();
    }
  }
}

/// The wallet returned an error (e.g. the user rejected the request).
class IntearWalletException implements Exception {
  IntearWalletException(this.message);
  final String message;

  @override
  String toString() => 'IntearWalletException: $message';
}
