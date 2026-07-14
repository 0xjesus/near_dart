import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:near_dart/near_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'secure_key_store.dart';
import 'shared_prefs_key_store.dart';
import 'wallet_security.dart';
import 'wallet_option.dart';

/// Creates a MyNearWallet adapter with the controller's logger.
typedef MyNearWalletAdapterBuilder =
    MyNearWalletAdapter Function(NearLogger? logger);

/// Creates an Intear adapter with the controller's logger.
typedef IntearWalletAdapterBuilder =
    IntearWalletAdapter Function(NearLogger? logger);

/// Creates a HOT adapter with the controller's logger.
typedef HotWalletAdapterBuilder = HotWalletAdapter Function(NearLogger? logger);

/// Supplies the initial wallet callback and subsequent deep links.
///
/// Applications normally use the controller's AppLinks-backed default. A
/// custom source can provide both parts of the callback lifecycle as one
/// valid dependency, including in deterministic tests.
abstract interface class NearWalletLinkSource {
  /// Returns the link that launched the application, if any.
  Future<Uri?> getInitialLink();

  /// Emits links received while the application is running.
  Stream<Uri> get uriLinkStream;
}

class _AppLinksWalletLinkSource implements NearWalletLinkSource {
  _AppLinksWalletLinkSource() : _appLinks = AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}

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
    this.securityPolicy = const NearWalletSecurityPolicy(),
    NearWalletSecurity? security,
    this.logger,
    @visibleForTesting MyNearWalletAdapterBuilder? myNearWalletAdapterBuilder,
    @visibleForTesting IntearWalletAdapterBuilder? intearWalletAdapterBuilder,
    @visibleForTesting HotWalletAdapterBuilder? hotWalletAdapterBuilder,
    @visibleForTesting NearWalletLinkSource? linkSource,
  }) : keyStore =
           keyStore ?? (kIsWeb ? SharedPrefsKeyStore() : SecureKeyStore()),
       client =
           client ??
           (network == MyNearWalletNetwork.mainnet
               ? NearRpcClient.mainnet(logger: logger)
               : NearRpcClient.testnet(logger: logger)),
       _myNearWalletAdapterBuilder = myNearWalletAdapterBuilder,
       _intearWalletAdapterBuilder = intearWalletAdapterBuilder,
       _hotWalletAdapterBuilder = hotWalletAdapterBuilder,
       _linkSource = linkSource {
    this.security = security ?? NearWalletSecurity(this.client);
  }

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
  ///
  /// Defaults to [SecureKeyStore] (Keystore/Keychain/DPAPI/libsecret) on
  /// mobile and desktop, and [SharedPrefsKeyStore] on web, where no OS
  /// secret storage exists.
  final KeyStore keyStore;

  /// RPC client used for local signing after connect.
  final NearRpcClient client;

  /// Opt-in on-chain verification and confirmation behavior.
  final NearWalletSecurityPolicy securityPolicy;

  /// Service used to perform on-chain wallet checks.
  late final NearWalletSecurity security;

  /// Receives safe structured diagnostics from wallet and RPC operations.
  final NearLogger? logger;

  final MyNearWalletAdapterBuilder? _myNearWalletAdapterBuilder;
  final IntearWalletAdapterBuilder? _intearWalletAdapterBuilder;
  final HotWalletAdapterBuilder? _hotWalletAdapterBuilder;
  final NearWalletLinkSource? _linkSource;
  MyNearWalletAdapter? _myNearWalletAdapter;

  static const _optionPrefsKey = 'near_wallet_connect_option';
  static const _accountPrefsKey = 'near_wallet_connect_account';
  static const _networkPrefsKey = 'near_wallet_connect_network';
  static const _hotAccountPrefsKey = 'near_wallet_connect_hot_account';
  static const _hotPublicKeyPrefsKey = 'near_wallet_connect_hot_public_key';

  WalletAccount? _account;
  NearWalletOption? _walletOption;
  bool _busy = false;
  NearSdkException? _lastException;
  StreamSubscription<Uri>? _linkSub;
  bool _disposed = false;
  int _myNearWalletFlowGeneration = 0;
  final Set<Completer<void>> _activeMyNearWalletCallbacks = {};

  /// The connected account, or null.
  WalletAccount? get account => _account;

  /// Which wallet the connected account came from, or null.
  NearWalletOption? get walletOption => _walletOption;

  /// Whether a wallet is connected.
  bool get isConnected => _account != null;

  /// Whether a connect/callback operation is in flight.
  bool get busy => _busy;

  /// The last error message, if any.
  String? get error => _lastException?.message;

  /// The last normalized SDK error, if any.
  NearSdkException? get lastException => _lastException;

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
    final existing = _myNearWalletAdapter;
    if (existing != null) return existing;
    final builder = _myNearWalletAdapterBuilder;
    if (builder != null) {
      return _myNearWalletAdapter = builder(logger);
    }
    final base = kIsWeb
        ? Uri.base.replace(query: '').removeFragment().toString()
        : '$callbackScheme://callback';
    return _myNearWalletAdapter = MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: contractId,
        successUrl: kIsWeb ? base : '$base/success',
        failureUrl: kIsWeb ? base : '$base/failure',
        network: network,
      ),
      keyStore: keyStore,
      launchUrl: _launch,
      logger: logger,
    );
  }

  IntearWalletAdapter _intearAdapter() {
    final builder = _intearWalletAdapterBuilder;
    if (builder != null) return builder(logger);
    return IntearWalletAdapter(
      config: IntearWalletConfig(
        networkId: _networkId,
        origin: appOrigin ?? '$callbackScheme://app',
        contractId: contractId,
        methodNames: methodNames.isEmpty ? null : methodNames,
      ),
      keyStore: keyStore,
      launchUrl: _launch,
      logger: logger,
    );
  }

  HotWalletAdapter _hotAdapter() {
    final builder = _hotWalletAdapterBuilder;
    if (builder != null) return builder(logger);
    return HotWalletAdapter(
      config: HotWalletConfig(origin: appOrigin ?? '$callbackScheme://app'),
      launchUrl: _launch,
      logger: logger,
    );
  }

  // ── lifecycle ────────────────────────────────────────────────────────────

  /// Restores any existing session and processes a pending sign-in callback.
  ///
  /// Call once at startup. On web it reads `Uri.base`; on mobile it consumes
  /// the initial deep link and listens for subsequent ones.
  Future<void> init() async {
    if (_disposed) return;
    // near_wallet_connect < 0.3.0 kept keys in plain shared preferences;
    // move any existing session into secure storage once.
    final ks = keyStore;
    if (ks is SecureKeyStore) await ks.migrateFrom(SharedPrefsKeyStore());

    await _restore();
    if (kIsWeb) {
      if (_looksLikeCallback(Uri.base)) await _handleCallback(Uri.base);
      return;
    }
    final linkSource = _linkSource ?? _AppLinksWalletLinkSource();
    final initial = await linkSource.getInitialLink();
    if (initial != null && _looksLikeCallback(initial)) {
      await _handleCallback(initial);
    }
    if (_disposed) return;
    _listenForLinks(linkSource.uriLinkStream);
  }

  void _listenForLinks(Stream<Uri> links) {
    if (_disposed) return;
    _linkSub = links.listen((uri) {
      if (_looksLikeCallback(uri)) _handleCallback(uri);
    });
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _account = null;
    _walletOption = null;

    final optionName = prefs.getString(_optionPrefsKey);
    var accountId = prefs.getString(_accountPrefsKey);
    var networkId = prefs.getString(_networkPrefsKey);
    if (optionName == null) {
      if (accountId != null ||
          networkId != null ||
          prefs.getString(_hotAccountPrefsKey) != null ||
          prefs.getString(_hotPublicKeyPrefsKey) != null) {
        await _clearPersistedSession();
      }
      return;
    }

    final restoredOption = NearWalletOption.values.asNameMap()[optionName];
    if (restoredOption == null) {
      await _clearPersistedSession();
      return;
    }

    if (accountId == null && networkId == null) {
      if (!await _migrateLegacySession(prefs, restoredOption)) return;
      accountId = prefs.getString(_accountPrefsKey);
      networkId = prefs.getString(_networkPrefsKey);
    }
    if (accountId == null || networkId == null) {
      await _clearPersistedSession();
      return;
    }
    if (networkId != _networkId) return;
    if (!availableWallets.contains(restoredOption)) {
      await _clearPersistedSession();
      return;
    }

    if (restoredOption == NearWalletOption.hot) {
      await _restoreHot(prefs, accountId);
      return;
    }

    final AccountId parsedAccountId;
    final KeyPairEd25519? key;
    try {
      parsedAccountId = AccountId(accountId);
      key = await keyStore.getKey(parsedAccountId);
    } catch (_) {
      await _clearPersistedSession();
      return;
    }
    if (key == null) {
      await _clearPersistedSession();
      return;
    }

    final account = WalletAccount(
      accountId: parsedAccountId,
      publicKey: key.publicKey,
    );
    if (!await _verifyRestoredAccount(
      account,
      requireFunctionCallScope: true,
      removeStoredKeyOnDefiniteFailure: true,
    )) {
      return;
    }
    _publishRestoredAccount(account, restoredOption);
  }

  Future<bool> _migrateLegacySession(
    SharedPreferences prefs,
    NearWalletOption option,
  ) async {
    if (option == NearWalletOption.hot) {
      final accountId = prefs.getString(_hotAccountPrefsKey);
      final publicKey = prefs.getString(_hotPublicKeyPrefsKey);
      if (accountId == null || publicKey == null) {
        await _clearPersistedSession();
        return false;
      }
      await _saveSession(option, accountId: accountId, hotPublicKey: publicKey);
      return true;
    }

    final accounts = await keyStore.accounts();
    if (accounts.length != 1 ||
        await keyStore.getKey(accounts.single) == null) {
      await _clearPersistedSession();
      return false;
    }
    await _saveSession(option, accountId: accounts.single.value);
    return true;
  }

  Future<void> _restoreHot(SharedPreferences prefs, String accountId) async {
    final publicKey = prefs.getString(_hotPublicKeyPrefsKey);
    final legacyAccountId = prefs.getString(_hotAccountPrefsKey);
    if (publicKey == null ||
        (legacyAccountId != null && legacyAccountId != accountId)) {
      await _clearPersistedSession();
      return;
    }

    final WalletAccount account;
    try {
      account = WalletAccount(
        accountId: AccountId(accountId),
        publicKey: PublicKey(publicKey),
      );
    } catch (_) {
      await _clearPersistedSession();
      return;
    }

    if (!await _verifyRestoredAccount(
      account,
      requireFunctionCallScope: false,
      removeStoredKeyOnDefiniteFailure: false,
    )) {
      return;
    }
    _publishRestoredAccount(account, NearWalletOption.hot);
  }

  Future<bool> _verifyRestoredAccount(
    WalletAccount account, {
    required bool requireFunctionCallScope,
    required bool removeStoredKeyOnDefiniteFailure,
  }) async {
    if (!securityPolicy.verifyAccessKeyOnConnect) return true;
    try {
      await security.verifyAccessKey(
        account: account,
        contractId: contractId,
        methodNames: methodNames,
        requireFunctionCallScope: requireFunctionCallScope,
      );
      return true;
    } catch (error) {
      final exception = _normalizeControllerError(error);
      final definiteFailure =
          exception.code == NearErrorCode.accessKeyNotFound ||
          exception.code == NearErrorCode.accessKeyMismatch;
      if (definiteFailure) {
        if (removeStoredKeyOnDefiniteFailure) {
          await keyStore.removeKey(account.accountId);
        }
        await _clearPersistedSession();
      }
      _account = null;
      _walletOption = null;
      _setException(exception, busy: false);
      return false;
    }
  }

  void _publishRestoredAccount(WalletAccount account, NearWalletOption option) {
    _account = account;
    _walletOption = option;
    _set(clearException: true);
  }

  static bool _looksLikeCallback(Uri uri) =>
      uri.queryParameters.containsKey('account_id') ||
      uri.queryParameters.containsKey('errorCode');

  // ── connect / disconnect ─────────────────────────────────────────────────

  /// Starts the connect flow with the chosen [wallet].
  ///
  /// MyNearWallet redirects to the browser (the result arrives via [init]);
  /// Intear and HOT open their native apps and resolve in place.
  /// Selecting Intear or HOT invalidates any pending MyNearWallet sign-in
  /// before opening the new wallet. A failed selection preserves the active
  /// account session, but the cancelled browser flow must be restarted.
  Future<void> connect({
    NearWalletOption wallet = NearWalletOption.myNearWallet,
  }) async {
    if (!availableWallets.contains(wallet)) {
      _setException(
        NearSdkException(
          code: NearErrorCode.wrongNetwork,
          message: '${wallet.label} is not available on $_networkId',
        ),
        busy: false,
      );
      return;
    }
    _set(busy: true, clearException: true);
    try {
      if (wallet != NearWalletOption.myNearWallet) {
        await _cancelPendingMyNearWalletSignIn();
      }
      switch (wallet) {
        case NearWalletOption.myNearWallet:
          await _mnwAdapter().signIn(
            contractId: contractId,
            methodNames: methodNames,
          );
        // On web the page navigates away here; the result arrives in init().
        case NearWalletOption.intear:
          final result = await _intearAdapter().signIn();
          await _verifyNewAccount(
            result.account,
            requireFunctionCallScope: true,
            removeStoredKeyOnFailure: true,
            clearPersistedSessionOnFailure: false,
          );
          await _saveSession(wallet, accountId: result.account.accountId.value);
          _account = result.account;
          _walletOption = wallet;
          _set(busy: false);
          _logConnected(wallet);
        case NearWalletOption.hot:
          final account = await _hotAdapter().signIn();
          await _verifyNewAccount(
            account,
            requireFunctionCallScope: false,
            removeStoredKeyOnFailure: false,
            clearPersistedSessionOnFailure: false,
          );
          await _saveSession(
            wallet,
            accountId: account.accountId.value,
            hotPublicKey: account.publicKey.value,
          );
          _account = account;
          _walletOption = wallet;
          _set(busy: false);
          _logConnected(wallet);
      }
    } catch (error) {
      _setException(_normalizeControllerError(error), busy: false);
    }
  }

  Future<void> _saveSession(
    NearWalletOption option, {
    required String accountId,
    String? hotPublicKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_optionPrefsKey);
    await prefs.setString(_accountPrefsKey, accountId);
    await prefs.setString(_networkPrefsKey, _networkId);
    if (option == NearWalletOption.hot && hotPublicKey != null) {
      await prefs.setString(_hotAccountPrefsKey, accountId);
      await prefs.setString(_hotPublicKeyPrefsKey, hotPublicKey);
    } else {
      await prefs.remove(_hotAccountPrefsKey);
      await prefs.remove(_hotPublicKeyPrefsKey);
    }
    await prefs.setString(_optionPrefsKey, option.name);
  }

  Future<void> _verifyNewAccount(
    WalletAccount account, {
    required bool requireFunctionCallScope,
    required bool removeStoredKeyOnFailure,
    required bool clearPersistedSessionOnFailure,
  }) async {
    if (!securityPolicy.verifyAccessKeyOnConnect) return;
    try {
      await security.verifyAccessKey(
        account: account,
        contractId: contractId,
        methodNames: methodNames,
        requireFunctionCallScope: requireFunctionCallScope,
      );
    } catch (_) {
      if (removeStoredKeyOnFailure) {
        await keyStore.removeKey(account.accountId);
      }
      if (clearPersistedSessionOnFailure) {
        if (_account == null) await _clearPersistedSession();
      }
      rethrow;
    }
  }

  Future<void> _handleCallback(Uri uri) async {
    if (_disposed) return;
    final operation = Completer<void>();
    _activeMyNearWalletCallbacks.add(operation);
    final generation = _myNearWalletFlowGeneration;
    final previousAccount = _account;
    final previousOption = _walletOption;
    final adapter = _mnwAdapter();
    var sessionWriteStarted = false;
    try {
      await _handleCallbackForGeneration(
        uri,
        adapter: adapter,
        generation: generation,
        previousAccount: previousAccount,
        previousOption: previousOption,
        onSessionWrite: () => sessionWriteStarted = true,
      );
    } catch (error) {
      await adapter.cancelPendingSignIn();
      if (sessionWriteStarted) {
        await _restorePersistedSession(previousAccount, previousOption);
      }
      if (generation != _myNearWalletFlowGeneration) return;
      _setException(_normalizeControllerError(error), busy: false);
    } finally {
      _activeMyNearWalletCallbacks.remove(operation);
      operation.complete();
    }
  }

  Future<void> _handleCallbackForGeneration(
    Uri uri, {
    required MyNearWalletAdapter adapter,
    required int generation,
    required WalletAccount? previousAccount,
    required NearWalletOption? previousOption,
    required VoidCallback onSessionWrite,
  }) async {
    // Only a pending sign-in makes this callback ours. Other wallet
    // callbacks can carry the same parameters (e.g. MyNearWallet's /sign
    // appends account_id next to transactionHashes) and must not clobber
    // an existing session.
    final signInPending = await keyStore.getPendingKey() != null;
    if (generation != _myNearWalletFlowGeneration || !signInPending) return;

    _set(busy: true, clearException: true);
    final account = await adapter.completeSignIn(uri);
    if (generation != _myNearWalletFlowGeneration) {
      await adapter.cancelPendingSignIn();
      return;
    }
    if (account != null) {
      try {
        await _verifyNewAccount(
          account,
          requireFunctionCallScope: true,
          removeStoredKeyOnFailure: false,
          clearPersistedSessionOnFailure: true,
        );
      } catch (_) {
        final rolledBack = await adapter.cancelPendingSignIn();
        if (!rolledBack) {
          final storedKey = await keyStore.getKey(account.accountId);
          if (storedKey?.publicKey == account.publicKey) {
            await keyStore.removeKey(account.accountId);
          }
        }
        rethrow;
      }
      if (generation != _myNearWalletFlowGeneration) {
        await adapter.cancelPendingSignIn();
        return;
      }
      onSessionWrite();
      await _saveSession(
        NearWalletOption.myNearWallet,
        accountId: account.accountId.value,
      );
      if (generation != _myNearWalletFlowGeneration) {
        await adapter.cancelPendingSignIn();
        await _restorePersistedSession(previousAccount, previousOption);
        return;
      }
      adapter.acceptCompletedSignIn(account);
      _account = account;
      _walletOption = NearWalletOption.myNearWallet;
      _set(busy: false);
      _logConnected(NearWalletOption.myNearWallet);
      return;
    }

    final stillPending = await keyStore.getPendingKey() != null;
    if (generation != _myNearWalletFlowGeneration || stillPending) return;
    if (_account == null) await _clearPersistedSession();
    _setException(
      const NearSdkException(
        code: NearErrorCode.cancelled,
        message: 'Sign-in cancelled',
      ),
      busy: false,
    );
  }

  Future<void> _cancelPendingMyNearWalletSignIn() async {
    _myNearWalletFlowGeneration++;
    await _mnwAdapter().cancelPendingSignIn();
    while (_activeMyNearWalletCallbacks.isNotEmpty) {
      await Future.wait(
        _activeMyNearWalletCallbacks.map((operation) => operation.future),
      );
    }
  }

  Future<void> _restorePersistedSession(
    WalletAccount? account,
    NearWalletOption? option,
  ) async {
    if (account == null || option == null) {
      await _clearPersistedSession();
      return;
    }
    await _saveSession(
      option,
      accountId: account.accountId.value,
      hotPublicKey: option == NearWalletOption.hot
          ? account.publicKey.value
          : null,
    );
  }

  /// Disconnects and clears the stored session.
  Future<void> disconnect() async {
    await _cancelPendingMyNearWalletSignIn();
    final account = _account;
    if (account != null && _walletOption != NearWalletOption.hot) {
      await keyStore.removeKey(account.accountId);
    }
    await _clearPersistedSession();
    _account = null;
    _walletOption = null;
    _busy = false;
    _lastException = null;
    if (!_disposed) notifyListeners();
    emitNearLog(
      logger,
      NearLogEvent(
        level: NearLogLevel.info,
        type: NearLogEventType.walletDisconnected,
        operation: 'disconnect',
        metadata: {'networkId': _networkId},
      ),
    );
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_optionPrefsKey);
    await prefs.remove(_accountPrefsKey);
    await prefs.remove(_networkPrefsKey);
    await prefs.remove(_hotAccountPrefsKey);
    await prefs.remove(_hotPublicKeyPrefsKey);
  }

  // ── the unified API ──────────────────────────────────────────────────────

  /// A ready-to-use [Account] signing locally with the stored function-call
  /// key, or null if not connected / the wallet stored no key.
  ///
  /// Available after a MyNearWallet or Intear connect. Function-call keys
  /// cannot attach deposits — use [sendTransactions] for payments.
  Future<Account?> signer() async {
    final a = _account;
    if (a == null) {
      _setException(_notConnectedException);
      return null;
    }
    final kp = await keyStore.getKey(a.accountId);
    if (kp == null) return null;
    _set(clearException: true);
    return Account(accountId: a.accountId, keyPair: kp, client: client);
  }

  /// Signs a NEP-413 message with the user's wallet key (Intear, HOT).
  Future<Nep413SignedMessage> signMessage(Nep413Payload payload) async {
    final a = _account;
    if (a == null) return _throwControllerError(_notConnectedException);
    _set(clearException: true);
    try {
      switch (_walletOption) {
        case NearWalletOption.intear:
          return await _intearAdapter().signMessage(
            accountId: a.accountId,
            payload: payload,
          );
        case NearWalletOption.hot:
          return await _hotAdapter().signMessage(payload: payload);
        default:
          throw const NearSdkException(
            code: NearErrorCode.unsupportedOperation,
            message:
                'MyNearWallet signs messages via browser redirect; use '
                'MyNearWalletAdapter.buildSignMessageUrl for that flow.',
          );
      }
    } catch (error, stackTrace) {
      final exception = _normalizeControllerError(error);
      _setException(exception);
      Error.throwWithStackTrace(exception, stackTrace);
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
    if (a == null) return _throwControllerError(_notConnectedException);
    _set(clearException: true);
    try {
      final List<dynamic> outcomes;
      switch (_walletOption) {
        case NearWalletOption.intear:
          outcomes = await _intearAdapter().signAndSendTransactions(
            accountId: a.accountId,
            transactions: transactions,
          );
        case NearWalletOption.hot:
          outcomes = await _hotAdapter().signAndSendTransactions(
            transactions: transactions,
          );
        default:
          throw const NearSdkException(
            code: NearErrorCode.unsupportedOperation,
            message:
                'MyNearWallet signs transactions via browser redirect; use '
                'MyNearWalletAdapter.buildTransactionUrl for that flow, or '
                'signer() for gas-only calls with the function-call key.',
          );
      }

      emitNearLog(
        logger,
        NearLogEvent(
          level: NearLogLevel.info,
          type: NearLogEventType.transactionSubmitted,
          operation: 'sendTransactions',
          metadata: {
            'networkId': _networkId,
            'transactionCount': outcomes.length,
          },
        ),
      );

      final finality = securityPolicy.transactionFinality;
      if (finality != null) {
        await security.confirmTransactions(
          senderAccountId: a.accountId,
          outcomes: outcomes,
          waitUntil: finality,
        );
        emitNearLog(
          logger,
          NearLogEvent(
            level: NearLogLevel.info,
            type: NearLogEventType.transactionFinalized,
            operation: 'sendTransactions',
            metadata: {
              'networkId': _networkId,
              'transactionCount': outcomes.length,
              'waitUntil': finality.rpcValue,
            },
          ),
        );
      }
      return outcomes;
    } catch (error, stackTrace) {
      final exception = _normalizeControllerError(error);
      _setException(exception);
      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  static const _notConnectedException = NearSdkException(
    code: NearErrorCode.notConnected,
    message: 'Connect a wallet first',
  );

  Never _throwControllerError(NearSdkException exception) {
    _setException(exception);
    throw exception;
  }

  NearSdkException _normalizeControllerError(Object error) {
    if (error is NearSdkException) return error;
    final normalized = nearErrorFrom(error);
    final message = switch (normalized.code) {
      NearErrorCode.deepLinkUnavailable =>
        'The wallet app could not be opened.',
      NearErrorCode.userRejected => 'The wallet request was rejected.',
      NearErrorCode.walletResponseInvalid || NearErrorCode.invalidResponse =>
        'The wallet returned an invalid response.',
      NearErrorCode.accountMismatch =>
        'The wallet returned an unexpected account.',
      NearErrorCode.signatureVerificationFailed =>
        'The wallet signature could not be verified.',
      NearErrorCode.missingCallback => 'The wallet callback was missing.',
      NearErrorCode.cancelled => 'The wallet operation was cancelled.',
      NearErrorCode.rpcTimeout => 'The wallet RPC request timed out.',
      NearErrorCode.rpcUnavailable => 'The wallet RPC endpoint is unavailable.',
      NearErrorCode.rateLimited => 'The wallet RPC request was rate-limited.',
      NearErrorCode.accessKeyNotFound =>
        'The wallet access key was not found on chain.',
      NearErrorCode.accessKeyMismatch =>
        'The wallet access key does not match the required scope.',
      NearErrorCode.transactionFailed => 'The wallet transaction failed.',
      NearErrorCode.insufficientBalance =>
        'The wallet has insufficient balance for this operation.',
      NearErrorCode.unsupportedOperation =>
        'This wallet does not support the requested operation.',
      NearErrorCode.notConnected => 'Connect a wallet first',
      NearErrorCode.wrongNetwork =>
        'The selected wallet is not available on this network.',
      NearErrorCode.invalidInput => 'The wallet request was invalid.',
      NearErrorCode.unknown => 'The wallet operation failed.',
    };
    return NearSdkException(
      code: normalized.code,
      message: message,
      retryable: normalized.retryable,
    );
  }

  void _logConnected(NearWalletOption wallet) {
    if (_disposed) return;
    emitNearLog(
      logger,
      NearLogEvent(
        level: NearLogLevel.info,
        type: NearLogEventType.walletConnected,
        operation: 'connect',
        metadata: {'wallet': wallet.name, 'networkId': _networkId},
      ),
    );
  }

  void _setException(NearSdkException exception, {bool? busy}) {
    if (_disposed) return;
    _lastException = exception;
    _set(busy: busy);
  }

  void _set({bool? busy, bool clearException = false}) {
    if (_disposed) return;
    if (busy != null) _busy = busy;
    if (clearException) _lastException = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _myNearWalletFlowGeneration++;
    _linkSub?.cancel();
    _linkSub = null;
    _myNearWalletAdapter?.dispose();
    super.dispose();
  }
}
