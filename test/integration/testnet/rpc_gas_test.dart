/// Integration tests for gasPrice() RPC method on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
///
/// NOTE: The gasPrice() endpoint may be rate-limited or deprecated on NEAR public RPC.
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

  group('Testnet: gasPrice()', () {
    test('returns current gas price (if endpoint available)', () async {
      final result = await client.gasPrice();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        // Endpoint is deprecated - this is expected
        expect(result.isFailure, isTrue);
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'gasPrice() should succeed');

      final gasPrice = result.getOrThrow();
      expect(gasPrice.gasPrice, greaterThan(BigInt.zero));
    });

    test('gas price is reasonable value (if endpoint available)', () async {
      final result = await client.gasPrice();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final gasPrice = result.getOrThrow();

      // NEAR's base gas price is around 100M yoctoNEAR per gas unit
      // It should be at least 1M and less than 1T
      final price = gasPrice.gasPrice;
      expect(price, greaterThan(BigInt.from(1000000))); // > 1M
      expect(
        price,
        lessThan(BigInt.parse('1000000000000000')),
      ); // < 1 quadrillion
    });

    test(
      'gas price can be used for fee estimation (if endpoint available)',
      () async {
        final result = await client.gasPrice();

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final gasPrice = result.getOrThrow();

        // Estimate fee for 30 TGas (typical function call)
        final gas = BigInt.from(30) * BigInt.from(10).pow(12);
        final estimatedFee = gasPrice.gasPrice * gas;

        // Fee should be reasonable (less than 1 NEAR for 30 TGas)
        final oneNear = BigInt.parse('1000000000000000000000000');
        expect(estimatedFee, lessThan(oneNear));
      },
    );
  });

  group('Testnet: gasPrice() with block reference', () {
    test('can query with specific block ID (if endpoint available)', () async {
      // Get a recent block hash
      final blockResult = await client.block(
        BlockReference.finality(Finality.final_),
      );

      if (blockResult.isFailure &&
          isRateLimitError((blockResult as RpcFailure).error)) {
        return;
      }

      final blockHash = blockResult.getOrThrow().header.hash;
      final result = await client.gasPrice(blockHash);

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().gasPrice, greaterThan(BigInt.zero));
    });

    test(
      'null block ID returns current price (if endpoint available)',
      () async {
        final result = await client.gasPrice(null);

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        expect(result.isSuccess, isTrue);
        expect(result.getOrThrow().gasPrice, greaterThan(BigInt.zero));
      },
    );
  });
}
