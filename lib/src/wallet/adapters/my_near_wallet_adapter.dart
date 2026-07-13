import 'dart:convert';

import 'package:near_dart/near_dart.dart';

/// Configuration for MyNearWallet adapter.
class MyNearWalletConfig {
  const MyNearWalletConfig({
    required this.contractId,
    required this.successUrl,
    required this.failureUrl,
    this.network = MyNearWalletNetwork.mainnet,
    NearNetwork? networkConfig,
  }) : networkConfig =
           networkConfig ??
           (network == MyNearWalletNetwork.mainnet
               ? NearNetwork.mainnet
               : NearNetwork.testnet);

  /// The contract to request access for.
  final AccountId contractId;

  /// URL to redirect to on success.
  final String successUrl;

  /// URL to redirect to on failure.
  final String failureUrl;

  /// Network to connect to.
  final MyNearWalletNetwork network;

  /// Complete network metadata used for wallet URLs and explorer links.
  final NearNetwork networkConfig;

  /// Gets the wallet base URL for this network.
  String get walletUrl {
    final walletUrl = networkConfig.myNearWalletUrl;
    if (walletUrl != null) return walletUrl;
    switch (network) {
      case MyNearWalletNetwork.mainnet:
        return NearNetwork.mainnet.myNearWalletUrl!;
      case MyNearWalletNetwork.testnet:
        return NearNetwork.testnet.myNearWalletUrl!;
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
    this.logger,
  }) : keyStore = keyStore ?? InMemoryKeyStore();

  final MyNearWalletConfig config;
  final UrlLauncher launchUrl;

  /// Receives safe operational diagnostics for wallet flows.
  final NearLogger? logger;

  /// Persists the function-call key generated during sign-in so it survives
  /// the redirect and can sign subsequent calls locally. Defaults to an
  /// in-memory store; provide a persistent one for the web redirect flow.
  final KeyStore keyStore;

  _PendingMyNearWalletFlow? _pendingFlow;

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
    if (_pendingFlow != null || await keyStore.getPendingKey() != null) {
      throw const MyNearWalletException.flowInProgress();
    }
    _openWalletFlow(
      'signIn',
      successUrl: config.successUrl,
      failureUrl: config.failureUrl,
    );
    final flow = _pendingFlow!;
    try {
      // The pending key survives the redirect; only its public half is sent.
      final keyPair = await KeyPairEd25519.generate();
      await keyStore.setPendingKey(keyPair);
      final uri = buildSignInUrl(
        contractId: contractId,
        publicKey: keyPair.publicKey,
        methodNames: methodNames ?? const [],
      );
      if (!await launchUrl(uri)) {
        throw const MyNearWalletException.deepLink();
      }
      // The wallet redirects back; [completeSignIn] resolves the account.
      return <WalletAccount>[];
    } catch (error, stackTrace) {
      try {
        await keyStore.clearPendingKey();
      } catch (_) {
        // Preserve the original wallet-flow failure.
      }
      final normalized = _normalizeMyNearError(error);
      _finishWalletFlow(flow, failureCode: normalized.code);
      Error.throwWithStackTrace(normalized, stackTrace);
    }
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
    final pendingKey = await keyStore.getPendingKey();
    if (_pendingFlow == null && pendingKey != null) {
      _openWalletFlow(
        'signIn',
        successUrl: config.successUrl,
        failureUrl: config.failureUrl,
      );
    }
    final flow = _pendingFlow;
    if (flow == null || flow.operation != 'signIn') return null;

    final isSuccessRoute = _matchesCallbackRoute(callbackUri, flow.successUrl);
    final isFailureRoute =
        flow.failureUrl != null &&
        _matchesCallbackRoute(callbackUri, flow.failureUrl!);
    if (!isSuccessRoute && !isFailureRoute) return null;

