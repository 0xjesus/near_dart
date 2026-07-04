import 'dart:convert';

import 'package:near_dart/near_dart.dart';

/// Configuration for MyNearWallet adapter.
class MyNearWalletConfig {
  const MyNearWalletConfig({
    required this.contractId,
    required this.successUrl,
    required this.failureUrl,
    this.network = MyNearWalletNetwork.mainnet,
  });

  /// The contract to request access for.
  final AccountId contractId;

  /// URL to redirect to on success.
  final String successUrl;

  /// URL to redirect to on failure.
  final String failureUrl;

  /// Network to connect to.
  final MyNearWalletNetwork network;

  /// Gets the wallet base URL for this network.
  String get walletUrl {
    switch (network) {
      case MyNearWalletNetwork.mainnet:
        return 'https://app.mynearwallet.com';
      case MyNearWalletNetwork.testnet:
        return 'https://testnet.mynearwallet.com';
    }
  }
}

/// MyNearWallet network options.
enum MyNearWalletNetwork { mainnet, testnet }

/// Callback type for launching URLs.
///
/// Implement this to launch URLs in your platform (e.g., using url_launcher).
typedef UrlLauncher = Future<bool> Function(Uri uri);

/// MyNearWallet adapter using deep links/redirects.
///
/// This adapter works by redirecting the user to MyNearWallet for signing,
/// then back to your app with the result.
///
/// Example:
/// ```dart
/// final adapter = MyNearWalletAdapter(
///   config: MyNearWalletConfig(
///     contractId: AccountId('app.near'),
///     successUrl: 'myapp://wallet/callback/success',
///     failureUrl: 'myapp://wallet/callback/failure',
///   ),
///   launchUrl: (uri) async {
///     // Use url_launcher or your platform's URL launcher
///     return await launchUrl(uri);
///   },
/// );
///
/// // Sign in will redirect to MyNearWallet
/// await adapter.signIn(contractId: AccountId('app.near'));
///
/// // Handle the callback in your app to get the account info
/// adapter.handleCallback(callbackUri);
/// ```
///
/// For Flutter apps, you'll need to:
/// 1. Configure deep links in your app (iOS Info.plist, Android AndroidManifest.xml)
/// 2. Handle the callback URLs to extract account information
/// 3. Call handleCallback() when your app receives the deep link
class MyNearWalletAdapter implements WalletAdapter {
  MyNearWalletAdapter({
    required this.config,
    required this.launchUrl,
    KeyStore? keyStore,
  }) : keyStore = keyStore ?? InMemoryKeyStore();

  final MyNearWalletConfig config;
  final UrlLauncher launchUrl;

  /// Persists the function-call key generated during sign-in so it survives
  /// the redirect and can sign subsequent calls locally. Defaults to an
  /// in-memory store; provide a persistent one for the web redirect flow.
  final KeyStore keyStore;

  WalletAccount? _account;

  @override
  String get id => 'my-near-wallet';

  @override
  WalletType get type => WalletType.browser;

  @override
  String get name => 'MyNearWallet';

  @override
  String? get iconUrl => 'https://app.mynearwallet.com/favicon.ico';

  /// Builds the sign-in URL for MyNearWallet's `/login` endpoint.
  ///
  /// [publicKey] is the public half of a freshly generated ed25519 key
  /// pair; MyNearWallet adds it to the account as a **function-call access
  /// key** scoped to [contractId] and [methodNames] (empty = all methods).
  /// The dApp keeps the private half and signs subsequent calls locally —
  /// no further redirects. [methodNames] are appended as repeated query
  /// params, matching near-api-js `requestSignIn`.
  Uri buildSignInUrl({
    required AccountId contractId,
    required PublicKey publicKey,
    List<String> methodNames = const [],
  }) {
    return Uri.parse(config.walletUrl).replace(
      path: '/login',
      queryParameters: {
        'success_url': config.successUrl,
        'failure_url': config.failureUrl,
        'contract_id': contractId.value,
        'public_key': publicKey.value,
        if (methodNames.isNotEmpty) 'methodNames': methodNames,
      },
    );
  }

  @override
  Future<List<WalletAccount>> signIn({
    required AccountId contractId,
    List<String>? methodNames,
  }) async {
    // Generate the function-call key the wallet will provision, stash it as
    // the pending key (so it survives the redirect), and launch /login with
    // its real public key. The private half stays with us for local signing.
    final keyPair = await KeyPairEd25519.generate();
    await keyStore.setPendingKey(keyPair);

    final uri = buildSignInUrl(
      contractId: contractId,
      publicKey: keyPair.publicKey,
      methodNames: methodNames ?? const [],
    );
    await launchUrl(uri);

    // The wallet redirects back; the account is resolved in [completeSignIn].
    return [];
  }

