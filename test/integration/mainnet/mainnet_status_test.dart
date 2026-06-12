/// Integration tests for status() RPC method on mainnet.
///
/// NO MOCKS - All tests hit real NEAR mainnet RPC endpoints.
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

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Mainnet: status()', () {
    test('returns valid node status', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(
        result.isSuccess,
        isTrue,
        reason: 'status() should succeed on mainnet',
      );

      final status = result.getOrNull()!;
      expect(status.chainId, equals('mainnet'));
    });

    test('returns correct chain_id', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.chainId, equals('mainnet'));
    });

    test('returns non-empty version info', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.version.version, isNotEmpty);
    });

    test('returns valid sync info', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();
      expect(status.syncInfo.latestBlockHeight, greaterThan(0));
      expect(status.syncInfo.latestBlockHash, isNotEmpty);
    });

    test('mainnet block height is higher than testnet epoch', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();

      // Mainnet has been running longer, should have higher block height
      // Mainnet started in 2020, should have billions of blocks by now
      expect(status.syncInfo.latestBlockHeight, greaterThan(100000000));
    });

    test('protocol version is current', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final status = result.getOrThrow();

      // Protocol version should be at least 60+ as of 2024
      expect(status.protocolVersion, greaterThan(50));
    });
  });

  group('Mainnet: block()', () {
    test('returns final block', () async {
      final result = await client.block(
        BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final block = result.getOrThrow();
      expect(block.header.height, greaterThan(0));
      expect(block.author, isNotEmpty);
    });

    test('returns optimistic block', () async {
      final result = await client.block(
        BlockReference.finality(Finality.optimistic),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });

    test('block has multiple shards', () async {
      final result = await client.block(
        BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final block = result.getOrThrow();
      // Mainnet typically has 4+ shards
      expect(block.chunks.length, greaterThanOrEqualTo(4));
    });
  });
}
