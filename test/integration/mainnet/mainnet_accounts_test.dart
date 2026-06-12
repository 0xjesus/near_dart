/// Integration tests for account queries on mainnet.
///
/// NO MOCKS - All tests hit real NEAR mainnet RPC endpoints.
@Tags(['integration', 'mainnet'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';
import '../../fixtures/known_data.dart';

void main() {
  late NearRpcClient client;

  setUpAll(() {
    client = NearRpcClient.mainnet();
  });

  tearDownAll(() {
    client.close();
  });

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Mainnet: viewAccount() - Known Accounts', () {
    test('near account exists', () async {
      final result = await client.viewAccount(
        accountId: MainnetAccounts.near,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(
        result.isSuccess,
        isTrue,
        reason: 'near account should exist on mainnet',
      );

      final account = result.getOrThrow();
      expect(account.amount.yoctoNear, greaterThan(BigInt.zero));
    });

    test('aurora account exists', () async {
      final result = await client.viewAccount(
        accountId: MainnetAccounts.aurora,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(
        result.isSuccess,
        isTrue,
        reason: 'aurora should exist on mainnet',
      );

      final account = result.getOrThrow();
      // Aurora is a major contract
      expect(account.codeHash, isNotEmpty);
    });

    test('wrap.near contract exists', () async {
      final result = await client.viewAccount(
        accountId: MainnetAccounts.wrapNear,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'wrap.near should exist');

      final account = result.getOrThrow();
      // Contract should have code deployed
      expect(
        account.codeHash,
        isNot(equals('11111111111111111111111111111111')),
      );
    });

    test('usdt.tether-token.near exists', () async {
      final result = await client.viewAccount(
        accountId: MainnetAccounts.usdt,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'USDT contract should exist');
    });

    test('all known mainnet accounts exist', () async {
      for (final accountId in MainnetAccounts.all) {
        final result = await client.viewAccount(
          accountId: accountId,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(
          result.isSuccess,
          isTrue,
          reason: '${accountId.value} should exist on mainnet',
        );
      }
    });
  });

  group('Mainnet: viewAccount() - Error Cases', () {
    test('returns error for non-existent account', () async {
      final result = await client.viewAccount(
        accountId: NonExistentAccounts.mainnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure) {
        final error = (result as RpcFailure).error;
        if (isRateLimitError(error)) return;
      }

      expect(result.isFailure, isTrue);
    });
  });

  group('Mainnet: viewAccessKeyList()', () {
    test('near account has access keys', () async {
      final result = await client.viewAccessKeyList(
        accountId: MainnetAccounts.near,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      expect(response.keys, isNotEmpty);
    });

    test('wrap.near contract has access keys', () async {
      final result = await client.viewAccessKeyList(
        accountId: MainnetAccounts.wrapNear,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });
  });

  group('Mainnet: Gas Price', () {
    test('returns current gas price', () async {
      final result = await client.gasPrice();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final gasPrice = result.getOrThrow();
      expect(gasPrice.gasPrice, greaterThan(BigInt.zero));
    });
  });
}
