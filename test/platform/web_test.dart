/// Platform-specific tests for web/browser.
///
/// These tests verify functionality specific to the browser runtime.
/// Run with: dart test --platform chrome test/platform/web_test.dart
@TestOn('browser')
@Tags(['platform', 'web'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('Web Platform: NearRpcClient', () {
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

  group('Web Platform: Type Creation', () {
    test('AccountId creation works', () {
      final account = AccountId('test.near');
      expect(account.value, equals('test.near'));
    });

    test('NearToken BigInt operations work', () {
      final token = NearToken.fromNear(1000000);
      expect(token.yoctoNear, greaterThan(BigInt.zero));

      // Verify large BigInt operations work in JS
      final largeToken = NearToken.fromYocto('999999999999999999999999999999');
      expect(
        largeToken.yoctoNear.toString(),
        equals('999999999999999999999999999999'),
      );
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

  group('Web Platform: JSON Serialization', () {
    test('BlockReference serializes correctly', () {
      final ref = BlockReference.finality(Finality.final_);
      expect(ref.toJson(), equals({'finality': 'final'}));
    });

    test('HeightBlockReference serializes correctly', () {
      final ref = BlockReference.blockId(12345678);
      expect(ref.toJson(), equals({'block_id': 12345678}));
    });

    test('Action serializes correctly', () {
      final action = TransferAction(deposit: NearToken.fromNear(1));
      final json = action.toJson();
      expect(json.containsKey('Transfer'), isTrue);
    });

    test('FunctionCallAction with args serializes', () {
      final action = FunctionCallAction(
        methodName: 'test_method',
        args: {'key': 'value'},
        deposit: NearToken.zero(),
      );
      final json = action.toJson();
      expect(json['FunctionCall']['method_name'], equals('test_method'));
    });
  });

  group('Web Platform: Equality and Hashing', () {
    test('AccountId equality works', () {
      final a1 = AccountId('test.near');
      final a2 = AccountId('test.near');
      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('NearToken equality works', () {
      final t1 = NearToken.fromNear(5);
      final t2 = NearToken.fromNear(5);
      expect(t1, equals(t2));
    });

    test('BlockReference equality works', () {
      final r1 = BlockReference.finality(Finality.final_);
      final r2 = BlockReference.finality(Finality.final_);
      expect(r1, equals(r2));
    });
  });

  group('Web Platform: RPC Calls (requires network)', () {
    late NearRpcClient client;

    setUpAll(() {
      client = NearRpcClient.testnet();
    });

    tearDownAll(() {
      client.close();
    });

    test('status() works in browser', () async {
      final result = await client.status();
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().chainId, equals('testnet'));
    });

    test('viewAccount() works in browser', () async {
      final result = await client.viewAccount(
        accountId: AccountId('testnet'),
        blockReference: BlockReference.finality(Finality.final_),
      );
      expect(result.isSuccess, isTrue);
    });

    test('callFunction() works in browser', () async {
      final result = await client.callFunction(
        accountId: AccountId('wrap.testnet'),
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('Web Platform: URL Handling', () {
    test('Uri parsing works', () {
      final uri = Uri.parse(
        'https://app.mynearwallet.com/login?contract_id=test.near',
      );
      expect(uri.host, equals('app.mynearwallet.com'));
      expect(uri.queryParameters['contract_id'], equals('test.near'));
    });

    test('Uri building works', () {
      final uri = Uri.https('app.mynearwallet.com', '/login', {
        'contract_id': 'test.near',
        'success_url': 'https://myapp.com/success',
      });
      expect(uri.toString(), contains('contract_id=test.near'));
    });
  });
}
