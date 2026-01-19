import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

import 'responses/status_response.dart';
import 'responses/block_response.dart';
import 'responses/account_response.dart';
import 'responses/gas_price_response.dart';
import 'responses/call_function_response.dart';
import 'responses/validators_response.dart';
import 'responses/transaction_response.dart';
import 'responses/chunk_response.dart';

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
  NearRpcClient({
    required this.rpcUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Creates a client configured for NEAR testnet.
  factory NearRpcClient.testnet({http.Client? httpClient}) {
    return NearRpcClient(
      rpcUrl: 'https://rpc.testnet.near.org',
      httpClient: httpClient,
    );
  }

  /// Creates a client configured for NEAR mainnet.
  factory NearRpcClient.mainnet({http.Client? httpClient}) {
    return NearRpcClient(
      rpcUrl: 'https://rpc.mainnet.near.org',
      httpClient: httpClient,
    );
  }

  /// Creates a client configured for NEAR betanet.
  factory NearRpcClient.betanet({http.Client? httpClient}) {
    return NearRpcClient(
      rpcUrl: 'https://rpc.betanet.near.org',
      httpClient: httpClient,
    );
  }

  /// The RPC endpoint URL.
  final String rpcUrl;

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
  ) async {
    final requestJson = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': 'near-dart-${DateTime.now().millisecondsSinceEpoch}',
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestJson),
      );

      if (response.statusCode != 200) {
        return RpcResult.failure(
          RpcError.http(response.statusCode, response.body),
        );
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final rpcResponse = JsonRpcResponse.fromJson(jsonResponse);

      if (rpcResponse.isError) {
        return RpcResult.failure(
          RpcError.fromJsonRpcError(rpcResponse.error!),
        );
      }

      final result = parser(rpcResponse.result as Map<String, dynamic>);
      return RpcResult.success(result);
    } on FormatException catch (e) {
      return RpcResult.failure(RpcError.parse('Failed to parse response', e));
    } on http.ClientException catch (e) {
      return RpcResult.failure(RpcError.network(e.message, e));
    } catch (e) {
      return RpcResult.failure(RpcError.network('Unknown error: $e', e));
    }
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
    return call(
      'query',
      {
        'request_type': 'view_account',
        'account_id': accountId.toJson(),
        ...blockReference.toJson(),
      },
      AccountView.fromJson,
    );
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
    return call(
      'query',
      {
        'request_type': 'view_access_key',
        'account_id': accountId.toJson(),
        'public_key': publicKey.toJson(),
        ...blockReference.toJson(),
      },
      AccessKeyView.fromJson,
    );
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
    return call(
      'gas_price',
      {'block_id': blockId},
      GasPriceResponse.fromJson,
    );
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

    return call(
      'query',
      {
        'request_type': 'call_function',
        'account_id': accountId.toJson(),
        'method_name': methodName,
        'args_base64': argsBase64,
        ...blockReference.toJson(),
      },
      CallFunctionResponse.fromJson,
    );
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
    return _callRaw(
      'validators',
      [blockId],
      ValidatorsResponse.fromJson,
    );
  }

  /// Returns the status of a transaction.
  ///
  /// This queries the final execution outcome of a transaction.
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
  }) {
    return call(
      'tx',
      {
        'tx_hash': transactionHash,
        'sender_account_id': senderAccountId.toJson(),
        'wait_until': 'EXECUTED',
      },
      TransactionResponse.fromJson,
    );
  }

  /// Returns details of a specific chunk.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.chunk(chunkHash: 'abc123...');
  /// ```
  Future<RpcResult<ChunkResponse>> chunk({required String chunkHash}) {
    return call(
      'chunk',
      {'chunk_id': chunkHash},
      ChunkResponse.fromJson,
    );
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
    return call(
      'query',
      {
        'request_type': 'view_access_key_list',
        'account_id': accountId.toJson(),
        ...blockReference.toJson(),
      },
      AccessKeyListResponse.fromJson,
    );
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
    return call(
      'query',
      {
        'request_type': 'view_code',
        'account_id': accountId.toJson(),
        ...blockReference.toJson(),
      },
      ContractCodeResponse.fromJson,
    );
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
    return call(
      'query',
      {
        'request_type': 'view_state',
        'account_id': accountId.toJson(),
        'prefix_base64': prefixBase64,
        ...blockReference.toJson(),
      },
      ContractStateResponse.fromJson,
    );
  }

  /// Disposes of the HTTP client.
  ///
  /// Call this when you're done using the client to free resources.
  void close() {
    _httpClient.close();
  }
}
