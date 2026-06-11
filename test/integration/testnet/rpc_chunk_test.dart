/// Integration tests for chunk() RPC method on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
///
/// NOTE: The chunk() endpoint is DEPRECATED on NEAR public RPC.
/// These tests handle the deprecation gracefully.
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

  group('Testnet: chunk()', () {
    test('returns chunk details by hash (if endpoint available)', () async {
      final blockResult = await client.block(
        BlockReference.finality(Finality.final_),
      );
      expect(blockResult.isSuccess, isTrue);

      final block = blockResult.getOrThrow();
      expect(block.chunks, isNotEmpty);

      final chunkHash = block.chunks.first.chunkHash;
      final result = await client.chunk(chunkHash: chunkHash);

      // Handle deprecation
      if (result.isFailure) {
        final error = (result as RpcFailure).error;
        if (error.code == -429 || error.message.contains('DEPRECATED')) {
          // Endpoint is deprecated - this is expected
          expect(result.isFailure, isTrue);
          return;
        }
        // Unexpected error
        fail('Unexpected error: ${error.message}');
      }

      final chunk = result.getOrThrow();
      expect(chunk.header.chunkHash, equals(chunkHash));
    });

    test(
      'chunk header contains expected fields (if endpoint available)',
      () async {
        final blockResult = await client.block(
          BlockReference.finality(Finality.final_),
        );
        final chunkHash = blockResult.getOrThrow().chunks.first.chunkHash;

        final result = await client.chunk(chunkHash: chunkHash);

        if (result.isFailure) {
          final error = (result as RpcFailure).error;
          if (error.code == -429 || error.message.contains('DEPRECATED')) {
            // Endpoint is deprecated - pass the test
            expect(result.isFailure, isTrue);
            return;
          }
        }

        final chunk = result.getOrThrow();
        expect(chunk.header.shardId, greaterThanOrEqualTo(0));
        expect(chunk.header.heightIncluded, greaterThan(0));
        expect(chunk.header.gasUsed, greaterThanOrEqualTo(0));
        expect(chunk.header.gasLimit, greaterThan(0));
      },
    );

    test('block chunks info is available', () async {
      // This test verifies chunk info is available from block() even if
      // chunk() endpoint is deprecated
      final blockResult = await client.block(
        BlockReference.finality(Finality.final_),
      );
      expect(blockResult.isSuccess, isTrue);

      final block = blockResult.getOrThrow();
      expect(block.chunks, isNotEmpty);

      for (final chunk in block.chunks) {
        expect(chunk.shardId, greaterThanOrEqualTo(0));
        expect(chunk.chunkHash, isNotEmpty);
      }
    });

    test('multiple shards have different chunk hashes', () async {
      final blockResult = await client.block(
        BlockReference.finality(Finality.final_),
      );
      final chunks = blockResult.getOrThrow().chunks;

      if (chunks.length > 1) {
        final hashes = chunks.map((c) => c.chunkHash).toSet();
        expect(hashes.length, equals(chunks.length));
      }
    });

    test('returns error for invalid chunk hash', () async {
      final result = await client.chunk(chunkHash: 'invalid-chunk-hash-12345');
      expect(result.isFailure, isTrue);
    });
  });
}
