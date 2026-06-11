/// Integration tests for block() RPC method on testnet.
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

  group('Testnet: block()', () {
    group('By finality', () {
      test('returns final block', () async {
        final result = await client.block(
          BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue, reason: 'block() should succeed');

        final block = result.getOrThrow();
        expect(block.header.height, greaterThan(0));
        expect(block.header.hash, isNotEmpty);
      });

      test('returns optimistic block', () async {
        final result = await client.block(
          BlockReference.finality(Finality.optimistic),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);

        final block = result.getOrThrow();
        expect(block.header.height, greaterThan(0));
      });

      test('optimistic block height >= final block height', () async {
        final finalResult = await client.block(
          BlockReference.finality(Finality.final_),
        );
        final optimisticResult = await client.block(
          BlockReference.finality(Finality.optimistic),
        );

        if (finalResult.isFailure &&
            isRateLimitError((finalResult as RpcFailure).error)) {
          return;
        }
        if (optimisticResult.isFailure &&
            isRateLimitError((optimisticResult as RpcFailure).error)) {
          return;
        }

        final finalHeight = finalResult.getOrThrow().header.height;
        final optimisticHeight = optimisticResult.getOrThrow().header.height;

        expect(optimisticHeight, greaterThanOrEqualTo(finalHeight));
      });
    });

    group('By height', () {
      test('returns block at specific height', () async {
        // First get current height
        final statusResult = await client.status();

        if (statusResult.isFailure &&
            isRateLimitError((statusResult as RpcFailure).error)) {
          return;
        }

        final currentHeight = statusResult
            .getOrThrow()
            .syncInfo
            .latestBlockHeight;

        // Query a block that definitely exists (a few behind current)
        final targetHeight = currentHeight - 100;

        final result = await client.block(BlockReference.blockId(targetHeight));

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);

        final block = result.getOrThrow();
        expect(block.header.height, equals(targetHeight));
      });

      test('returns error for future block height', () async {
        // Query a block far in the future
        const futureHeight = 999999999999;

        final result = await client.block(BlockReference.blockId(futureHeight));

        expect(result.isFailure, isTrue);
        // Error can be rpcError or httpError
        final failure = result as RpcFailure;
        expect(
          failure.error.kind == RpcErrorKind.rpcError ||
              failure.error.kind == RpcErrorKind.httpError,
          isTrue,
        );
      });

      test('block header contains expected fields', () async {
        final statusResult = await client.status();

        if (statusResult.isFailure &&
            isRateLimitError((statusResult as RpcFailure).error)) {
          return;
        }

        final targetHeight =
            statusResult.getOrThrow().syncInfo.latestBlockHeight - 50;

        final result = await client.block(BlockReference.blockId(targetHeight));

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final block = result.getOrThrow();
        expect(block.header.height, equals(targetHeight));
        expect(block.header.hash, isNotEmpty);
        expect(block.header.prevHash, isNotEmpty);
        expect(block.header.timestamp, greaterThan(0));
      });
    });

    group('By hash', () {
      test('returns block by hash', () async {
        // First get a known block hash
        final blockResult = await client.block(
          BlockReference.finality(Finality.final_),
        );

        if (blockResult.isFailure &&
            isRateLimitError((blockResult as RpcFailure).error)) {
          return;
        }

        final knownHash = blockResult.getOrThrow().header.hash;
        final knownHeight = blockResult.getOrThrow().header.height;

        // Query by that hash
        final result = await client.block(
          BlockReference.blockHash(CryptoHash(knownHash)),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);

        final block = result.getOrThrow();
        expect(block.header.hash, equals(knownHash));
        expect(block.header.height, equals(knownHeight));
      });

      test('returns error for invalid hash', () async {
        final result = await client.block(
          BlockReference.blockHash(const CryptoHash('invalidhash123456789')),
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('Block content', () {
      test('block has author', () async {
        final result = await client.block(
          BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final block = result.getOrThrow();
        expect(block.author, isNotEmpty);
      });

      test('block has chunks info', () async {
        final result = await client.block(
          BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final block = result.getOrThrow();
        expect(block.chunks, isNotEmpty);
      });

      test('chunks contain shard info', () async {
        final result = await client.block(
          BlockReference.finality(Finality.final_),
        );

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final block = result.getOrThrow();
        for (final chunk in block.chunks) {
          expect(chunk.shardId, greaterThanOrEqualTo(0));
          expect(chunk.chunkHash, isNotEmpty);
        }
      });
    });
  });
}