    _callbackReceived(flow);
    NearErrorCode? failureCode;
    try {
      final callback = MyNearWalletCallback.fromUri(callbackUri);
      if (isFailureRoute) {
        failureCode = NearErrorCode.userRejected;
        await keyStore.clearPendingKey();
        return null;
      }
      if (!callback.isSuccess || callback.accountId == null) {
        failureCode = callback.isError
            ? NearErrorCode.userRejected
            : NearErrorCode.walletResponseInvalid;
        await keyStore.clearPendingKey();
        return null;
      }

      final pending = pendingKey ?? await keyStore.getPendingKey();
      if (pending == null) {
        failureCode = NearErrorCode.missingCallback;
        return null;
      }

      final returnedKey = callback.publicKey;
      if (returnedKey == null || returnedKey != pending.publicKey.value) {
        failureCode = NearErrorCode.walletResponseInvalid;
        await keyStore.clearPendingKey();
        return null;
      }

      late final AccountId accountId;
      try {
        accountId = AccountId(callback.accountId!);
      } catch (_) {
        failureCode = NearErrorCode.walletResponseInvalid;
        await keyStore.clearPendingKey();
        return null;
      }
      await keyStore.setKey(accountId, pending);
      await keyStore.clearPendingKey();

      final account = WalletAccount(
        accountId: accountId,
        publicKey: pending.publicKey,
      );
      return account;
    } catch (error, stackTrace) {
      final normalized = _normalizeMyNearError(error);
      failureCode = normalized.code;
      Error.throwWithStackTrace(normalized, stackTrace);
    } finally {
      _finishWalletFlow(flow, failureCode: failureCode);
    }
  }

  /// Parses a MyNearWallet callback URL without touching the key store.
  ///
  /// Prefer [completeSignIn] for the sign-in flow; this is for inspecting a
  /// raw callback (e.g. transaction-result callbacks).
  MyNearWalletCallback handleCallback(Uri callbackUri) {
    final flow = _pendingFlow;
    if (flow == null || flow.operation != 'verifyOwner') {
      try {
        return MyNearWalletCallback.fromUri(callbackUri);
      } catch (error, stackTrace) {
        final normalized = _normalizeMyNearError(error);
        Error.throwWithStackTrace(normalized, stackTrace);
      }
    }
    if (!_matchesCallbackRoute(callbackUri, flow.successUrl)) {
      throw const MyNearWalletCallbackException();
    }

    _callbackReceived(flow);
    NearErrorCode? failureCode;
    try {
      final callback = MyNearWalletCallback.fromUri(callbackUri);
      if (callback.isError) failureCode = NearErrorCode.userRejected;
      return callback;
    } catch (error, stackTrace) {
      final normalized = _normalizeMyNearError(error);
      failureCode = normalized.code;
      Error.throwWithStackTrace(normalized, stackTrace);
    } finally {
      _finishWalletFlow(flow, failureCode: failureCode);
    }
  }

  bool _matchesCallbackRoute(Uri uri, String configured) {
    final expected = Uri.parse(configured);
    String normalizedPath(String path) => path.isEmpty ? '/' : path;
    return uri.scheme == expected.scheme &&
        uri.host == expected.host &&
        uri.port == expected.port &&
        normalizedPath(uri.path) == normalizedPath(expected.path);
  }

  @override
  Future<void> signOut() async {
    for (final accountId in await keyStore.accounts()) {
      await keyStore.removeKey(accountId);
    }
    await keyStore.clearPendingKey();
    _pendingFlow = null;
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

    await _launchWalletFlow(
      'signAndSendTransaction',
      uri,
      successUrl: callbackUrl ?? config.successUrl,
    );

    // Result will come from callback handling
    throw const _PendingCallbackException(
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

    await _launchWalletFlow(
      'signAndSendTransactions',
      uri,
      successUrl: callbackUrl ?? config.successUrl,
    );

    throw const _PendingCallbackException(
      'Transaction results must be parsed from callback URL. '
      'Call handleTransactionCallback() when you receive the deep link.',
    );
  }

  /// Handles a transaction callback from MyNearWallet.
  List<TransactionResult> handleTransactionCallback(Uri callbackUri) {
    final flow = _pendingFlow;
    if (flow == null ||
        (flow.operation != 'signAndSendTransaction' &&
            flow.operation != 'signAndSendTransactions')) {
      throw const MyNearWalletException.missingCallback();
    }
    if (!_matchesCallbackRoute(callbackUri, flow.successUrl)) {
      throw const MyNearWalletCallbackException();
    }

    _callbackReceived(flow);
    NearErrorCode? failureCode;
    try {
      final callback = MyNearWalletCallback.fromUri(callbackUri);
      if (callback.isError) {
        failureCode = NearErrorCode.userRejected;
        return [
          TransactionResult(
            transactionHash: const CryptoHash(''),
            outcome: ExecutionOutcome(
              status: ExecutionStatus.failure(
                const ExecutionError(
                  errorType: 'WalletRejected',
                  errorMessage: 'MyNearWallet rejected the transaction.',
                ),
              ),
              gasBurnt: BigInt.zero,
            ),
          ),
        ];
      }

      final hashes = callback.transactionHashes;
      if (hashes == null ||
          hashes.isEmpty ||
          hashes.any((hash) => !_isCanonicalTransactionHash(hash))) {
        failureCode = NearErrorCode.walletResponseInvalid;
        throw const MyNearWalletCallbackException();
      }
      return hashes.map((hash) {
        return TransactionResult(
          transactionHash: CryptoHash(hash),
          outcome: ExecutionOutcome(
            status: ExecutionStatus.successValue(''),
            gasBurnt: BigInt.zero,
          ),
        );
      }).toList();
    } catch (error, stackTrace) {
      final normalized = _normalizeMyNearError(error);
      failureCode ??= normalized.code;
      Error.throwWithStackTrace(normalized, stackTrace);
    } finally {
      _finishWalletFlow(flow, failureCode: failureCode);
    }
  }

  bool _isCanonicalTransactionHash(String value) {
    try {
      final bytes = base58Decode(value);
      return bytes.length == 32 && base58Encode(bytes) == value;
    } catch (_) {
      return false;
    }
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

    await _launchWalletFlow(
      'signMessage',
      uri,
      successUrl: params.callbackUrl ?? config.successUrl,
      signMessageRequest: params,
    );

    throw const _PendingCallbackException(
      'Signed message must be parsed from callback URL. '
      'Call handleSignMessageCallback() when you receive the deep link.',
    );
  }

  /// Handles a sign message callback from MyNearWallet.
  ///
  /// The wallet returns `accountId`/`publicKey`/`signature` in the URL
  /// **hash fragment** (`callback#accountId=…`); older flows used query
  /// parameters. Both are accepted, with fragment values winning.
  ///
  /// All three fields are required — a callback missing any of them throws
  /// [FormatException] rather than producing a partially-filled result.
  /// This parses without verifying; to also check the signature
  /// cryptographically use [completeSignMessage].
  SignedMessage handleSignMessageCallback(Uri callbackUri) {
    final pending = _pendingFlow;
    if (pending == null || pending.operation != 'signMessage') {
      try {
        return _parseSignMessageCallback(callbackUri);
      } catch (error, stackTrace) {
        final normalized = _normalizeMyNearError(error);
        Error.throwWithStackTrace(normalized, stackTrace);
      }
    }

    final flow = _requireSignMessageFlow(callbackUri);
    _callbackReceived(flow);
    NearErrorCode? failureCode;
    try {
      final signed = _parseSignMessageCallback(callbackUri);
      return signed;
    } catch (error, stackTrace) {
      final normalized = _normalizeMyNearError(error);
      failureCode = normalized.code;
      Error.throwWithStackTrace(normalized, stackTrace);
    } finally {
      _finishWalletFlow(flow, failureCode: failureCode);
    }
  }

  SignedMessage _parseSignMessageCallback(Uri callbackUri) {
    try {
      final params = {
        ...callbackUri.queryParameters,
        if (callbackUri.fragment.isNotEmpty)
          ...Uri.splitQueryString(callbackUri.fragment),
      };

      final accountId = params['accountId'];
      final publicKey = params['publicKey'];
      final signature = params['signature'];
      if (accountId == null ||
          accountId.isEmpty ||
          publicKey == null ||
          publicKey.isEmpty ||
          signature == null ||
          signature.isEmpty) {
        throw const MyNearWalletCallbackException();
      }

      return SignedMessage(
        accountId: AccountId(accountId),
        publicKey: PublicKey(publicKey),
        signature: signature,
        state: params['state'],
      );
    } on MyNearWalletCallbackException {
      rethrow;
    } catch (_) {
      throw const MyNearWalletCallbackException();
    }
  }

  /// Parses **and verifies** a sign-message callback against the original
  /// [request].
  ///
  /// On top of [handleSignMessageCallback] this:
  /// - rejects a callback whose `state` differs from `request.state`
  ///   (CSRF/mix-up protection), and
  /// - cryptographically verifies the ed25519 signature over the NEP-413
  ///   payload the app actually requested — including the callbackUrl that
  ///   MyNearWallet embeds in the signed bytes on redirect flows.
  ///
  /// Throws [FormatException] on missing fields or state mismatch and
  /// [SignatureVerificationException] if the signature does not verify.
  /// Note: whether the returned key belongs to the account should still be
  /// checked on-chain (`view_access_key`) before trusting it for auth.
  Future<SignedMessage> completeSignMessage(
    Uri callbackUri, {
    required SignMessageParams request,
  }) async {
    final flow = _requireSignMessageFlow(callbackUri);
    if (!_sameSignMessageRequest(flow.signMessageRequest, request)) {
      throw const MyNearWalletCallbackException();
    }
    _callbackReceived(flow);
    NearErrorCode? failureCode;
    try {
      final signed = _parseSignMessageCallback(callbackUri);

      if (signed.state != request.state) {
        throw const MyNearWalletCallbackException();
      }

      final payload = Nep413Payload(
        message: request.message,
        recipient: request.recipient,
        nonce: request.nonce,
        callbackUrl: request.callbackUrl ?? config.successUrl,
      );
      try {
        final valid = await verifyNep413Signature(
          payload: payload,
          signed: Nep413SignedMessage(
            accountId: signed.accountId,
            publicKey: signed.publicKey,
            signature: signed.signature,
          ),
        );
        if (!valid) throw const SignatureVerificationException();
      } on SignatureVerificationException {
        rethrow;
      } catch (_) {
        throw const SignatureVerificationException();
      }
      return signed;
    } catch (error, stackTrace) {
      final normalized = _normalizeMyNearError(error);
      failureCode = normalized.code;
      Error.throwWithStackTrace(normalized, stackTrace);
    } finally {
      _finishWalletFlow(flow, failureCode: failureCode);
    }
  }

  _PendingMyNearWalletFlow _requireSignMessageFlow(Uri callbackUri) {
    final flow = _pendingFlow;
    if (flow == null || flow.operation != 'signMessage') {
      throw const MyNearWalletException.missingCallback();
    }
    if (!_matchesCallbackRoute(callbackUri, flow.successUrl)) {
      throw const MyNearWalletCallbackException();
    }
    return flow;
  }

  bool _sameSignMessageRequest(
    SignMessageParams? pending,
    SignMessageParams supplied,
  ) {
    if (pending == null ||
        pending.message != supplied.message ||
        pending.recipient != supplied.recipient ||
        pending.callbackUrl != supplied.callbackUrl ||
        pending.state != supplied.state ||
        pending.nonce.length != supplied.nonce.length) {
      return false;
    }
    for (var i = 0; i < pending.nonce.length; i++) {
      if (pending.nonce[i] != supplied.nonce[i]) return false;
    }
    return true;
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

    await _launchWalletFlow(
      'verifyOwner',
      uri,
      successUrl: callbackUrl ?? config.successUrl,
    );

    throw const _PendingCallbackException(
      'Verification result must be parsed from callback URL.',
    );
  }

  Future<void> _launchWalletFlow(
    String operation,
    Uri uri, {
    required String successUrl,
    SignMessageParams? signMessageRequest,
  }) async {
    _openWalletFlow(
      operation,
      successUrl: successUrl,
      signMessageRequest: signMessageRequest,
    );
    final flow = _pendingFlow!;
    try {
      if (!await launchUrl(uri)) {
        throw const MyNearWalletException.deepLink();
      }
    } catch (error, stackTrace) {
      final normalized = _normalizeMyNearError(error);
      _finishWalletFlow(flow, failureCode: normalized.code);
      Error.throwWithStackTrace(normalized, stackTrace);
    }
  }

  void _openWalletFlow(
    String operation, {
    required String successUrl,
    String? failureUrl,
    SignMessageParams? signMessageRequest,
  }) {
    if (_pendingFlow != null) {
      throw const MyNearWalletException.flowInProgress();
    }
    _pendingFlow = _PendingMyNearWalletFlow(
      operation: operation,
      successUrl: successUrl,
      failureUrl: failureUrl,
      signMessageRequest: signMessageRequest,
    );
    _emitWalletEvent(
      NearLogEventType.walletFlowOpened,
      operation: operation,
      durationMs: 0,
      outcome: 'opened',
    );
  }

  void _callbackReceived(_PendingMyNearWalletFlow flow) {
    if (!identical(_pendingFlow, flow) || flow.callbackReceived) return;
    flow.callbackReceived = true;
    _emitWalletEvent(
      NearLogEventType.walletCallbackReceived,
      operation: flow.operation,
      durationMs: DateTime.now().difference(flow.startedAt).inMilliseconds,
      outcome: 'received',
    );
  }

  void _finishWalletFlow(
    _PendingMyNearWalletFlow flow, {
    NearErrorCode? failureCode,
  }) {
    if (!identical(_pendingFlow, flow)) return;
    _pendingFlow = null;
    _emitWalletEvent(
      failureCode == null
          ? NearLogEventType.walletFlowSucceeded
          : NearLogEventType.walletFlowFailed,
      operation: flow.operation,
      durationMs: DateTime.now().difference(flow.startedAt).inMilliseconds,
      outcome: failureCode == null ? 'success' : 'failure',
      failureCode: failureCode,
    );
  }

  void _emitWalletEvent(
    NearLogEventType type, {
    required String operation,
    required int durationMs,
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
          'walletId': id,
          'durationMs': durationMs,
          'outcome': outcome,
          if (failureCode != null) 'failureCode': failureCode.name,
        },
      ),
    );
  }

  NearSdkException _normalizeMyNearError(Object error) {
    if (error is NearSdkException) return error;
    if (error is UnsupportedError) {
      return const MyNearWalletException.unsupported();
    }
    if (error is FormatException ||
        error is TypeError ||
        error is ArgumentError) {
      return const MyNearWalletCallbackException();
    }
    return const MyNearWalletException.unknown();
  }

  @override
  void dispose() {
    // Nothing to clean up
  }
}

