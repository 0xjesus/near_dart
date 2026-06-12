/// Integration tests that run against the real NEAR testnet.
///
/// These tests verify that the client works correctly with the actual
/// NEAR RPC API. They require network access and should be run separately
/// from unit tests.
///
/// Run with: dart test test/integration_test.dart --tags integration
@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  late NearRpcClient client;

  setUpAll(() {
    client = NearRpcClient.testnet();
  });

  tearDownAll(() {
    client.close();
  });

  group('Integration: NEAR Testnet', () {
    test('status returns valid node information', () async {
      final result = await client.status();

      expect(result.isSuccess, isTrue, reason: 'status() should succeed');

      final status = result.getOrNull()!;
      expect(status.chainId, equals('testnet'));
      expect(status.version.version, isNotEmpty);
      expect(status.syncInfo.latestBlockHeight, greaterThan(0));
      expect(status.protocolVersion, greaterThan(0));

      print('Node version: ${status.version.version}');
      print('Latest block: ${status.syncInfo.latestBlockHeight}');
      print('Protocol version: ${status.protocolVersion}');
    });

    test('block returns valid block data for final finality', () async {
      final result = await client.block(
        BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'block() should succeed');

      final block = result.getOrNull()!;
      expect(block.header.height, greaterThan(0));
      expect(block.header.hash, isNotEmpty);
      expect(block.author, isNotEmpty);

      print('Block height: ${block.header.height}');
      print('Block hash: ${block.header.hash}');
      print('Block author: ${block.author}');
    });

    test('viewAccount returns valid data for existing account', () async {
      // Use the testnet faucet account which always exists
      final result = await client.viewAccount(
        accountId: AccountId('testnet'),
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'viewAccount() should succeed');

      final account = result.getOrNull()!;
      expect(account.amount.yoctoNear, greaterThan(BigInt.zero));
      expect(account.storageUsage, greaterThanOrEqualTo(0));

      print('Account balance: ${account.amount.toNear()} NEAR');
      print('Storage usage: ${account.storageUsage} bytes');
    });

    test('viewAccount returns error for non-existent account', () async {
      final result = await client.viewAccount(
        accountId: AccountId(
          'this-account-definitely-does-not-exist-12345.testnet',
        ),
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(
        result.isFailure,
        isTrue,
        reason: 'Should fail for non-existent account',
      );

      final error = (result as RpcFailure).error;
      expect(error.kind, equals(RpcErrorKind.rpcError));
      print('Error for non-existent account: ${error.message}');
    });

    test('gasPrice returns valid gas price', () async {
      final result = await client.gasPrice();

      expect(result.isSuccess, isTrue, reason: 'gasPrice() should succeed');

      final gasPrice = result.getOrNull()!;
      expect(gasPrice.gasPrice, greaterThan(BigInt.zero));

      print('Gas price: ${gasPrice.gasPrice} yoctoNEAR/gas');
    });

    test('block by height returns valid data', () async {
      // First get the latest block height
      final statusResult = await client.status();
      final latestHeight = statusResult.getOrNull()!.syncInfo.latestBlockHeight;

      // Query a block a few behind to ensure it exists
      final targetHeight = latestHeight - 10;

      final result = await client.block(BlockReference.blockId(targetHeight));

      expect(
        result.isSuccess,
        isTrue,
        reason: 'block() by height should succeed',
      );

      final block = result.getOrNull()!;
      expect(block.header.height, equals(targetHeight));

      print('Queried block at height $targetHeight');
    });
  });
}
