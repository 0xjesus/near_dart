import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:near_dart/near_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shared_prefs_key_store.dart';
import 'wallet_option.dart';

/// One controller for every supported NEAR wallet.
///
/// ```dart
/// final wallet = NearWalletController(
///   network: MyNearWalletNetwork.testnet,
///   contractId: AccountId('myapp.testnet'),
///   methodNames: const ['my_method'],
/// );
/// await wallet.init();
///
/// // In your UI: NearConnectButton(controller: wallet) shows a wallet picker,
/// // or connect programmatically:
/// await wallet.connect(wallet: NearWalletOption.intear);
///
/// // Then one API, whatever the wallet:
/// final signer = await wallet.signer();          // local function-call key
/// await wallet.signMessage(payload);             // NEP-413 (Intear, HOT)
/// await wallet.sendTransactions(transactions);   // wallet-signed txs
/// ```
///
/// Wallet flows differ and the controller adapts automatically:
///
/// - **MyNearWallet** — browser redirect; the result arrives via [init]'s
///   deep-link/URL handling. Supported until its announced sunset.
/// - **Intear** — native app + WebSocket bridge; resolves in place.
/// - **HOT** — native/Telegram app + HTTP relay; resolves in place
///   (mainnet only).
class NearWalletController extends ChangeNotifier {
  NearWalletController({
    required this.network,
    required this.contractId,
    this.methodNames = const [],
    this.callbackScheme = 'nearsdk',
    this.appOrigin,
    KeyStore? keyStore,
    NearRpcClient? client,
  }) : keyStore = keyStore ?? SharedPrefsKeyStore(),
       client =
           client ??
           (network == MyNearWalletNetwork.mainnet
               ? NearRpcClient.mainnet()
               : NearRpcClient.testnet());

  /// Which network to connect to.
  final MyNearWalletNetwork network;

  /// The contract the provisioned function-call key may call.
  final AccountId contractId;

  /// Methods the key is scoped to (empty = all methods on [contractId]).
  final List<String> methodNames;

  /// Custom URL scheme used for the mobile deep-link callback
  /// (configure it in AndroidManifest.xml / Info.plist).
  final String callbackScheme;

  /// How this app is presented inside HOT Wallet (a URL or name).
  final String? appOrigin;

  /// Where keys are persisted (must survive the redirect).
  final KeyStore keyStore;

  /// RPC client used for local signing after connect.
  final NearRpcClient client;

  static const _optionPrefsKey = 'near_wallet_connect_option';
  static const _hotAccountPrefsKey = 'near_wallet_connect_hot_account';

  WalletAccount? _account;
  NearWalletOption? _walletOption;
  bool _busy = false;
  String? _error;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;

  /// The connected account, or null.
  WalletAccount? get account => _account;

  /// Which wallet the connected account came from, or null.
  NearWalletOption? get walletOption => _walletOption;

  /// Whether a wallet is connected.
  bool get isConnected => _account != null;

  /// Whether a connect/callback operation is in flight.
  bool get busy => _busy;

  /// The last error message, if any.
  String? get error => _error;

  /// The wallets available on [network].
  List<NearWalletOption> get availableWallets =>
      NearWalletOption.available(network);

  String get _networkId =>
      network == MyNearWalletNetwork.mainnet ? 'mainnet' : 'testnet';

  Future<bool> _launch(Uri uri) => launchUrl(
    uri,
    webOnlyWindowName: kIsWeb ? '_self' : null,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
  );

  // ── adapters ─────────────────────────────────────────────────────────────

