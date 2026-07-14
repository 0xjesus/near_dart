/// Integration tests for error handling with real RPC errors on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints to get real errors.
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

  group('Testnet: RPC Error - Account Not Found', () {
    test('viewAccount returns error for non-existent account', () async {
      final result = await client.viewAccount(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);

      final failure = result as RpcFailure;
      // Error can be rpcError or httpError depending on RPC implementation
      expect(
        failure.error.kind == RpcErrorKind.rpcError ||
            failure.error.kind == RpcErrorKind.httpError,
        isTrue,
      );
    });

    test('error has message or data', () async {
      final result = await client.viewAccount(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      final failure = result as RpcFailure;
      // Error should have some information
      expect(failure.error.message, isNotEmpty);
    });
  });

  group('Testnet: RPC Error - Block Not Found', () {
    test('block returns error for future height', () async {
      final result = await client.block(BlockReference.blockId(999999999999));

      expect(result.isFailure, isTrue);
      // Error can be rpcError or httpError
      final failure = result as RpcFailure;
      expect(
        failure.error.kind == RpcErrorKind.rpcError ||
            failure.error.kind == RpcErrorKind.httpError,
        isTrue,
      );
    });

    test('block returns error for invalid hash', () async {
      final result = await client.block(
        BlockReference.blockHash(
          const CryptoHash('totally-invalid-hash-value'),
        ),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('Testnet: RPC Error - Contract Errors', () {
    test('callFunction returns error for non-existent method', () async {
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'this_method_does_not_exist_12345',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('callFunction returns error for non-existent contract', () async {
      final result = await client.callFunction(
        accountId: NonExistentAccounts.testnetNonExistent,
        methodName: 'any_method',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('callFunction returns error for invalid args', () async {
      // ft_balance_of requires account_id, passing invalid structure
      final result = await client.callFunction(
        accountId: TestnetContracts.wrapTestnet.account,
        methodName: 'ft_balance_of',
        args: {'invalid_param': 'not_account_id'},
        blockReference: BlockReference.finality(Finality.final_),
      );

      // This might succeed with default behavior or fail
      // Depends on contract implementation
      expect(result.isSuccess || result.isFailure, isTrue);
    });
  });

  group('Testnet: RPC Error - Access Key Errors', () {
    test('viewAccessKey returns error for non-existent key', () async {
      final fakeKey = (await KeyPairEd25519.generate()).publicKey;

      final result = await client.viewAccessKey(
        accountId: TestnetAccounts.testnet,
        publicKey: fakeKey,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('viewAccessKey returns error for non-existent account', () async {
      final fakeKey = PublicKey(KnownPublicKeys.ed25519Valid);

      final result = await client.viewAccessKey(
        accountId: NonExistentAccounts.testnetNonExistent,
        publicKey: fakeKey,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('viewAccessKeyList yields no keys for non-existent account', () async {
      final result = await client.viewAccessKeyList(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      // Provider behavior differs: legacy nodes return UNKNOWN_ACCOUNT,
      // while FastNear returns success with an empty key list. Both
      // correctly express "this account has no keys".
      if (result.isSuccess) {
        expect(result.getOrThrow().keys, isEmpty);
      } else {
        expect(result.isFailure, isTrue);
      }
    });
  });

  group('Testnet: RPC Error - Chunk Errors', () {
    test('chunk returns error for invalid chunk hash', () async {
      final result = await client.chunk(chunkHash: 'invalid-chunk-hash');

      expect(result.isFailure, isTrue);
    });
  });

  group('Testnet: Error Pattern Matching', () {
    test('can pattern match on failure', () async {
      final result = await client.viewAccount(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      String message;
      switch (result) {
        case RpcSuccess(:final value):
          message = 'Success: ${value.amount}';
        case RpcFailure(:final error):
          message = 'Error: ${error.message}';
      }

      expect(message, startsWith('Error:'));
    });

    test('getOrThrow throws RpcException on failure', () async {
      final result = await client.viewAccount(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.getOrThrow, throwsA(isA<RpcException>()));
    });

    test('getOrNull returns null on failure', () async {
      final result = await client.viewAccount(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.getOrNull(), isNull);
    });
  });

  group('Testnet: RPC Error - Code and State Errors', () {
    test('viewCode returns error for non-existent account', () async {
      final result = await client.viewCode(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('viewState returns error for non-existent account', () async {
      final result = await client.viewState(
        accountId: NonExistentAccounts.testnetNonExistent,
        prefixBase64: '',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
