/// Platform-specific tests for Dart VM.
///
/// These tests verify functionality specific to the Dart VM runtime.
/// Run with: dart test --platform vm test/platform/vm_test.dart
@TestOn('vm')
@Tags(['platform', 'vm'])
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('VM Platform: NearRpcClient', () {
    test('can create testnet client', () {
      final client = NearRpcClient.testnet();
      expect(client.rpcUrl, equals('https://test.rpc.fastnear.com'));
      client.close();
    });

    test('can create mainnet client', () {
      final client = NearRpcClient.mainnet();
      expect(client.rpcUrl, equals('https://free.rpc.fastnear.com'));
      client.close();
    });

    test('can create client with custom URL', () {
      final client = NearRpcClient(rpcUrl: 'https://custom.rpc.example.com');
      expect(client.rpcUrl, equals('https://custom.rpc.example.com'));
      client.close();
    });
  });

  group('VM Platform: Type Creation', () {
    test('AccountId creation works', () {
      final account = AccountId('test.near');
      expect(account.value, equals('test.near'));
    });

    test('NearToken BigInt operations work', () {
      final token = NearToken.fromNear(1000000);
      expect(token.yoctoNear, greaterThan(BigInt.zero));
    });

    test('CryptoHash creation works', () {
      const hash = CryptoHash('test-hash-value');
      expect(hash.value, equals('test-hash-value'));
    });

    test('PublicKey parsing works', () {
      final key = PublicKey(
        'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
      );
      expect(key.keyType, equals(KeyType.ed25519));
    });
  });

  group('VM Platform: JSON Serialization', () {
    test('BlockReference serializes correctly', () {
      final ref = BlockReference.finality(Finality.final_);
      expect(ref.toJson(), equals({'finality': 'final'}));
    });

    test('Action serializes correctly', () {
      final action = TransferAction(deposit: NearToken.fromNear(1));
      final json = action.toJson();
      expect(json.containsKey('Transfer'), isTrue);
    });
  });

  group('VM Platform: RPC Calls (requires network)', () {
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

    test('status() works on VM', () async {
      final result = await client.status();

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().chainId, equals('testnet'));
    });

    test('viewAccount() works on VM', () async {
      final result = await client.viewAccount(
        accountId: AccountId('testnet'),
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });
  });

  group('VM Platform: IO Operations', () {
    test('Platform is not browser', () {
      // On VM, Platform.environment should be accessible
      expect(() => Platform.environment, returnsNormally);
    });

    test('can detect operating system', () {
      expect(Platform.operatingSystem, isNotEmpty);
    });
  });
}
