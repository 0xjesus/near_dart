import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:near_flutter/near_flutter.dart';
import 'package:near_flutter/near_flutter.dart';

// Mock wallet adapter for testing
class MockWalletAdapter extends Mock implements WalletAdapter {}

// Fake for mocktail fallback
class FakeAccountId extends Fake implements AccountId {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAccountId());
  });
  group('WalletAdapter', () {
    late MockWalletAdapter adapter;

    setUp(() {
      adapter = MockWalletAdapter();
    });

    group('signIn', () {
      test('returns account on successful sign in', () async {
        final expectedAccount = WalletAccount(
          accountId: AccountId('alice.near'),
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );

        when(() => adapter.signIn(
          contractId: any(named: 'contractId'),
          methodNames: any(named: 'methodNames'),
        )).thenAnswer((_) async => [expectedAccount]);

        final accounts = await adapter.signIn(
          contractId: AccountId('contract.near'),
        );

        expect(accounts, hasLength(1));
        expect(accounts.first.accountId.value, equals('alice.near'));
      });

      test('returns multiple accounts for multi-account wallets', () async {
        final accounts = [
          WalletAccount(
            accountId: AccountId('alice.near'),
            publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
          ),
          WalletAccount(
            accountId: AccountId('bob.near'),
            publicKey: PublicKey('ed25519:7E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
          ),
        ];

        when(() => adapter.signIn(
          contractId: any(named: 'contractId'),
        )).thenAnswer((_) async => accounts);

        final result = await adapter.signIn(
          contractId: AccountId('contract.near'),
        );

        expect(result, hasLength(2));
      });
    });

    group('signOut', () {
      test('completes without error', () async {
        when(() => adapter.signOut()).thenAnswer((_) async {});

        await expectLater(adapter.signOut(), completes);
      });
    });

    group('getAccounts', () {
      test('returns empty list when not signed in', () async {
        when(() => adapter.getAccounts()).thenAnswer((_) async => []);

        final accounts = await adapter.getAccounts();
        expect(accounts, isEmpty);
      });

      test('returns accounts when signed in', () async {
        final account = WalletAccount(
          accountId: AccountId('alice.near'),
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );

        when(() => adapter.getAccounts()).thenAnswer((_) async => [account]);

        final accounts = await adapter.getAccounts();
        expect(accounts, hasLength(1));
      });
    });

    group('isSignedIn', () {
      test('returns false when not signed in', () async {
        when(() => adapter.isSignedIn()).thenAnswer((_) async => false);

        final result = await adapter.isSignedIn();
        expect(result, isFalse);
      });

      test('returns true when signed in', () async {
        when(() => adapter.isSignedIn()).thenAnswer((_) async => true);

        final result = await adapter.isSignedIn();
        expect(result, isTrue);
      });
    });
  });

  group('WalletAccount', () {
    test('creates account with id and public key', () {
      final account = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
      );

      expect(account.accountId.value, equals('alice.near'));
      expect(account.publicKey.keyType, equals(KeyType.ed25519));
    });

    test('value equality works correctly', () {
      final account1 = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
      );

      final account2 = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
      );

      expect(account1, equals(account2));
    });

    test('serializes to JSON correctly', () {
      final account = WalletAccount(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
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
  });

  group('SignedMessage', () {
    test('creates signed message with all fields', () {
      final signedMessage = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        signature: 'base64signature...',
      );

      expect(signedMessage.accountId.value, equals('alice.near'));
      expect(signedMessage.signature, equals('base64signature...'));
    });

    test('serializes to JSON correctly', () {
      final signedMessage = SignedMessage(
        accountId: AccountId('alice.near'),
        publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        signature: 'base64signature...',
        state: 'csrf-token',
      );

      final json = signedMessage.toJson();
      expect(json['accountId'], equals('alice.near'));
      expect(json['signature'], equals('base64signature...'));
      expect(json['state'], equals('csrf-token'));
    });
  });
}
