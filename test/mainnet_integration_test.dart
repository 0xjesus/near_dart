/// Integration tests that run against the real NEAR mainnet.
///
/// These tests verify that the client works correctly with mainnet.
/// Run with: dart test test/mainnet_integration_test.dart --tags integration
@Tags(['integration', 'mainnet'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  late NearRpcClient client;

  setUpAll(() {
    client = NearRpcClient.mainnet();
  });

  tearDownAll(() {
    client.close();
  });

  group('Integration: NEAR Mainnet', () {
    test('status returns valid mainnet node information', () async {
      final result = await client.status();

      expect(result.isSuccess, isTrue, reason: 'status() should succeed');

      final status = result.getOrNull()!;
      expect(status.chainId, equals('mainnet'));
      expect(status.version.version, isNotEmpty);
      expect(status.syncInfo.latestBlockHeight, greaterThan(0));

      print('=== MAINNET STATUS ===');
      print('Chain ID: ${status.chainId}');
      print('Node version: ${status.version.version}');
      print('Latest block: ${status.syncInfo.latestBlockHeight}');
      print('Protocol version: ${status.protocolVersion}');
    });

    test('block returns valid mainnet block data', () async {
      final result = await client.block(
        BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'block() should succeed');

      final block = result.getOrNull()!;
      expect(block.header.height, greaterThan(0));

      print('=== MAINNET BLOCK ===');
      print('Block height: ${block.header.height}');
      print('Block hash: ${block.header.hash}');
      print('Block author: ${block.author}');
    });

    test('viewAccount returns valid data for near foundation', () async {
      // Use near.near which is the NEAR Foundation account
      final result = await client.viewAccount(
        accountId: AccountId('near'),
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'viewAccount() should succeed');

      final account = result.getOrNull()!;
      expect(account.amount.yoctoNear, greaterThan(BigInt.zero));

      print('=== MAINNET ACCOUNT: near ===');
      print('Balance: ${account.amount.toNear()} NEAR');
      print('Storage usage: ${account.storageUsage} bytes');
      print('Has contract: ${account.hasContract}');
    });

    test('gasPrice returns valid mainnet gas price', () async {
      final result = await client.gasPrice();

      expect(result.isSuccess, isTrue, reason: 'gasPrice() should succeed');

      final gasPrice = result.getOrNull()!;
      expect(gasPrice.gasPrice, greaterThan(BigInt.zero));

      print('=== MAINNET GAS PRICE ===');
      print('Gas price: ${gasPrice.gasPrice} yoctoNEAR/gas');
    });
  });
}
