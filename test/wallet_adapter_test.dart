/// Tests for wallet adapter types.
///
/// Pure unit tests - no mocks, no network required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('WalletType', () {
    test('has all expected variants', () {
      expect(WalletType.values, contains(WalletType.browser));
      expect(WalletType.values, contains(WalletType.injected));
      expect(WalletType.values, contains(WalletType.hardware));
      expect(WalletType.values, contains(WalletType.bridge));
      expect(WalletType.values, contains(WalletType.instantLink));
    });
  });

  group('WalletAccount', () {
    test('creates account with id and public key', () {
      final account = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(account.accountId.value, equals('alice.near'));
      expect(account.publicKey.keyType, equals(KeyType.ed25519));
    });

    test('value equality works correctly', () {
      final account1 = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      final account2 = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(account1, equals(account2));
    });

    test('different accounts are not equal', () {
      final account1 = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      final account2 = WalletAccount(
        accountId: AccountId('bob.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(account1, isNot(equals(account2)));
    });

    test('serializes to JSON correctly', () {
      final account = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      final json = account.toJson();
      expect(json['accountId'], equals('alice.near'));
      expect(json['publicKey'], contains('ed25519:'));
    });
  });

  group('SignMessageParams', () {
    test('creates params with required fields', () {
      final nonce = List<int>.generate(32, (i) => i);
      final params = SignMessageParams(
        message: 'Hello, NEAR!',
        recipient: 'myapp.com',
        nonce: nonce,
      );

      expect(params.message, equals('Hello, NEAR!'));
      expect(params.recipient, equals('myapp.com'));
      expect(params.nonce, hasLength(32));
    });

    test('creates params with optional callback URL', () {
      final nonce = List<int>.generate(32, (i) => i);
      final params = SignMessageParams(
        message: 'Hello, NEAR!',
        recipient: 'myapp.com',
        nonce: nonce,
        callbackUrl: 'https://myapp.com/callback',
      );

      expect(params.callbackUrl, equals('https://myapp.com/callback'));
    });

    test('creates params with optional state', () {
      final nonce = List<int>.generate(32, (i) => i);
      final params = SignMessageParams(
        message: 'Hello, NEAR!',
        recipient: 'myapp.com',
        nonce: nonce,
        state: 'csrf-token-123',
      );

      expect(params.state, equals('csrf-token-123'));
    });

    test('throws if nonce is not 32 bytes', () {
      expect(
        () => SignMessageParams(
          message: 'Hello',
          recipient: 'myapp.com',
          nonce: [1, 2, 3], // Only 3 bytes
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws if nonce is too long', () {
      expect(
        () => SignMessageParams(
          message: 'Hello',
          recipient: 'myapp.com',
          nonce: List.filled(33, 0), // 33 bytes
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equality includes all fields', () {
      final nonce = List<int>.generate(32, (i) => i);
      final params1 = SignMessageParams(
        message: 'Hello',
        recipient: 'app.com',
        nonce: nonce,
        callbackUrl: 'https://callback',
        state: 'state123',
      );
      final params2 = SignMessageParams(
        message: 'Hello',
        recipient: 'app.com',
        nonce: List<int>.generate(32, (i) => i),
        callbackUrl: 'https://callback',
        state: 'state123',
      );

      expect(params1, equals(params2));
    });
  });

  group('SignedMessage', () {
    test('creates signed message with all fields', () {
      final signedMessage = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'base64signature...',
      );

      expect(signedMessage.accountId.value, equals('alice.near'));
      expect(signedMessage.signature, equals('base64signature...'));
    });

    test('creates signed message with state', () {
      final signedMessage = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig',
        state: 'returned-state',
      );

      expect(signedMessage.state, equals('returned-state'));
    });

    test('serializes to JSON correctly', () {
      final signedMessage = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'base64signature...',
        state: 'csrf-token',
      );

      final json = signedMessage.toJson();
      expect(json['accountId'], equals('alice.near'));
      expect(json['signature'], equals('base64signature...'));
      expect(json['state'], equals('csrf-token'));
    });

    test('JSON excludes null state', () {
      final signedMessage = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
        signature: 'sig',
      );

      final json = signedMessage.toJson();
      expect(json.containsKey('state'), isFalse);
    });

    test('equality works correctly', () {
      final msg1 = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:key'),
        signature: 'sig',
        state: 'state',
      );
      final msg2 = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:key'),
        signature: 'sig',
        state: 'state',
      );

      expect(msg1, equals(msg2));
    });
  });
}