  MyNearWalletAdapter _mnwAdapter() {
    final base = kIsWeb
        ? Uri.base.replace(query: '').removeFragment().toString()
        : '$callbackScheme://callback';
    return MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: contractId,
        successUrl: kIsWeb ? base : '$base/success',
        failureUrl: kIsWeb ? base : '$base/failure',
        network: network,
      ),
      keyStore: keyStore,
      launchUrl: _launch,
    );
  }

  IntearWalletAdapter _intearAdapter() => IntearWalletAdapter(
    config: IntearWalletConfig(
      networkId: _networkId,
      origin: appOrigin ?? '$callbackScheme://app',
      contractId: contractId,
      methodNames: methodNames.isEmpty ? null : methodNames,
    ),
    keyStore: keyStore,
    launchUrl: _launch,
  );

  HotWalletAdapter _hotAdapter() => HotWalletAdapter(
    config: HotWalletConfig(origin: appOrigin ?? '$callbackScheme://app'),
    launchUrl: _launch,
  );

  // ── lifecycle ────────────────────────────────────────────────────────────

  /// Restores any existing session and processes a pending sign-in callback.
  ///
  /// Call once at startup. On web it reads `Uri.base`; on mobile it consumes
  /// the initial deep link and listens for subsequent ones.
  Future<void> init() async {
    await _restore();
    if (kIsWeb) {
      if (_looksLikeCallback(Uri.base)) await _handleCallback(Uri.base);
      return;
    }
    _appLinks = AppLinks();
    final initial = await _appLinks!.getInitialLink();
    if (initial != null && _looksLikeCallback(initial)) {
      await _handleCallback(initial);
    }
    _linkSub = _appLinks!.uriLinkStream.listen((uri) {
      if (_looksLikeCallback(uri)) _handleCallback(uri);
    });
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _walletOption = NearWalletOption.values
        .asNameMap()[prefs.getString(_optionPrefsKey)];

    if (_walletOption == NearWalletOption.hot) {
      final accountId = prefs.getString(_hotAccountPrefsKey);
      if (accountId != null) {
        _account = WalletAccount(
          accountId: AccountId(accountId),
          publicKey: PublicKey('ed25519:11111111111111111111111111111111'),
        );
        notifyListeners();
      }
      return;
    }

    // MyNearWallet and Intear both persist a key in the key store.
    final accounts = await _mnwAdapter().getAccounts();
    if (accounts.isNotEmpty) {
      _account = accounts.first;
      _walletOption ??= NearWalletOption.myNearWallet;
      notifyListeners();
    }
  }

  static bool _looksLikeCallback(Uri uri) =>
      uri.queryParameters.containsKey('account_id') ||
      uri.queryParameters.containsKey('errorCode');

  // ── connect / disconnect ─────────────────────────────────────────────────

  /// Starts the connect flow with the chosen [wallet].
  ///
  /// MyNearWallet redirects to the browser (the result arrives via [init]);
  /// Intear and HOT open their native apps and resolve in place.
  Future<void> connect({
    NearWalletOption wallet = NearWalletOption.myNearWallet,
  }) async {
    if (!availableWallets.contains(wallet)) {
      _set(
        busy: false,
        error: '${wallet.label} is not available on $_networkId',
      );
      return;
    }
    _set(busy: true, error: null);
    try {
      switch (wallet) {
        case NearWalletOption.myNearWallet:
          await _saveOption(wallet);
          await _mnwAdapter().signIn(
            contractId: contractId,
            methodNames: methodNames,
          );
        // On web the page navigates away here; the result arrives in init().
        case NearWalletOption.intear:
          final result = await _intearAdapter().signIn();
          _account = result.account;
          _walletOption = wallet;
          await _saveOption(wallet);
          _set(busy: false);
        case NearWalletOption.hot:
          final account = await _hotAdapter().signIn();
          _account = account;
          _walletOption = wallet;
          await _saveOption(wallet, hotAccountId: account.accountId.value);
          _set(busy: false);
      }
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  Future<void> _saveOption(
    NearWalletOption option, {
    String? hotAccountId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_optionPrefsKey, option.name);
    if (hotAccountId != null) {
      await prefs.setString(_hotAccountPrefsKey, hotAccountId);
    }
  }

  Future<void> _handleCallback(Uri uri) async {
    // Only a pending sign-in makes this callback ours. Other wallet
    // callbacks can carry the same parameters (e.g. MyNearWallet's /sign
    // appends account_id next to transactionHashes) and must not clobber
    // an existing session.
    final signInPending = await keyStore.getPendingKey() != null;
    if (!signInPending && _account != null) return;

    _set(busy: true);
    try {
      final account = await _mnwAdapter().completeSignIn(uri);
      if (account != null) {
        _account = account;
        _walletOption = NearWalletOption.myNearWallet;
        await _saveOption(NearWalletOption.myNearWallet);
        _set(busy: false);
      } else {
        _set(busy: false, error: signInPending ? 'Sign-in cancelled' : null);
      }
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  /// Disconnects and clears the stored session.
  Future<void> disconnect() async {
    final account = _account;
    if (account != null) await keyStore.removeKey(account.accountId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_optionPrefsKey);
    await prefs.remove(_hotAccountPrefsKey);
    _account = null;
    _walletOption = null;
    notifyListeners();
  }

  // ── the unified API ──────────────────────────────────────────────────────

  /// A ready-to-use [Account] signing locally with the stored function-call
  /// key, or null if not connected / the wallet stored no key.
  ///
  /// Available after a MyNearWallet or Intear connect. Function-call keys
  /// cannot attach deposits — use [sendTransactions] for payments.
  Future<Account?> signer() async {
    final a = _account;
    if (a == null) return null;
    final kp = await keyStore.getKey(a.accountId);
    if (kp == null) return null;
    return Account(accountId: a.accountId, keyPair: kp, client: client);
  }

  /// Signs a NEP-413 message with the user's wallet key (Intear, HOT).
  Future<Nep413SignedMessage> signMessage(Nep413Payload payload) async {
    final a = _account;
    if (a == null) throw StateError('Connect a wallet first');
    switch (_walletOption) {
      case NearWalletOption.intear:
        return _intearAdapter().signMessage(
          accountId: a.accountId,
          payload: payload,
        );
      case NearWalletOption.hot:
        return _hotAdapter().signMessage(payload: payload);
      default:
        throw UnsupportedError(
          'MyNearWallet signs messages via browser redirect — use '
          'MyNearWalletAdapter.buildSignMessageUrl for that flow.',
        );
    }
  }

  /// Signs and sends [transactions] with the user's wallet (Intear, HOT) and
  /// returns the execution outcomes.
  ///
  /// Transactions use the wallet-selector JSON shape:
  /// `[{"receiverId": "...", "actions": [{"type": "FunctionCall", ...}]}]`.
  Future<List<dynamic>> sendTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    final a = _account;
    if (a == null) throw StateError('Connect a wallet first');
    switch (_walletOption) {
      case NearWalletOption.intear:
        return _intearAdapter().signAndSendTransactions(
          accountId: a.accountId,
          transactions: transactions,
        );
      case NearWalletOption.hot:
        return _hotAdapter().signAndSendTransactions(
          transactions: transactions,
        );
      default:
        throw UnsupportedError(
          'MyNearWallet signs transactions via browser redirect — use '
          'MyNearWalletAdapter.buildTransactionUrl for that flow, or '
          'signer() for gas-only calls with the function-call key.',
        );
    }
  }

  void _set({bool? busy, String? error}) {
    if (busy != null) _busy = busy;
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }
}
