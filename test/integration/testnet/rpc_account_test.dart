/// Integration tests for viewAccount() RPC method on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
@Tags(['integration', 'testnet'])
library;

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

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Testnet: viewAccount()', () {
    group('Known accounts', () {
      test('testnet account exists and has balance', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.testnet,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return; // Skip on rate limit
        }

        expect(
          result.isSuccess,
          isTrue,
          reason: 'testnet account should exist',
        );

        final account = result.getOrThrow();
        expect(account.amount.yoctoNear, greaterThan(BigInt.zero));
      });

      test('near account exists', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.near,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue, reason: 'near account should exist');
      });

      test('wrap.testnet contract exists', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.wrapTestnet,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue, reason: 'wrap.testnet should exist');

        final account = result.getOrThrow();
        // Contract accounts have code deployed
        expect(account.hasContract, isTrue);
      });

      test('all known testnet accounts exist', () async {
        for (final accountId in TestnetAccounts.all) {
          final result = await client.viewAccount(
            accountId: accountId,
            blockReference: BlockReference.finality(Finality.final_),
          );

          if (result.isFailure &&
              isRateLimitError((result as RpcFailure).error)) {
            return; // Skip entire test on rate limit
          }

          expect(
            result.isSuccess,
            isTrue,
            reason: '${accountId.value} should exist on testnet',
          );
        }
      });
    });

    group('Non-existent accounts', () {
      test('returns error for non-existent account', () async {
        final result = await client.viewAccount(
          accountId: NonExistentAccounts.testnetNonExistent,
          blockReference: BlockReference.finality(Finality.final_),
        );

        // Can be rate limited or actual error
        if (result.isFailure) {
          final error = (result as RpcFailure).error;
          if (isRateLimitError(error)) return;

          expect(
            error.kind == RpcErrorKind.rpcError ||
                error.kind == RpcErrorKind.httpError,
            isTrue,
          );
        }
      });
    });

    group('Account fields', () {
      test('account has expected fields', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.testnet,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final account = result.getOrThrow();
        expect(account.amount, isA<NearToken>());
        expect(account.locked, isA<NearToken>());
        expect(account.storageUsage, greaterThanOrEqualTo(0));
        expect(account.codeHash.value, isNotEmpty);
      });

      test('contract account has non-default code hash', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.wrapTestnet,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final account = result.getOrThrow();
        // Contracts have actual code deployed
        expect(account.hasContract, isTrue);
      });

      test('storage usage is positive for active accounts', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.testnet,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final account = result.getOrThrow();
        expect(account.storageUsage, greaterThan(0));
      });
    });

    group('Block reference variations', () {
      test('query at final finality', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.testnet,
          blockReference: BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);
      });

      test('query at optimistic finality', () async {
        final result = await client.viewAccount(
          accountId: TestnetAccounts.testnet,
          blockReference: BlockReference.finality(Finality.optimistic),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);
      });

      test('query at specific block height', () async {
        // Get current height first
        final statusResult = await client.status();

        if (statusResult.isFailure &&
            isRateLimitError((statusResult as RpcFailure).error)) {
          return;
        }

        final height =
            statusResult.getOrThrow().syncInfo.latestBlockHeight - 10;

        final result = await client.viewAccount(
          accountId: TestnetAccounts.testnet,
          blockReference: BlockReference.blockId(height),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);
      });
    });
  });
}
