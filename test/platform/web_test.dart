/// Platform-specific tests for web/browser.
///
/// These tests verify functionality specific to the browser runtime.
/// Run with: dart test --platform chrome test/platform/web_test.dart
@TestOn('browser')
@Tags(['platform', 'web'])
library;

import 'dart:convert';

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

  group('Web Platform: Strict Ed25519', () {
    final publicKey = PublicKey(
      'ed25519:${base58Encode(_hex('d75a980182b10ab7d54bfed3c964073a'
      '0ee172f3daa62325af021a68f707511a'))}',
    );
    final validSignature = _hex(
      'e5564300c360ac729086e2cc806e828a'
      '84877f1eb8e5d974d873e06522490155'
      '5fb8821590a33bacc61e39701cf9b46b'
      'd25bf5f0595bbe24655141438e7a100b',
    );

    test('verifies RFC 8032 test vector 1', () async {
      expect(
        await verifySignature(
          message: const [],
          signature: validSignature,
          publicKey: publicKey,
        ),
        isTrue,
      );
    });

    test('rejects identity and zero public keys', () {
      final identity = [1, ...List<int>.filled(31, 0)];
      final zero = List<int>.filled(32, 0);

      expect(
        () => PublicKey('ed25519:${base58Encode(identity)}'),
        throwsArgumentError,
      );
      expect(
        () => PublicKey('ed25519:${base58Encode(zero)}'),
        throwsArgumentError,
      );
    });

    test('returns false for identity R with S = 0', () async {
      final identity = [1, ...List<int>.filled(31, 0)];

      expect(
        await verifySignature(
          message: utf8.encode('browser strict verification'),
          signature: [...identity, ...List<int>.filled(32, 0)],
          publicKey: publicKey,
        ),
        isFalse,
      );
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

List<int> _hex(String value) => [
  for (var i = 0; i < value.length; i += 2)
    int.parse(value.substring(i, i + 2), radix: 16),
];
