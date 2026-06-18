import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:near_dart/near_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shared_prefs_key_store.dart';

/// Drives the NEAR wallet connection lifecycle for a Flutter app, adapting to
/// the platform automatically:
///
/// - **Web**: full-page redirect to MyNearWallet, callback read from the app
///   URL on return.
/// - **Mobile/desktop**: launches the system browser and receives the
///   callback via the app's deep-link scheme (`app_links`).
///
/// On connect it provisions a **function-call key** and stores it, so
/// afterward you sign contract calls **locally** (via [signer]) with no more
/// redirects.
///
/// ```dart
/// final wallet = NearWalletController(
///   network: MyNearWalletNetwork.testnet,
///   contractId: AccountId('app.testnet'),
///   callbackScheme: 'myapp', // your nearsdk-style scheme on mobile
/// );
/// await wallet.init();        // process any pending callback + restore session
/// await wallet.connect();     // redirect to the wallet
/// // ...after callback...
/// final signer = await wallet.signer();
/// await signer!.callFunction(/* ... */); // signed locally
/// ```
class NearWalletController extends ChangeNotifier {
  NearWalletController({
    required this.network,
    required this.contractId,
    this.methodNames = const [],
    this.callbackScheme = 'nearsdk',
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

  /// Where keys are persisted (must survive the redirect).
  final KeyStore keyStore;

  /// RPC client used for local signing after connect.
  final NearRpcClient client;

  WalletAccount? _account;
  bool _busy = false;
  String? _error;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;

  /// The connected account, or null.
  WalletAccount? get account => _account;

  /// Whether a wallet is connected.
  bool get isConnected => _account != null;

  /// Whether a connect/callback operation is in flight.
  bool get busy => _busy;

  /// The last error message, if any.
  String? get error => _error;

  /// Returns a ready-to-use [Account] for the connected account (loading its
  /// stored function-call key), or null if not connected. Use it to sign
  /// contract calls locally — no redirect.
  ///
  /// ```dart
  /// final signer = await wallet.signer();
  /// await signer!.callFunction(contractId: ..., methodName: 'foo');
  /// ```
  Future<Account?> signer() async {
    final a = _account;
    if (a == null) return null;
    final kp = await keyStore.getKey(a.accountId);
    if (kp == null) return null;
    return Account(accountId: a.accountId, keyPair: kp, client: client);
  }

  MyNearWalletAdapter _adapter() {
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
      launchUrl: (uri) => launchUrl(
        uri,
        webOnlyWindowName: kIsWeb ? '_self' : null,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      ),
    );
  }

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
    final accounts = await _adapter().getAccounts();
    if (accounts.isNotEmpty) {
      _account = accounts.first;
      notifyListeners();
    }
  }

  static bool _looksLikeCallback(Uri uri) =>
      uri.queryParameters.containsKey('account_id') ||
      uri.queryParameters.containsKey('errorCode');

  /// Starts the connect flow (generates a key and redirects to the wallet).
  Future<void> connect() async {
    _set(busy: true, error: null);
    try {
      await _adapter().signIn(contractId: contractId, methodNames: methodNames);
      // On web the page navigates away here; the result arrives via [init].
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  Future<void> _handleCallback(Uri uri) async {
    _set(busy: true);
    try {
      final account = await _adapter().completeSignIn(uri);
      _account = account;
      _set(busy: false, error: account == null ? 'Sign-in cancelled' : null);
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  /// Disconnects and clears stored keys for the connected account.
  Future<void> disconnect() async {
    await _adapter().signOut();
    _account = null;
    notifyListeners();
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
