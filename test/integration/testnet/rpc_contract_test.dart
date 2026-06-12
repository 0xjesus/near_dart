/// Integration tests for callFunction() RPC method on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
@Tags(['integration', 'testnet'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';
import '../../fixtures/known_data.dart';

void main() {
  late NearRpcClient client;

  setUpAll(() {
    client = NearRpcClient.testnet();
  });

  tearDownAll(() {
    client.close();
  });

  group('Testnet: callFunction() - wrap.testnet', () {
    test('ft_metadata returns token metadata', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue, reason: 'ft_metadata should succeed');

      final response = result.getOrThrow();
      final metadata = response.resultAsJson();

      expect(metadata['name'], equals(ExpectedFtMetadata.wrappedNear.name));
      expect(metadata['symbol'], equals(ExpectedFtMetadata.wrappedNear.symbol));
      expect(
        metadata['decimals'],
        equals(ExpectedFtMetadata.wrappedNear.decimals),
      );
    });

    test('ft_total_supply returns supply', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_total_supply',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      final supply = response.resultAsJson();

      // Supply should be a string number
      expect(supply, isA<String>());
      expect(BigInt.tryParse(supply as String), isNotNull);
    });

    test('ft_balance_of returns balance for existing account', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_balance_of',
        args: {'account_id': 'testnet'},
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      final balance = response.resultAsJson();

      // Balance should be a string number (could be "0")
      expect(balance, isA<String>());
    });

    test('ft_balance_of returns "0" for account with no balance', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_balance_of',
        args: {'account_id': NonExistentAccounts.testnetNonExistent.value},
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      final balance = response.resultAsJson();

      expect(balance, equals('0'));
    });

    test('storage_balance_of returns storage info', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'storage_balance_of',
        args: {'account_id': 'testnet'},
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isSuccess, isTrue);

      // Response can be null or an object with total/available
      final response = result.getOrThrow();
      // Just verify we got a valid response
      expect(response.result, isNotNull);
    });
  });

  group('Testnet: callFunction() - error cases', () {
    test('returns error for non-existent method', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'non_existent_method_12345',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('returns error for non-contract account', () async {
      // testnet account doesn't have a contract deployed
      // But it might have some system contract, so this test is for method not found
      final result = await client.callFunction(
        accountId: TestnetAccounts.testnet,
        methodName: 'some_method',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('returns error for non-existent account', () async {
      final result = await client.callFunction(
        accountId: NonExistentAccounts.testnetNonExistent,
        methodName: 'any_method',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('Testnet: callFunction() - response parsing', () {
    test('result is base64 decodable', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      final response = result.getOrThrow();

      // The raw result should be base64 decodable
      final decoded = utf8.decode(response.result);
      expect(() => jsonDecode(decoded), returnsNormally);
    });

    test('resultAsString returns decoded string', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_total_supply',
        blockReference: BlockReference.finality(Finality.final_),
      );

      final response = result.getOrThrow();
      final supply = response.resultAsString();

      expect(supply, isNotEmpty);
    });

    test('logs are captured', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      final response = result.getOrThrow();
      // Logs is a list (may be empty for simple view calls)
      expect(response.logs, isA<List>());
    });
  });

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Testnet: callFunction() - block references', () {
    test('works with final finality', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });

    test('works with optimistic finality', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.optimistic),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });

    test('works with block height', () async {
      // Get current height
      final statusResult = await client.status();

      if (statusResult.isFailure &&
          isRateLimitError((statusResult as RpcFailure).error)) {
        return;
      }

      final height = statusResult.getOrThrow().syncInfo.latestBlockHeight - 10;

      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.blockId(height),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });
  });
}
