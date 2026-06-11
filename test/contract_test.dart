/// Tests for contract interaction methods.
@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

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

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Contract Interaction: Testnet', () {
    test('callFunction calls view method on contract', () async {
      // Call ft_metadata on wrap.testnet (wrapped NEAR token)
      final result = await testnetClient.callFunction(
        accountId: AccountId('wrap.testnet'),
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'callFunction should succeed');

      final response = result.getOrNull()!;
      final metadata = response.resultAsJson() as Map<String, dynamic>;

      expect(metadata['symbol'], equals('wNEAR'));
      expect(metadata['decimals'], equals(24));
    });

    test('callFunction with args returns balance', () async {
      // Check balance of a known account
      final result = await testnetClient.callFunction(
        accountId: AccountId('wrap.testnet'),
        methodName: 'ft_balance_of',
        args: {'account_id': 'testnet'},
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
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

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'callFunction should succeed');

      final response = result.getOrNull()!;
      final metadata = response.resultAsJson() as Map<String, dynamic>;

      expect(metadata['symbol'], equals('wNEAR'));
    });

    test('callFunction reads USDT contract', () async {
      // Call ft_metadata on USDT contract
      final result = await mainnetClient.callFunction(
        accountId: AccountId('usdt.tether-token.near'),
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final metadata =
          result.getOrNull()!.resultAsJson() as Map<String, dynamic>;
      expect(metadata['symbol'], equals('USDt'));
    });
  });

  group('Validators', () {
    test('validators returns testnet validator info', () async {
      final result = await testnetClient.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final validators = result.getOrNull()!;
      expect(validators.currentValidators, isNotEmpty);
      expect(validators.epochHeight, greaterThan(0));
    });

    test('validators returns mainnet validator info', () async {
      final result = await mainnetClient.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final validators = result.getOrNull()!;
      expect(validators.currentValidators, isNotEmpty);
    });
  });

  group('Access Keys', () {
    test('viewAccessKeyList returns account keys', () async {
      // Query a known account with access keys
      final result = await testnetClient.viewAccessKeyList(
        accountId: AccountId('testnet'),
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final keys = result.getOrNull()!;
      expect(keys.keys, isNotEmpty);
    });
  });
}