class _PendingMyNearWalletFlow {
  _PendingMyNearWalletFlow({
    required this.operation,
    required this.successUrl,
    this.failureUrl,
    this.signMessageRequest,
  }) : startedAt = DateTime.now();

  final String operation;
  final String successUrl;
  final String? failureUrl;
  final SignMessageParams? signMessageRequest;
  final DateTime startedAt;
  bool callbackReceived = false;
}

/// Exception thrown when waiting for a callback from the wallet.
class _PendingCallbackException extends NearSdkException {
  const _PendingCallbackException(String message)
    : super(code: NearErrorCode.missingCallback, message: message);
}

/// A normalized MyNearWallet failure.
class MyNearWalletException extends NearSdkException {
  const MyNearWalletException(
    String message, {
    NearErrorCode code = NearErrorCode.unknown,
    bool retryable = false,
  }) : super(code: code, message: message, retryable: retryable);

  const MyNearWalletException.deepLink()
    : super(
        code: NearErrorCode.deepLinkUnavailable,
        message: 'The MyNearWallet page could not be opened.',
      );

  const MyNearWalletException.flowInProgress()
    : super(
        code: NearErrorCode.unsupportedOperation,
        message: 'Another MyNearWallet flow is already pending.',
      );

  const MyNearWalletException.missingCallback()
    : super(
        code: NearErrorCode.missingCallback,
        message: 'No matching MyNearWallet callback is pending.',
      );

  const MyNearWalletException.unsupported()
    : super(
        code: NearErrorCode.unsupportedOperation,
        message: 'The MyNearWallet operation is unsupported.',
      );

  const MyNearWalletException.unknown()
    : super(
        code: NearErrorCode.unknown,
        message: 'The MyNearWallet request failed.',
      );

  @override
  String toString() =>
      'MyNearWalletException(code: $code, retryable: $retryable)';
}

/// A malformed MyNearWallet callback.
class MyNearWalletCallbackException extends NearSdkException
    implements FormatException {
  const MyNearWalletCallbackException()
    : super(
        code: NearErrorCode.walletResponseInvalid,
        message: 'MyNearWallet returned an invalid callback.',
      );

  @override
  int? get offset => null;

  @override
  dynamic get source => null;

  @override
  String toString() => 'MyNearWalletCallbackException(code: $code)';
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

/// A wallet callback carried a signature that does not verify.
class SignatureVerificationException extends NearSdkException {
  const SignatureVerificationException([
    String message = 'The MyNearWallet signature could not be verified.',
  ]) : super(code: NearErrorCode.signatureVerificationFailed, message: message);

  @override
  String toString() => 'SignatureVerificationException(code: $code)';
}
