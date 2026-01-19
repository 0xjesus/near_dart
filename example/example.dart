import 'package:near_dart/near_dart.dart';

void main() async {
  // Create client for mainnet
  final client = NearRpcClient.mainnet();

  // Get network status
  final status = await client.status();
  switch (status) {
    case RpcSuccess(:final value):
      print('Chain: ${value.chainId}');
      print('Block: ${value.syncInfo.latestBlockHeight}');
    case RpcFailure(:final error):
      print('Error: ${error.message}');
  }

  // Query account
  final result = await client.viewAccount(
    accountId: AccountId('near'),
    blockReference: BlockReference.finality(Finality.final_),
  );

  if (result.isSuccess) {
    final account = result.getOrNull()!;
    print('Balance: ${account.amount.toNear()} NEAR');
  }

  // Build a transaction
  final tx = Transaction(
    signerId: AccountId('alice.near'),
    receiverId: AccountId('bob.near'),
    actions: [
      TransferAction(deposit: NearToken.fromNear(1)),
    ],
  );
  print('Transaction: ${tx.toJson()}');

  client.close();
}
