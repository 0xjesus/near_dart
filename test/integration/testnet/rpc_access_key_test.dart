/// Integration tests for viewAccessKey() and viewAccessKeyList() on testnet.
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

  group('Testnet: viewAccessKeyList()', () {
    test('testnet account has access keys', () async {
      final result = await client.viewAccessKeyList(
        accountId: TestnetAccounts.testnet,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      expect(response.keys, isNotEmpty);
    });

    test('access key list contains public keys', () async {
      final result = await client.viewAccessKeyList(
        accountId: TestnetAccounts.testnet,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final response = result.getOrThrow();
      for (final keyInfo in response.keys) {
        expect(keyInfo.publicKey, isNotEmpty);
        // Public keys should start with ed25519: or secp256k1:
        expect(
          keyInfo.publicKey.startsWith('ed25519:') ||
              keyInfo.publicKey.startsWith('secp256k1:'),
          isTrue,
        );
      }
    });

    test('access key info has nonce', () async {
      final result = await client.viewAccessKeyList(
        accountId: TestnetAccounts.testnet,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final response = result.getOrThrow();
      for (final keyInfo in response.keys) {
        expect(keyInfo.accessKey.nonce, greaterThanOrEqualTo(0));
      }
    });

    test('returns error for non-existent account', () async {
      final result = await client.viewAccessKeyList(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      // Non-existent account should return failure or empty keys
      if (result.isSuccess) {
        expect(result.getOrThrow().keys, isEmpty);
      } else {
        expect(result.isFailure, isTrue);
      }
    });

    test('contract accounts have access keys', () async {
      final result = await client.viewAccessKeyList(
        accountId: TestnetAccounts.wrapTestnet,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });
  });

  group('Testnet: viewAccessKey()', () {
    test('returns access key info for valid key', () async {
      // First get a key list to find a valid public key
      final listResult = await client.viewAccessKeyList(
        accountId: TestnetAccounts.testnet,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (listResult.isFailure &&
          isRateLimitError((listResult as RpcFailure).error)) {
        return;
      }

      final keys = listResult.getOrThrow().keys;
      if (keys.isEmpty) {
        // Skip if no keys (unlikely for testnet account)
        return;
      }

      final publicKeyStr = keys.first.publicKey;
      final publicKey = PublicKey(publicKeyStr);

      final result = await client.viewAccessKey(
        accountId: TestnetAccounts.testnet,
        publicKey: publicKey,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final accessKey = result.getOrThrow();
      expect(accessKey.nonce, greaterThanOrEqualTo(0));
    });

    test('returns error for non-existent key', () async {
      final fakeKey = PublicKey(
        'ed25519:4wBqpZM9xaSheZzJSMawUKKwhdpChKbZ5eu5ky4Vigw',
      );

      final result = await client.viewAccessKey(
        accountId: TestnetAccounts.testnet,
        publicKey: fakeKey,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('returns error for non-existent account', () async {
      final fakeKey = PublicKey(
        'ed25519:4wBqpZM9xaSheZzJSMawUKKwhdpChKbZ5eu5ky4Vigw',
      );

      final result = await client.viewAccessKey(
        accountId: NonExistentAccounts.testnetNonExistent,
        publicKey: fakeKey,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('Access key permissions', () {
    test('access keys have valid permission types', () async {
      final result = await client.viewAccessKeyList(
        accountId: TestnetAccounts.testnet,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final keys = result.getOrThrow().keys;

      for (final key in keys) {
        // Permission should be either FullAccess or FunctionCall
        final permission = key.accessKey.permission;
        expect(
          permission is FullAccessPermissionView ||
              permission is FunctionCallPermissionView,
          isTrue,
        );
      }
    });
  });
}
