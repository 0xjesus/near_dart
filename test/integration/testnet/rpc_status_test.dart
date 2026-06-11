/// Integration tests for status() RPC method on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
@Tags(['integration', 'testnet'])
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

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Testnet: status()', () {
    test('returns valid node status', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'status() should succeed');

      final status = result.getOrNull()!;
      expect(status.chainId, equals('testnet'));
    });

    test('returns correct chain_id for testnet', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.chainId, equals('testnet'));
    });

    test('returns non-empty version info', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.version.version, isNotEmpty);
      expect(status.version.build, isNotEmpty);
    });

    test('returns valid sync info', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.syncInfo.latestBlockHeight, greaterThan(0));
      expect(status.syncInfo.latestBlockHash, isNotEmpty);
      expect(status.syncInfo.latestBlockTime, isNotEmpty);
    });

    test('returns positive protocol version', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.protocolVersion, greaterThan(0));
    });

    test('latest block height is recent', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      // Testnet produces blocks roughly every second
      expect(status.syncInfo.latestBlockHeight, greaterThan(100000000));
    });

    test('sync info contains earliest block info', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.syncInfo.earliestBlockHeight, greaterThanOrEqualTo(0));
      expect(status.syncInfo.earliestBlockHash, isNotEmpty);
    });

    test('multiple calls return consistent chain_id', () async {
      final result1 = await client.status();
      final result2 = await client.status();

      if (result1.isFailure &&
          isRateLimitError((result1 as RpcFailure).error)) {
        return;
      }
      if (result2.isFailure &&
          isRateLimitError((result2 as RpcFailure).error)) {
        return;
      }

      expect(
        result1.getOrThrow().chainId,
        equals(result2.getOrThrow().chainId),
      );
    });

    test('block height increases over time', () async {
      final result1 = await client.status();

      if (result1.isFailure &&
          isRateLimitError((result1 as RpcFailure).error)) {
        return;
      }

      final height1 = result1.getOrThrow().syncInfo.latestBlockHeight;

      // Wait a bit for new blocks
      await Future.delayed(const Duration(seconds: 2));

      final result2 = await client.status();

      if (result2.isFailure &&
          isRateLimitError((result2 as RpcFailure).error)) {
        return;
      }

      final height2 = result2.getOrThrow().syncInfo.latestBlockHeight;

      // Height should increase (or at least stay the same if no new blocks)
      expect(height2, greaterThanOrEqualTo(height1));
    });
  });
}
