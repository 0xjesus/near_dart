import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryKeyStore', () {
    late InMemoryKeyStore store;
    late KeyPairEd25519 keyA;
    late KeyPairEd25519 keyB;

    setUp(() async {
      store = InMemoryKeyStore();
      keyA = await KeyPairEd25519.fromSeed(List.filled(32, 1));
      keyB = await KeyPairEd25519.fromSeed(List.filled(32, 2));
    });

    test('stores and retrieves a key by account', () async {
      await store.setKey(AccountId('alice.testnet'), keyA);
      final got = await store.getKey(AccountId('alice.testnet'));
      expect(got, isNotNull);
      expect(got!.publicKey, keyA.publicKey);
      expect(got.toString(), keyA.toString());
    });

    test('returns null for an unknown account', () async {
      expect(await store.getKey(AccountId('nobody.testnet')), isNull);
    });

    test('lists stored accounts', () async {
      await store.setKey(AccountId('alice.testnet'), keyA);
      await store.setKey(AccountId('bob.testnet'), keyB);
      final accounts = await store.accounts();
      expect(accounts.map((a) => a.value).toSet(), {
        'alice.testnet',
        'bob.testnet',
      });
    });

    test('removes a key', () async {
      await store.setKey(AccountId('alice.testnet'), keyA);
      await store.removeKey(AccountId('alice.testnet'));
      expect(await store.getKey(AccountId('alice.testnet')), isNull);
      expect(await store.accounts(), isEmpty);
    });

    test('overwrites an existing key for the same account', () async {
      await store.setKey(AccountId('alice.testnet'), keyA);
      await store.setKey(AccountId('alice.testnet'), keyB);
      final got = await store.getKey(AccountId('alice.testnet'));
      expect(got!.publicKey, keyB.publicKey);
    });

    group('pending key (survives the sign-in redirect)', () {
      test('stores and retrieves the pending key', () async {
        await store.setPendingKey(keyA);
        final got = await store.getPendingKey();
        expect(got!.toString(), keyA.toString());
      });

      test('returns null when there is no pending key', () async {
        expect(await store.getPendingKey(), isNull);
      });

      test('clears the pending key', () async {
        await store.setPendingKey(keyA);
        await store.clearPendingKey();
        expect(await store.getPendingKey(), isNull);
      });
    });
  });
}
