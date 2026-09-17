import 'package:near_jsonrpc_client/near_jsonrpc_client.dart';

/// Minimal status query against public testnet RPC.
Future<void> main() async {
  final rpc = NearJsonRpcClient(endpoint: 'https://test.rpc.fastnear.com');
  try {
    final status = await rpc.status();
    print('chain: ${status.chain_id}');
    print('height: ${status.sync_info?.latest_block_height}');
  } finally {
    rpc.close();
  }
}
