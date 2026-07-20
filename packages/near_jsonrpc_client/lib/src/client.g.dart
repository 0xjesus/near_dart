// GENERATED CODE — DO NOT EDIT BY HAND.
// Source: nearcore OpenAPI 1.2.13
// Regenerate: dart run tool/generate.dart
//
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.g.dart';

/// Thrown when the node returns a JSON-RPC error.
class NearRpcException implements Exception {
  NearRpcException(this.error);
  final Object? error;
  @override
  String toString() => 'NearRpcException($error)';
}

/// Typed NEAR JSON-RPC client generated from the nearcore OpenAPI spec.
class NearJsonRpcClient {
  NearJsonRpcClient({required this.endpoint, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  /// nearcore OpenAPI spec version this client was generated from.
  static const specVersion = '1.2.13';
  final String endpoint;
  final http.Client _http;
  var _id = 0;

  Future<dynamic> _call(String method, dynamic params) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 'near-dart-${_id++}',
      'method': method,
      if (params != null) 'params': params,
    });
    final res = await _http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['error'] != null) {
      throw NearRpcException(json['error']);
    }
    return json['result'];
  }

  /// Closes the underlying HTTP client.
  void close() => _http.close();

  /// Calls the `EXPERIMENTAL_call_function` JSON-RPC method.
  Future<RpcCallFunctionResponse> EXPERIMENTALCallFunction(
    RpcCallFunctionRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_call_function', params.toJson());
    return RpcCallFunctionResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_changes` JSON-RPC method.
  Future<RpcStateChangesInBlockResponse> EXPERIMENTALChanges(
    RpcStateChangesInBlockByTypeRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_changes', params.toJson());
    return RpcStateChangesInBlockResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_changes_in_block` JSON-RPC method.
  Future<RpcStateChangesInBlockByTypeResponse> EXPERIMENTALChangesInBlock(
    RpcStateChangesInBlockRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_changes_in_block',
      params.toJson(),
    );
    return RpcStateChangesInBlockByTypeResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_congestion_level` JSON-RPC method.
  Future<RpcCongestionLevelResponse> EXPERIMENTALCongestionLevel(
    RpcCongestionLevelRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_congestion_level',
      params.toJson(),
    );
    return RpcCongestionLevelResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_genesis_config` JSON-RPC method.
  Future<GenesisConfig> EXPERIMENTALGenesisConfig([dynamic params]) async {
    final result = await _call(r'EXPERIMENTAL_genesis_config', params);
    return GenesisConfig.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_light_client_block_proof` JSON-RPC method.
  Future<RpcLightClientBlockProofResponse> EXPERIMENTALLightClientBlockProof(
    RpcLightClientBlockProofRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_light_client_block_proof',
      params.toJson(),
    );
    return RpcLightClientBlockProofResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_light_client_proof` JSON-RPC method.
  Future<RpcLightClientExecutionProofResponse> EXPERIMENTALLightClientProof(
    RpcLightClientExecutionProofRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_light_client_proof',
      params.toJson(),
    );
    return RpcLightClientExecutionProofResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_maintenance_windows` JSON-RPC method.
  Future<dynamic> EXPERIMENTALMaintenanceWindows(
    RpcMaintenanceWindowsRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_maintenance_windows',
      params.toJson(),
    );
    return result;
  }

  /// Calls the `EXPERIMENTAL_protocol_config` JSON-RPC method.
  Future<RpcProtocolConfigResponse> EXPERIMENTALProtocolConfig(
    RpcProtocolConfigRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_protocol_config',
      params.toJson(),
    );
    return RpcProtocolConfigResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_receipt` JSON-RPC method.
  Future<RpcReceiptResponse> EXPERIMENTALReceipt(
    RpcReceiptRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_receipt', params.toJson());
    return RpcReceiptResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_receipt_to_tx` JSON-RPC method.
  Future<RpcReceiptToTxResponse> EXPERIMENTALReceiptToTx(
    RpcReceiptToTxRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_receipt_to_tx', params.toJson());
    return RpcReceiptToTxResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_split_storage_info` JSON-RPC method.
  Future<RpcSplitStorageInfoResponse> EXPERIMENTALSplitStorageInfo(
    RpcSplitStorageInfoRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_split_storage_info',
      params.toJson(),
    );
    return RpcSplitStorageInfoResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_tx_status` JSON-RPC method.
  Future<RpcTransactionResponse> EXPERIMENTALTxStatus(
    RpcTransactionStatusRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_tx_status', params.toJson());
    return RpcTransactionResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_validators_ordered` JSON-RPC method.
  Future<dynamic> EXPERIMENTALValidatorsOrdered(
    RpcValidatorsOrderedRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_validators_ordered',
      params.toJson(),
    );
    return result;
  }

  /// Calls the `EXPERIMENTAL_view_access_key` JSON-RPC method.
  Future<RpcViewAccessKeyResponse> EXPERIMENTALViewAccessKey(
    RpcViewAccessKeyRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_view_access_key',
      params.toJson(),
    );
    return RpcViewAccessKeyResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_view_access_key_list` JSON-RPC method.
  Future<RpcViewAccessKeyListResponse> EXPERIMENTALViewAccessKeyList(
    RpcViewAccessKeyListRequest params,
  ) async {
    final result = await _call(
      r'EXPERIMENTAL_view_access_key_list',
      params.toJson(),
    );
    return RpcViewAccessKeyListResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_view_account` JSON-RPC method.
  Future<RpcViewAccountResponse> EXPERIMENTALViewAccount(
    RpcViewAccountRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_view_account', params.toJson());
    return RpcViewAccountResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_view_code` JSON-RPC method.
  Future<RpcViewCodeResponse> EXPERIMENTALViewCode(
    RpcViewCodeRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_view_code', params.toJson());
    return RpcViewCodeResponse.fromJson(result);
  }

  /// Calls the `EXPERIMENTAL_view_state` JSON-RPC method.
  Future<RpcViewStateResponse> EXPERIMENTALViewState(
    RpcViewStateRequest params,
  ) async {
    final result = await _call(r'EXPERIMENTAL_view_state', params.toJson());
    return RpcViewStateResponse.fromJson(result);
  }

  /// Calls the `block` JSON-RPC method.
  Future<RpcBlockResponse> block(RpcBlockRequest params) async {
    final result = await _call(r'block', params.toJson());
    return RpcBlockResponse.fromJson(result);
  }

  /// Calls the `block_effects` JSON-RPC method.
  Future<RpcStateChangesInBlockByTypeResponse> blockEffects(
    RpcStateChangesInBlockRequest params,
  ) async {
    final result = await _call(r'block_effects', params.toJson());
    return RpcStateChangesInBlockByTypeResponse.fromJson(result);
  }

  /// Calls the `broadcast_tx_async` JSON-RPC method.
  Future<CryptoHash> broadcastTxAsync(RpcSendTransactionRequest params) async {
    final result = await _call(r'broadcast_tx_async', params.toJson());
    return result as CryptoHash;
  }

  /// Calls the `broadcast_tx_commit` JSON-RPC method.
  Future<RpcTransactionResponse> broadcastTxCommit(
    RpcSendTransactionRequest params,
  ) async {
    final result = await _call(r'broadcast_tx_commit', params.toJson());
    return RpcTransactionResponse.fromJson(result);
  }

  /// Calls the `changes` JSON-RPC method.
  Future<RpcStateChangesInBlockResponse> changes(
    RpcStateChangesInBlockByTypeRequest params,
  ) async {
    final result = await _call(r'changes', params.toJson());
    return RpcStateChangesInBlockResponse.fromJson(result);
  }

  /// Calls the `chunk` JSON-RPC method.
  Future<RpcChunkResponse> chunk(RpcChunkRequest params) async {
    final result = await _call(r'chunk', params.toJson());
    return RpcChunkResponse.fromJson(result);
  }

  /// Calls the `client_config` JSON-RPC method.
  Future<RpcClientConfigResponse> clientConfig([dynamic params]) async {
    final result = await _call(r'client_config', params);
    return RpcClientConfigResponse.fromJson(result);
  }

  /// Calls the `gas_price` JSON-RPC method.
  Future<RpcGasPriceResponse> gasPrice(RpcGasPriceRequest params) async {
    final result = await _call(r'gas_price', params.toJson());
    return RpcGasPriceResponse.fromJson(result);
  }

  /// Calls the `genesis_config` JSON-RPC method.
  Future<GenesisConfig> genesisConfig([dynamic params]) async {
    final result = await _call(r'genesis_config', params);
    return GenesisConfig.fromJson(result);
  }

  /// Calls the `health` JSON-RPC method.
  Future<dynamic> health([dynamic params]) async {
    final result = await _call(r'health', params);
    return result;
  }

  /// Calls the `light_client_proof` JSON-RPC method.
  Future<RpcLightClientExecutionProofResponse> lightClientProof(
    RpcLightClientExecutionProofRequest params,
  ) async {
    final result = await _call(r'light_client_proof', params.toJson());
    return RpcLightClientExecutionProofResponse.fromJson(result);
  }

  /// Calls the `maintenance_windows` JSON-RPC method.
  Future<dynamic> maintenanceWindows(
    RpcMaintenanceWindowsRequest params,
  ) async {
    final result = await _call(r'maintenance_windows', params.toJson());
    return result;
  }

  /// Calls the `network_info` JSON-RPC method.
  Future<RpcNetworkInfoResponse> networkInfo([dynamic params]) async {
    final result = await _call(r'network_info', params);
    return RpcNetworkInfoResponse.fromJson(result);
  }

  /// Calls the `next_light_client_block` JSON-RPC method.
  Future<RpcLightClientNextBlockResponse> nextLightClientBlock(
    RpcLightClientNextBlockRequest params,
  ) async {
    final result = await _call(r'next_light_client_block', params.toJson());
    return RpcLightClientNextBlockResponse.fromJson(result);
  }

  /// Calls the `query` JSON-RPC method.
  Future<RpcQueryResponse> query(RpcQueryRequest params) async {
    final result = await _call(r'query', params.toJson());
    return RpcQueryResponse.fromJson(result);
  }

  /// Calls the `send_tx` JSON-RPC method.
  Future<RpcTransactionResponse> sendTx(
    RpcSendTransactionRequest params,
  ) async {
    final result = await _call(r'send_tx', params.toJson());
    return RpcTransactionResponse.fromJson(result);
  }

  /// Calls the `status` JSON-RPC method.
  Future<RpcStatusResponse> status([dynamic params]) async {
    final result = await _call(r'status', params);
    return RpcStatusResponse.fromJson(result);
  }

  /// Calls the `tx` JSON-RPC method.
  Future<RpcTransactionResponse> tx(RpcTransactionStatusRequest params) async {
    final result = await _call(r'tx', params.toJson());
    return RpcTransactionResponse.fromJson(result);
  }

  /// Calls the `validators` JSON-RPC method.
  Future<RpcValidatorResponse> validators(RpcValidatorRequest params) async {
    final result = await _call(r'validators', params.toJson());
    return RpcValidatorResponse.fromJson(result);
  }
}
