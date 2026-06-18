@Tags(['integration', 'testnet'])
library;

import 'package:near_jsonrpc_client/near_jsonrpc_client.dart';
import 'package:test/test.dart';

/// Verifies the OpenAPI-generated client against live testnet — proving the
/// generated request/response models decode real nearcore responses.
void main() {
  late NearJsonRpcClient rpc;

  setUp(() {
    rpc = NearJsonRpcClient(endpoint: 'https://test.rpc.fastnear.com');
  });
  tearDown(() => rpc.close());

  test('status() decodes into the generated RpcStatusResponse', () async {
    final status = await rpc.status();
    expect(status.chain_id, equals('testnet'));
    expect(status.protocol_version, greaterThan(0));
    expect(status.sync_info!.latest_block_height, greaterThan(0));
  });

  test('gasPrice() decodes into the generated response', () async {
    final gas = await rpc.gasPrice(const RpcGasPriceRequest(block_id: null));
    expect(gas.gas_price, isNotEmpty);
  });

  test('block() by finality decodes the generated RpcBlockResponse', () async {
    final block = await rpc.block(
      RpcBlockRequest.fromJson({'finality': 'final'}),
    );
    expect(block.author, isNotEmpty);
    expect(block.header!.height, greaterThan(0));
    expect(block.chunks, isNotEmpty);
  });

  test('the client reports the spec version it was generated from', () {
    expect(NearJsonRpcClient.specVersion, isNotEmpty);
  });
}
