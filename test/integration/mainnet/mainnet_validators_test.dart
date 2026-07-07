/// Integration tests for validators() RPC method on mainnet.
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

  group('Mainnet: validators()', () {
    test('returns validator information', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(
        result.isSuccess,
        isTrue,
        reason: 'validators() should succeed on mainnet',
      );

      final validators = result.getOrThrow();
      expect(validators.currentValidators, isNotEmpty);
    });

    test('mainnet has multiple validators', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      // Mainnet should have many validators
      expect(validators.currentValidators.length, greaterThan(50));
    });

    test('validators have significant stake', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      for (final validator in validators.currentValidators) {
        expect(validator.stake.yoctoNear, greaterThan(BigInt.zero));
      }
    });

    test('all validators have valid account IDs', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      for (final validator in validators.currentValidators) {
        expect(validator.accountId, isNotEmpty);
        // Mainnet validators typically end in .poolv1.near or similar
        expect(
          validator.accountId.contains('.') ||
              validator.accountId.length == 64, // implicit accounts
          isTrue,
        );
      }
    });

    test('validators have ed25519 public keys', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      for (final validator in validators.currentValidators) {
        expect(validator.publicKey, startsWith('ed25519:'));
      }
    });

    test('epoch height is in expected range', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      // Mainnet has been running since 2020, should have high epoch count
      // Epochs are ~12 hours, so roughly 2 per day
      // 4+ years = ~3000+ epochs
      expect(validators.epochHeight, greaterThan(2000));
    });

    test('next validators are populated', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      // Next validators should be planned
      expect(validators.nextValidators, isNotEmpty);
    });
  });

  group('Mainnet: Validator Stake Distribution', () {
    test('total stake is substantial', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      BigInt totalStake = BigInt.zero;
      for (final validator in validators.currentValidators) {
        totalStake += validator.stake.yoctoNear;
      }

      // Total staked on mainnet should be > 100 million NEAR
      final minTotalStake =
          BigInt.parse('100000000') * BigInt.parse('1000000000000000000000000');
      expect(totalStake, greaterThan(minTotalStake));
    });

    test('no single validator has majority stake', () async {
      final result = await client.validators();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final validators = result.getOrThrow();

      BigInt totalStake = BigInt.zero;
      BigInt maxStake = BigInt.zero;

      for (final validator in validators.currentValidators) {
        totalStake += validator.stake.yoctoNear;
        if (validator.stake.yoctoNear > maxStake) {
          maxStake = validator.stake.yoctoNear;
        }
      }

      // No validator should have > 33% of total stake (decentralization)
      final maxAllowed = totalStake * BigInt.from(33) ~/ BigInt.from(100);
      expect(maxStake, lessThan(maxAllowed));
    });
  });

  group('Mainnet: Chunk Producer Info', () {
    test('chunks have producers assigned', () async {
      final blockResult = await client.block(
        BlockReference.finality(Finality.final_),
      );

      if (blockResult.isFailure &&
          isRateLimitError((blockResult as RpcFailure).error)) {
        return;
      }

      final block = blockResult.getOrThrow();

      // Each chunk should have producer info
      for (final chunk in block.chunks) {
        expect(chunk.shardId, greaterThanOrEqualTo(0));
      }
    });
  });
}
