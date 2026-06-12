/// Integration tests for validators() RPC method on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
///
/// NOTE: The validators() endpoint may be rate-limited or deprecated on NEAR public RPC.
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

  group('Testnet: validators()', () {
    test('returns validator information (if endpoint available)', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        // Endpoint is deprecated - this is expected
        expect(result.isFailure, isTrue);
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'validators() should succeed');

      final validators = result.getOrThrow();
      expect(validators.currentValidators, isNotEmpty);
    });

    test(
      'current validators have account IDs (if endpoint available)',
      () async {
        final result = await client.validators();

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final validators = result.getOrThrow();

        for (final validator in validators.currentValidators) {
          expect(validator.accountId, isNotEmpty);
        }
      },
    );

    test(
      'current validators have stake amounts (if endpoint available)',
      () async {
        final result = await client.validators();

        if (result.isFailure &&
            isRateLimitError((result as RpcFailure).error)) {
          return;
        }

        final validators = result.getOrThrow();

        for (final validator in validators.currentValidators) {
          // Stake is a NearToken
          expect(validator.stake.yoctoNear, greaterThanOrEqualTo(BigInt.zero));
        }
      },
    );

    test('validators have positive stake (if endpoint available)', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      for (final validator in validators.currentValidators) {
        expect(validator.stake.yoctoNear, greaterThan(BigInt.zero));
      }
    });

    test('returns epoch info (if endpoint available)', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      expect(validators.epochHeight, greaterThan(0));
      expect(validators.epochStartHeight, greaterThan(0));
    });

    test('validators have public keys (if endpoint available)', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      for (final validator in validators.currentValidators) {
        expect(validator.publicKey, isNotEmpty);
        expect(
          validator.publicKey.startsWith('ed25519:') ||
              validator.publicKey.startsWith('secp256k1:'),
          isTrue,
        );
      }
    });

    test('next validators list exists (if endpoint available)', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      // Next validators list should exist (may be same as current)
      expect(validators.nextValidators, isA<List>());
    });

    test('returns current proposals (if endpoint available)', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      // Proposals list should exist (may be empty)
      expect(validators.currentProposals, isA<List>());
    });
  });
}
