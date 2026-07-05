/// Unit tests for wallet types (WalletAccount, SignMessageParams, etc).
///
/// Tests pure logic - no network calls required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('WalletType', () {
    test('has all expected types', () {
      expect(WalletType.values, contains(WalletType.browser));
      expect(WalletType.values, contains(WalletType.injected));
      expect(WalletType.values, contains(WalletType.hardware));
      expect(WalletType.values, contains(WalletType.bridge));
      expect(WalletType.values, contains(WalletType.instantLink));
      expect(WalletType.values.length, equals(5));
    });
  });

  group('WalletAccount', () {
    test('creates with required fields', () {
      final account = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(account.accountId.value, equals('alice.near'));
      expect(
        account.publicKey.value,
        equals('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
      );
    });

    test('toJson serializes correctly', () {
      final account = WalletAccount(
        accountId: AccountId('bob.testnet'),
        publicKey: PublicKey(
          'ed25519:4wBqpZM9xaSheZzJSMawUKKwhdpChKbZ5eu5ky4Vigw',
        ),
      );

      final json = account.toJson();

      expect(json['accountId'], equals('bob.testnet'));
      expect(
        json['publicKey'],
        equals('ed25519:4wBqpZM9xaSheZzJSMawUKKwhdpChKbZ5eu5ky4Vigw'),
      );
    });

    test('equality works correctly', () {
      final a1 = WalletAccount(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );
      final a2 = WalletAccount(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );
      final a3 = WalletAccount(
        accountId: AccountId('other.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(a1, equals(a2));
      expect(a1, isNot(equals(a3)));
    });

    test('hashCode is consistent with equality', () {
      final a1 = WalletAccount(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );
      final a2 = WalletAccount(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(a1.hashCode, equals(a2.hashCode));
    });
  });

  group('SignMessageParams', () {
    test('creates with all fields', () {
      final params = SignMessageParams(
        message: 'Hello, NEAR!',
        recipient: 'myapp.com',
        nonce: List.filled(32, 42),
        callbackUrl: 'https://myapp.com/callback',
        state: 'state123',
      );

      expect(params.message, equals('Hello, NEAR!'));
      expect(params.recipient, equals('myapp.com'));
      expect(params.nonce.length, equals(32));
      expect(params.callbackUrl, equals('https://myapp.com/callback'));
      expect(params.state, equals('state123'));
    });

    test('creates with required fields only', () {
      final params = SignMessageParams(
        message: 'Test message',
        recipient: 'test.com',
        nonce: List.filled(32, 0),
      );

      expect(params.message, equals('Test message'));
      expect(params.recipient, equals('test.com'));
      expect(params.callbackUrl, isNull);
      expect(params.state, isNull);
    });

    test('validates nonce length exactly 32', () {
      // Too short
      expect(
        () => SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(31, 0),
        ),
        throwsArgumentError,
      );

      // Too long
      expect(
        () => SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(33, 0),
        ),
        throwsArgumentError,
      );

      // Exactly 32 is valid
      expect(
        () => SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(32, 0),
        ),
        returnsNormally,
      );
    });

    test('equality includes all fields', () {
      final nonce = List.filled(32, 1);
      final p1 = SignMessageParams(
        message: 'Test',
        recipient: 'app.com',
        nonce: nonce,
        callbackUrl: 'https://callback',
        state: 'state',
      );
      final p2 = SignMessageParams(
        message: 'Test',
        recipient: 'app.com',
        nonce: List.filled(32, 1),
        callbackUrl: 'https://callback',
        state: 'state',
      );
      final p3 = SignMessageParams(
        message: 'Different',
        recipient: 'app.com',
        nonce: nonce,
      );

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('SignedMessage', () {
    test('creates with all fields', () {
      final message = SignedMessage(
        accountId: AccountId('signer.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'base64signature==',
        state: 'returnedState',
      );

      expect(message.accountId.value, equals('signer.near'));
      expect(
        message.publicKey.value,
        equals('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
      );
      expect(message.signature, equals('base64signature=='));
      expect(message.state, equals('returnedState'));
    });

    test('creates without optional state', () {
      final message = SignedMessage(
        accountId: AccountId('signer.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig',
      );

      expect(message.state, isNull);
    });

    test('toJson includes all fields', () {
      final message = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig123',
        state: 'mystate',
      );

      final json = message.toJson();

      expect(json['accountId'], equals('alice.near'));
      expect(
        json['publicKey'],
        equals('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
      );
      expect(json['signature'], equals('sig123'));
      expect(json['state'], equals('mystate'));
    });

    test('toJson excludes null state', () {
      final message = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig123',
      );

      final json = message.toJson();

      expect(json.containsKey('state'), isFalse);
    });

    test('equality works correctly', () {
      final m1 = SignedMessage(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig',
        state: 'state',
      );
      final m2 = SignedMessage(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig',
        state: 'state',
      );
      final m3 = SignedMessage(
        accountId: AccountId('test.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'different',
        state: 'state',
      );

      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
    });
  });
}
