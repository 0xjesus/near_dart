import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

import '../diagnostics/diagnostic_endpoint_sanitizer.dart';

/// How long the RPC node should wait before returning a transaction result.
///
/// See https://docs.near.org/api/rpc/transactions for the semantics of
/// each level.
enum TxExecutionStatus {
  /// Return immediately; the transaction is only validated and routed.
  none('NONE'),

  /// The transaction is included in a block.
  included('INCLUDED'),

  /// Executed optimistically; the result is known (default for `send_tx`).
  executedOptimistic('EXECUTED_OPTIMISTIC'),

  /// The block containing the transaction is final.
  includedFinal('INCLUDED_FINAL'),

  /// Executed and all non-refund receipts are final.
  executed('EXECUTED'),

  /// Everything, including refund receipts, is final.
  final_('FINAL');

  const TxExecutionStatus(this.rpcValue);

  /// The wire value for the `wait_until` RPC parameter.
  final String rpcValue;
}

/// A type-safe client for NEAR Protocol's JSON-RPC API.
///
/// This client provides methods to interact with the NEAR blockchain,
/// including querying block information, account data, and sending transactions.
///
/// Example:
/// ```dart
/// final client = NearRpcClient.testnet();
///
/// // Get node status
/// final status = await client.status();
///
/// // Get account info
/// final account = await client.viewAccount(
///   accountId: AccountId('alice.testnet'),
///   blockReference: BlockReference.finality(Finality.final_),
/// );
/// ```
class NearRpcClient {
  /// Creates a client with a custom RPC URL.
  ///
  /// When [fallbackUrls] is non-empty, requests that fail at the
  /// transport level (network errors, non-200 HTTP responses such as 429
  /// rate limits) are retried against each fallback in order. JSON-RPC
  /// level errors are returned as-is — they are answers, not outages.
  NearRpcClient({
    required this.rpcUrl,
    this.fallbackUrls = const [],
    this.timeout = const Duration(seconds: 30),
    this.network,
    this.logger,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Creates a client from a typed [NearNetwork] configuration.
  factory NearRpcClient.forNetwork(
    NearNetwork network, {
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
    NearLogger? logger,
  }) {
    return NearRpcClient(
      rpcUrl: network.rpcUrl,
      fallbackUrls: network.fallbackRpcUrls,
      timeout: timeout,
      network: network,
      logger: logger,
      httpClient: httpClient,
    );
  }

  /// Creates a client configured for NEAR testnet.
  ///
  /// Defaults to FastNear's free tier. The legacy `rpc.testnet.near.org`
  /// endpoint (deprecated in 2025, severely rate limited) is kept as a
  /// fallback only.
  factory NearRpcClient.testnet({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
    NearLogger? logger,
  }) {
    return NearRpcClient.forNetwork(
      NearNetwork.testnet,
      timeout: timeout,
      logger: logger,
      httpClient: httpClient,
    );
  }

  /// Creates a client configured for NEAR mainnet.
  ///
  /// Defaults to FastNear's free tier. The legacy `rpc.mainnet.near.org`
  /// endpoint (deprecated in 2025, severely rate limited) is kept as a
  /// fallback only.
  factory NearRpcClient.mainnet({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
    NearLogger? logger,
  }) {
    return NearRpcClient.forNetwork(
      NearNetwork.mainnet,
      timeout: timeout,
      logger: logger,
      httpClient: httpClient,
    );
  }

  /// The primary RPC endpoint URL.
  final String rpcUrl;

  /// Fallback RPC endpoints, tried in order on transport-level failures.
  final List<String> fallbackUrls;

  /// Per-request timeout. A request exceeding this is treated as a
  /// transport failure (`RpcError.timeout`) and triggers failover.
  final Duration timeout;

  /// Typed network metadata, when the client was created from a known network.
  final NearNetwork? network;

  /// Receives safe operational diagnostics for RPC requests.
  final NearLogger? logger;

  final http.Client _httpClient;

  /// Sends a JSON-RPC request and returns the result.
  ///
  /// This is the low-level method used by all RPC calls. You can use this
  /// directly for methods not yet wrapped by the client.
  @protected
  Future<RpcResult<T>> call<T>(
    String method,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) parser,
  ) async {
    return _callRaw(method, params, parser);
  }

  /// Low-level method for RPC calls that accepts any params type.
  Future<RpcResult<T>> _callRaw<T>(
    String method,
    dynamic params,
    T Function(Map<String, dynamic>) parser,
  ) {
    return _callWithFailover(
      method,
      params,
      (result) => parser(result as Map<String, dynamic>),
    );
  }

  /// Posts a JSON-RPC request to the primary URL, retrying fallbacks on
  /// transport-level failures, and parses the result with [parser].
  Future<RpcResult<T>> _callWithFailover<T>(
    String method,
    dynamic params,
    T Function(dynamic result) parser,
  ) async {
    final requestJson = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': 'near-dart-${DateTime.now().millisecondsSinceEpoch}',
    };
    final body = jsonEncode(requestJson);

    final endpoints = [rpcUrl, ...fallbackUrls];
    final stopwatch = Stopwatch()..start();
    RpcResult<T>? lastTransportFailure;
    int? lastStatusCode;

    _emitRpcEvent(
      NearLogEventType.rpcRequestStarted,
      method: method,
      url: endpoints.first,
      attempt: 1,
      endpointCount: endpoints.length,
      stopwatch: stopwatch,
    );

    for (var index = 0; index < endpoints.length; index++) {
      final url = endpoints[index];
      final attempt = index + 1;
      lastStatusCode = null;
      final endpoint = validateSupportedHttpEndpoint(url);
      if (!endpoint.isSupported) {
        lastTransportFailure = RpcResult.failure(
          RpcError.network('RPC endpoint is invalid or unsupported.'),
        );
        if (index < endpoints.length - 1) {
          _emitRpcEvent(
            NearLogEventType.rpcRequestRetried,
            method: method,
            url: url,
            attempt: attempt,
            endpointCount: endpoints.length,
            stopwatch: stopwatch,
          );
        }
        continue;
      }
      try {
        final response = await _httpClient
            .post(
              endpoint.uri!,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);
        lastStatusCode = response.statusCode;

        if (response.statusCode != 200) {
          // Rate limits and server outages: try the next endpoint.
          lastTransportFailure = RpcResult.failure(
            RpcError.http(response.statusCode, response.body),
          );
          if (index < endpoints.length - 1) {
            _emitRpcEvent(
              NearLogEventType.rpcRequestRetried,
              method: method,
              url: url,
              attempt: attempt,
              endpointCount: endpoints.length,
              statusCode: response.statusCode,
              stopwatch: stopwatch,
            );
          }
          continue;
        }

        try {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          final rpcResponse = JsonRpcResponse.fromJson(jsonResponse);

          if (rpcResponse.isError) {
            // The node answered: its error is the answer, not an outage.
            final failure = RpcResult<T>.failure(
              RpcError.fromJsonRpcError(rpcResponse.error!),
            );
            _emitRpcEvent(
              NearLogEventType.rpcRequestFailed,
              method: method,
              url: url,
              attempt: attempt,
              endpointCount: endpoints.length,
              statusCode: response.statusCode,
              stopwatch: stopwatch,
            );
            return failure;
          }

          final legacyQueryError = _legacyQueryRuntimeError(
            method,
            rpcResponse.result,
          );
          if (legacyQueryError != null) {
            final failure = RpcResult<T>.failure(legacyQueryError);
            _emitRpcEvent(
              NearLogEventType.rpcRequestFailed,
              method: method,
              url: url,
              attempt: attempt,
              endpointCount: endpoints.length,
              statusCode: response.statusCode,
              stopwatch: stopwatch,
            );
            return failure;
          }

          final success = RpcResult<T>.success(parser(rpcResponse.result));
          _emitRpcEvent(
            NearLogEventType.rpcRequestSucceeded,
            method: method,
            url: url,
            attempt: attempt,
            endpointCount: endpoints.length,
            statusCode: response.statusCode,
            stopwatch: stopwatch,
          );
          return success;
        } catch (error) {
          final failure = RpcResult<T>.failure(
            RpcError.parse('Failed to parse response', error),
          );
          _emitRpcEvent(
            NearLogEventType.rpcRequestFailed,
            method: method,
            url: url,
            attempt: attempt,
            endpointCount: endpoints.length,
            statusCode: response.statusCode,
            stopwatch: stopwatch,
          );
          return failure;
        }
      } on TimeoutException {
        // A stalled node is a transport failure: try the next endpoint.
        lastTransportFailure = RpcResult.failure(
          RpcError.timeout('RPC request timed out.'),
        );
        if (index < endpoints.length - 1) {
          _emitRpcEvent(
            NearLogEventType.rpcRequestRetried,
            method: method,
            url: url,
            attempt: attempt,
            endpointCount: endpoints.length,
            stopwatch: stopwatch,
          );
        }
      } on http.ClientException {
        lastTransportFailure = RpcResult.failure(
          RpcError.network('RPC transport failed.'),
        );
        if (index < endpoints.length - 1) {
          _emitRpcEvent(
            NearLogEventType.rpcRequestRetried,
            method: method,
            url: url,
            attempt: attempt,
            endpointCount: endpoints.length,
            stopwatch: stopwatch,
          );
        }
      } catch (_) {
        lastTransportFailure = RpcResult.failure(
          RpcError.network('RPC transport failed.'),
        );
        if (index < endpoints.length - 1) {
          _emitRpcEvent(
            NearLogEventType.rpcRequestRetried,
            method: method,
            url: url,
            attempt: attempt,
            endpointCount: endpoints.length,
            stopwatch: stopwatch,
          );
        }
      }
    }
    final failure = lastTransportFailure!;
    _emitRpcEvent(
      NearLogEventType.rpcRequestFailed,
      method: method,
      url: endpoints.last,
      attempt: endpoints.length,
      endpointCount: endpoints.length,
      statusCode: lastStatusCode,
      stopwatch: stopwatch,
    );
    return failure;
  }