  /// Completes sign-in from the wallet's callback [callbackUri].
  ///
  /// Parses `account_id`/`public_key`, promotes the pending key pair to a
  /// stored key for that account (so later calls can be signed locally),
  /// and returns the connected [WalletAccount] — or null if the callback
  /// was a failure or no sign-in was pending.
  ///
  /// Call this on app start (web: the initial URL) or when a deep link
  /// arrives (mobile).
  Future<WalletAccount?> completeSignIn(Uri callbackUri) async {
    final callback = MyNearWalletCallback.fromUri(callbackUri);
    if (!callback.isSuccess || callback.accountId == null) {
      await keyStore.clearPendingKey();
      return null;
    }

    final pending = await keyStore.getPendingKey();
    if (pending == null) return null;

    // The wallet returns the public key it provisioned; it must match the
    // pending key we generated, otherwise we'd hold an unusable secret.
    final returnedKey = callback.publicKey;
    if (returnedKey != null && returnedKey != pending.publicKey.value) {
      await keyStore.clearPendingKey();
      return null;
    }

    final accountId = AccountId(callback.accountId!);
    await keyStore.setKey(accountId, pending);
    await keyStore.clearPendingKey();

    final account = WalletAccount(
      accountId: accountId,
      publicKey: pending.publicKey,
    );
    _account = account;
    return account;
  }

  /// Parses a MyNearWallet callback URL without touching the key store.
  ///
  /// Prefer [completeSignIn] for the sign-in flow; this is for inspecting a
  /// raw callback (e.g. transaction-result callbacks).
  MyNearWalletCallback handleCallback(Uri callbackUri) =>
      MyNearWalletCallback.fromUri(callbackUri);

  @override
  Future<void> signOut() async {
    for (final accountId in await keyStore.accounts()) {
      await keyStore.removeKey(accountId);
    }
    await keyStore.clearPendingKey();
    _account = null;
  }

  @override
  Future<List<WalletAccount>> getAccounts() async {
    // The key store is the source of truth, so a connection survives an app
    // restart (the in-process [_account] is just a cache).
    final result = <WalletAccount>[];
    for (final accountId in await keyStore.accounts()) {
      final keyPair = await keyStore.getKey(accountId);
      if (keyPair != null) {
        result.add(
          WalletAccount(accountId: accountId, publicKey: keyPair.publicKey),
        );
      }
    }
    return result;
  }

  @override
  Future<bool> isSignedIn() async => (await keyStore.accounts()).isNotEmpty;

  /// Returns the locally-stored signing key for [accountId], if connected.
  ///
  /// Use it to sign function-call transactions locally (no redirect) with
  /// `signTransaction` / `Account`.
  Future<KeyPairEd25519?> keyFor(AccountId accountId) =>
      keyStore.getKey(accountId);

  /// Builds a transaction signing URL for MyNearWallet's `/sign` endpoint.
  ///
  /// `transactions` is a comma-separated list of base64-encoded
  /// Borsh-serialized [Transaction] objects (the same wire format
  /// near-api-js uses). Each transaction must carry [Transaction.publicKey],
  /// [Transaction.nonce] and [Transaction.blockHash]; otherwise
  /// `serializeTransaction` throws a [StateError].
  Uri buildTransactionUrl({
    required List<Transaction> transactions,
    String? callbackUrl,
  }) {
    final txParam = transactions
        .map((tx) => base64Encode(serializeTransaction(tx)))
        .join(',');

    return Uri.parse(config.walletUrl).replace(
      path: '/sign',
      queryParameters: {
        'transactions': txParam,
        'callbackUrl': callbackUrl ?? config.successUrl,
      },
    );
  }

  @override
  Future<TransactionResult> signAndSendTransaction({
    required Transaction transaction,
    String? callbackUrl,
  }) async {
    final uri = buildTransactionUrl(
      transactions: [transaction],
      callbackUrl: callbackUrl,
    );

    await launchUrl(uri);

    // Result will come from callback handling
    throw _PendingCallbackException(
      'Transaction result must be parsed from callback URL. '
      'Call handleTransactionCallback() when you receive the deep link.',
    );
  }

  @override
  Future<List<TransactionResult>> signAndSendTransactions({
    required List<Transaction> transactions,
    String? callbackUrl,
  }) async {
    final uri = buildTransactionUrl(
      transactions: transactions,
      callbackUrl: callbackUrl,
    );

    await launchUrl(uri);

    throw _PendingCallbackException(
      'Transaction results must be parsed from callback URL. '
      'Call handleTransactionCallback() when you receive the deep link.',
    );
  }

