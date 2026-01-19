/// Tests for contract interaction methods.
@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:near_flutter/near_flutter.dart';

void main() {
  late NearRpcClient testnetClient;
  late NearRpcClient mainnetClient;

  setUpAll(() {
    testnetClient = NearRpcClient.testnet();
    mainnetClient = NearRpcClient.mainnet();
  });

  tearDownAll(() {
    testnetClient.close();
    mainnetClient.close();
  });

  group('Contract Interaction: Testnet', () {
    test('callFunction calls view method on contract', () async {
      // Call ft_metadata on wrap.testnet (wrapped NEAR token)
      final result = await testnetClient.callFunction(
        accountId: AccountId('wrap.testnet'),
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'callFunction should succeed');

      final response = result.getOrNull()!;
      final metadata = response.resultAsJson() as Map<String, dynamic>;

      expect(metadata['symbol'], equals('wNEAR'));
      expect(metadata['decimals'], equals(24));

      print('=== TESTNET: wrap.testnet ft_metadata ===');
      print('Symbol: ${metadata['symbol']}');
      print('Name: ${metadata['name']}');
      print('Decimals: ${metadata['decimals']}');
    });

    test('callFunction with args returns balance', () async {
      // Check balance of a known account
      final result = await testnetClient.callFunction(
        accountId: AccountId('wrap.testnet'),
        methodName: 'ft_balance_of',
        args: {'account_id': 'testnet'},
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      final balance = result.getOrNull()!.resultAsJson();
      print('=== TESTNET: wrap.testnet ft_balance_of(testnet) ===');
      print('Balance: $balance');
    });
  });

  group('Contract Interaction: Mainnet', () {
    test('callFunction calls view method on mainnet contract', () async {
      // Call ft_metadata on wrap.near (wrapped NEAR on mainnet)
      final result = await mainnetClient.callFunction(
        accountId: AccountId('wrap.near'),
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'callFunction should succeed');

      final response = result.getOrNull()!;
      final metadata = response.resultAsJson() as Map<String, dynamic>;

      expect(metadata['symbol'], equals('wNEAR'));

      print('=== MAINNET: wrap.near ft_metadata ===');
      print('Symbol: ${metadata['symbol']}');
      print('Name: ${metadata['name']}');
    });

    test('callFunction reads USDT contract', () async {
      // Call ft_metadata on USDT contract
      final result = await mainnetClient.callFunction(
        accountId: AccountId('usdt.tether-token.near'),
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      final metadata = result.getOrNull()!.resultAsJson() as Map<String, dynamic>;
      expect(metadata['symbol'], equals('USDt'));

      print('=== MAINNET: USDT ft_metadata ===');
      print('Symbol: ${metadata['symbol']}');
      print('Decimals: ${metadata['decimals']}');
    });
  });

  group('Validators', () {
    test('validators returns testnet validator info', () async {
      final result = await testnetClient.validators();

      expect(result.isSuccess, isTrue);

      final validators = result.getOrNull()!;
      expect(validators.currentValidators, isNotEmpty);
      expect(validators.epochHeight, greaterThan(0));

      print('=== TESTNET VALIDATORS ===');
      print('Epoch height: ${validators.epochHeight}');
      print('Current validators: ${validators.currentValidators.length}');
      print('Next validators: ${validators.nextValidators.length}');

      if (validators.currentValidators.isNotEmpty) {
        final top = validators.currentValidators.first;
        print('Top validator: ${top.accountId}');
        print('Stake: ${top.stake.toNear()} NEAR');
      }
    });

    test('validators returns mainnet validator info', () async {
      final result = await mainnetClient.validators();

      expect(result.isSuccess, isTrue);

      final validators = result.getOrNull()!;
      expect(validators.currentValidators, isNotEmpty);

      print('=== MAINNET VALIDATORS ===');
      print('Epoch height: ${validators.epochHeight}');
      print('Current validators: ${validators.currentValidators.length}');
    });
  });

  group('Access Keys', () {
    test('viewAccessKeyList returns account keys', () async {
      // Query a known account with access keys
      final result = await testnetClient.viewAccessKeyList(
        accountId: AccountId('testnet'),
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      final keys = result.getOrNull()!;
      expect(keys.keys, isNotEmpty);

      print('=== TESTNET: testnet access keys ===');
      print('Number of keys: ${keys.keys.length}');
    });
  });
}