  RpcError? _legacyQueryRuntimeError(String method, dynamic result) {
    if (method != 'query' || result is! Map<String, dynamic>) return null;

    final error = result['error'];
    if (error is! String ||
        error.isEmpty ||
        result['logs'] is! List<dynamic> ||
        result['block_height'] is! int ||
        result['block_hash'] is! String) {
      return null;
    }

    return RpcError(
      kind: RpcErrorKind.runtimeError,
      message: 'NEAR query failed at runtime.',
      data: Map<String, dynamic>.unmodifiable(result),
    );
  }

  void _emitRpcEvent(
    NearLogEventType type, {
    required String method,
    required String url,
    required int attempt,
    required int endpointCount,
    required Stopwatch stopwatch,
    int? statusCode,
  }) {
    emitNearLog(
      logger,
      NearLogEvent(
        level: switch (type) {
          NearLogEventType.rpcRequestRetried => NearLogLevel.warning,
          NearLogEventType.rpcRequestFailed => NearLogLevel.error,
          _ => NearLogLevel.info,
        },
        type: type,
        operation: method,
        metadata: {
          'endpoint': sanitizeDiagnosticEndpointOrigin(url),
          'attempt': attempt,
          'endpointCount': endpointCount,
          if (statusCode != null) 'statusCode': statusCode,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      ),
    );
  }

  /// Returns the status of the connected RPC node.
  ///
  /// This includes information about sync status, node version,
  /// protocol version, and the current set of validators.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.status();
  /// if (result.isSuccess) {
  ///   print('Chain ID: ${result.getOrNull()!.chainId}');
  /// }
  /// ```
  Future<RpcResult<StatusResponse>> status() {
    return call('status', {}, StatusResponse.fromJson);
  }

  /// Returns block details for the given block reference.
  ///
  /// You can query by finality, block height, or block hash.
  ///
  /// Example:
  /// ```dart
  /// // By finality
  /// final result = await client.block(
  ///   BlockReference.finality(Finality.final_),
  /// );
  ///
  /// // By height
  /// final result = await client.block(
  ///   BlockReference.blockId(12345678),
  /// );
  ///
  /// // By hash
  /// final result = await client.block(
  ///   BlockReference.blockHash(CryptoHash('abc...')),
  /// );
  /// ```
  Future<RpcResult<BlockResponse>> block(BlockReference blockReference) {
    return call('block', blockReference.toJson(), BlockResponse.fromJson);
  }

  /// Returns account information for the given account ID.
  ///
  /// This uses the `query` RPC method with `request_type: view_account`.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.viewAccount(
  ///   accountId: AccountId('alice.testnet'),
  ///   blockReference: BlockReference.finality(Finality.final_),
  /// );
  /// ```
  Future<RpcResult<AccountView>> viewAccount({
    required AccountId accountId,
    required BlockReference blockReference,
  }) {
    return call('query', {
      'request_type': 'view_account',
      'account_id': accountId.toJson(),
      ...blockReference.toJson(),
    }, AccountView.fromJson);
  }

  /// Returns access key information for a given public key.
  ///
  /// This uses the `query` RPC method with `request_type: view_access_key`.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.viewAccessKey(
  ///   accountId: AccountId('alice.testnet'),
  ///   publicKey: PublicKey('ed25519:...'),
  ///   blockReference: BlockReference.finality(Finality.final_),
  /// );
  /// ```
  Future<RpcResult<AccessKeyView>> viewAccessKey({
    required AccountId accountId,
    required PublicKey publicKey,
    required BlockReference blockReference,
  }) {
    return call('query', {
      'request_type': 'view_access_key',
      'account_id': accountId.toJson(),
      'public_key': publicKey.toJson(),
      ...blockReference.toJson(),
    }, AccessKeyView.fromJson);
  }

  /// Returns the current gas price.
  ///
  /// The gas price is returned in yoctoNEAR per gas unit.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.gasPrice();
  /// if (result.isSuccess) {
  ///   print('Gas price: ${result.getOrNull()!.gasPrice}');
  /// }
  /// ```
  Future<RpcResult<GasPriceResponse>> gasPrice([String? blockId]) {
    return call('gas_price', {'block_id': blockId}, GasPriceResponse.fromJson);
  }

  /// Calls a view function on a smart contract.
  ///
  /// This uses the `query` RPC method with `request_type: call_function`.
  /// The function is called without modifying state.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.callFunction(
  ///   accountId: AccountId('wrap.near'),
  ///   methodName: 'ft_balance_of',
  ///   args: {'account_id': 'alice.near'},
  ///   blockReference: BlockReference.finality(Finality.final_),
  /// );
  ///
  /// if (result.isSuccess) {
  ///   final balance = result.getOrNull()!.resultAsJson();
  ///   print('Balance: $balance');
  /// }
  /// ```
  Future<RpcResult<CallFunctionResponse>> callFunction({
    required AccountId accountId,
    required String methodName,
    Map<String, dynamic>? args,
    required BlockReference blockReference,
  }) {
    // Encode args as base64 JSON
    final argsBase64 = args != null
        ? base64Encode(utf8.encode(jsonEncode(args)))
        : base64Encode(utf8.encode('{}'));

    return call('query', {
      'request_type': 'call_function',
      'account_id': accountId.toJson(),
      'method_name': methodName,
      'args_base64': argsBase64,
      ...blockReference.toJson(),
    }, CallFunctionResponse.fromJson);
  }

  /// Calls a view function and decodes its JSON result as [T].
  ///
  /// The query defaults to final block finality. If [decode] rejects the
  /// returned JSON shape, this method returns an [RpcErrorKind.parseError]
  /// failure instead of throwing from the decoder.
  ///
  /// ```dart
  /// final result = await client.viewFunction<int>(
  ///   contractId: AccountId('counter.near'),
  ///   methodName: 'get_count',
  ///   decode: (json) => (json as Map<String, dynamic>)['count'] as int,
  /// );
  /// ```
  Future<RpcResult<T>> viewFunction<T>({
    required AccountId contractId,
    required String methodName,
    Map<String, dynamic>? args,
    required T Function(Object? json) decode,
    BlockReference? blockReference,
  }) async {
    final response = await callFunction(
      accountId: contractId,
      methodName: methodName,
      args: args,
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    );
    if (response case RpcFailure<CallFunctionResponse>(:final error)) {
      return RpcResult<T>.failure(error);
    }
    try {
      return RpcResult<T>.success(decode(response.getOrThrow().resultAsJson()));
    } catch (error) {
      return RpcResult<T>.failure(
        RpcError.parse('Failed to decode view function result', error),
      );
    }
  }

  /// Returns information about validators for a given epoch.
  ///
  /// Pass null for the latest epoch, or specify a block height/hash.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.validators();
  /// if (result.isSuccess) {
  ///   final validators = result.getOrNull()!;
  ///   print('Current validators: ${validators.currentValidators.length}');
  /// }
  /// ```
  Future<RpcResult<ValidatorsResponse>> validators([Object? blockId]) {
    // NEAR RPC expects [null] for latest epoch or [block_id]
    return _callRaw('validators', [blockId], ValidatorsResponse.fromJson);
  }

  /// Broadcasts a signed transaction and waits for execution.
  ///
  /// Uses the `send_tx` RPC method. By default waits until
  /// [TxExecutionStatus.executedOptimistic] — the transaction has been
  /// executed and the result is known, but not yet finalized. Use
  /// [TxExecutionStatus.final_] to wait for full finality.
  ///
  /// Example:
  /// ```dart
  /// final signed = await signTransaction(transaction, keyPair);
  /// final result = await client.sendTransaction(signed);
  /// if (result.isSuccess) {
  ///   print('Executed: ${result.getOrNull()!.transaction.hash}');
  /// }
  /// ```
  Future<RpcResult<TransactionResponse>> sendTransaction(
    SignedTransaction signedTransaction, {
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return call('send_tx', {
      'signed_tx_base64': signedTransaction.encodeToBase64(),
      'wait_until': waitUntil.rpcValue,
    }, TransactionResponse.fromJson);
  }

  /// Broadcasts a signed transaction without waiting for execution.
  ///
  /// Uses the `broadcast_tx_async` RPC method and returns the transaction
  /// hash immediately. Query the outcome later with [txStatus].
  Future<RpcResult<String>> sendTransactionAsync(
    SignedTransaction signedTransaction,
  ) {
    return _callWithFailover('broadcast_tx_async', [
      signedTransaction.encodeToBase64(),
    ], (result) => result as String);
  }

  /// Returns the status of a transaction.
  ///
  /// This queries the transaction outcome at [waitUntil], which defaults to
  /// [TxExecutionStatus.executed].
  ///
  /// Example:
  /// ```dart
  /// final result = await client.txStatus(
  ///   transactionHash: 'abc123...',
  ///   senderAccountId: AccountId('alice.near'),
  /// );
  /// ```
  Future<RpcResult<TransactionResponse>> txStatus({
    required String transactionHash,
    required AccountId senderAccountId,
    TxExecutionStatus waitUntil = TxExecutionStatus.executed,
  }) {
    return call('tx', {
      'tx_hash': transactionHash,
      'sender_account_id': senderAccountId.toJson(),
      'wait_until': waitUntil.rpcValue,
    }, TransactionResponse.fromJson);
  }

  /// Returns details of a specific chunk.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.chunk(chunkHash: 'abc123...');
  /// ```
  Future<RpcResult<ChunkResponse>> chunk({required String chunkHash}) {
    return call('chunk', {'chunk_id': chunkHash}, ChunkResponse.fromJson);
  }

  /// Returns all access keys for an account.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.viewAccessKeyList(
  ///   accountId: AccountId('alice.near'),
  ///   blockReference: BlockReference.finality(Finality.final_),
  /// );
  /// ```
  Future<RpcResult<AccessKeyListResponse>> viewAccessKeyList({
    required AccountId accountId,
    required BlockReference blockReference,
  }) {
    return call('query', {
      'request_type': 'view_access_key_list',
      'account_id': accountId.toJson(),
      ...blockReference.toJson(),
    }, AccessKeyListResponse.fromJson);
  }

  /// Returns the contract code for an account.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.viewCode(
  ///   accountId: AccountId('contract.near'),
  ///   blockReference: BlockReference.finality(Finality.final_),
  /// );
  /// ```
  Future<RpcResult<ContractCodeResponse>> viewCode({
    required AccountId accountId,
    required BlockReference blockReference,
  }) {
    return call('query', {
      'request_type': 'view_code',
      'account_id': accountId.toJson(),
      ...blockReference.toJson(),
    }, ContractCodeResponse.fromJson);
  }

  /// Returns the contract state (key-value pairs) for an account.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.viewState(
  ///   accountId: AccountId('contract.near'),
  ///   prefixBase64: '', // Empty string for all state
  ///   blockReference: BlockReference.finality(Finality.final_),
  /// );
  /// ```
  Future<RpcResult<ContractStateResponse>> viewState({
    required AccountId accountId,
    String prefixBase64 = '',
    required BlockReference blockReference,
  }) {
    return call('query', {
      'request_type': 'view_state',
      'account_id': accountId.toJson(),
      'prefix_base64': prefixBase64,
      ...blockReference.toJson(),
    }, ContractStateResponse.fromJson);
  }

  /// Disposes of the HTTP client.
  ///
  /// Call this when you're done using the client to free resources.
  void close() {
    _httpClient.close();
  }
}