  /// Handles a transaction callback from MyNearWallet.
  List<TransactionResult> handleTransactionCallback(Uri callbackUri) {
    final callback = MyNearWalletCallback.fromUri(callbackUri);

    if (callback.isError) {
      return [
        TransactionResult(
          transactionHash: const CryptoHash(''),
          outcome: ExecutionOutcome(
            status: ExecutionStatus.failure(
              ExecutionError(
                errorType: callback.errorCode ?? 'Unknown',
                errorMessage: callback.errorMessage ?? 'Unknown error',
              ),
            ),
            gasBurnt: BigInt.zero,
          ),
        ),
      ];
    }

    // Parse transaction hashes from callback
    return (callback.transactionHashes ?? []).map((hash) {
      return TransactionResult(
        transactionHash: CryptoHash(hash),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.zero,
        ),
      );
    }).toList();
  }

  /// Builds a message signing URL.
  Uri buildSignMessageUrl(SignMessageParams params) {
    return Uri.parse(config.walletUrl).replace(
      path: '/sign-message',
      queryParameters: {
        'message': params.message,
        'recipient': params.recipient,
        'nonce': base64Encode(params.nonce),
        'callbackUrl': params.callbackUrl ?? config.successUrl,
        if (params.state != null) 'state': params.state,
      },
    );
  }

  @override
  Future<SignedMessage> signMessage(SignMessageParams params) async {
    final uri = buildSignMessageUrl(params);

    await launchUrl(uri);

    throw _PendingCallbackException(
      'Signed message must be parsed from callback URL. '
      'Call handleSignMessageCallback() when you receive the deep link.',
    );
  }

  /// Handles a sign message callback from MyNearWallet.
  ///
  /// The wallet returns `accountId`/`publicKey`/`signature` in the URL
  /// **hash fragment** (`callback#accountId=…`); older flows used query
  /// parameters. Both are accepted, with fragment values winning.
  SignedMessage handleSignMessageCallback(Uri callbackUri) {
    final params = {
      ...callbackUri.queryParameters,
      if (callbackUri.fragment.isNotEmpty)
        ...Uri.splitQueryString(callbackUri.fragment),
    };

    return SignedMessage(
      accountId: AccountId(
        params['accountId'] ?? _account?.accountId.value ?? '',
      ),
      publicKey: PublicKey(params['publicKey'] ?? 'ed25519:placeholder'),
      signature: params['signature'] ?? '',
      state: params['state'],
    );
  }

  @override
  Future<SignedMessage> verifyOwner({
    required String message,
    String? callbackUrl,
  }) async {
    final uri = Uri.parse(config.walletUrl).replace(
      path: '/verify-owner',
      queryParameters: {
        'message': message,
        'callbackUrl': callbackUrl ?? config.successUrl,
      },
    );

    await launchUrl(uri);

    throw _PendingCallbackException(
      'Verification result must be parsed from callback URL.',
    );
  }

  @override
  void dispose() {
    // Nothing to clean up
  }
}

/// Exception thrown when waiting for a callback from the wallet.
class _PendingCallbackException implements Exception {
  _PendingCallbackException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Parsed callback data from MyNearWallet.
class MyNearWalletCallback {
  const MyNearWalletCallback._({
    this.accountId,
    this.publicKey,
    this.allKeys,
    this.transactionHashes,
    this.errorCode,
    this.errorMessage,
  });

  /// Parses a callback URL from MyNearWallet.
  factory MyNearWalletCallback.fromUri(Uri uri) {
    final params = uri.queryParameters;

    return MyNearWalletCallback._(
      accountId: params['account_id'],
      publicKey: params['public_key'],
      allKeys: params['all_keys'],
      transactionHashes: params['transactionHashes']?.split(','),
      errorCode: params['errorCode'],
      errorMessage: params['errorMessage'],
    );
  }

  /// The connected account ID.
  final String? accountId;

  /// The public key added for the app.
  final String? publicKey;

  /// All public keys for the account.
  final String? allKeys;

  /// Transaction hashes for signed transactions.
  final List<String>? transactionHashes;

  /// Error code if the operation failed.
  final String? errorCode;

  /// Error message if the operation failed.
  final String? errorMessage;

  /// Whether this callback indicates success.
  bool get isSuccess => errorCode == null && errorMessage == null;

  /// Whether this callback indicates an error.
  bool get isError => errorCode != null || errorMessage != null;
}
