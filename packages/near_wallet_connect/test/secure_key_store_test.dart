import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:near_dart/near_dart.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the platform secure storage.
class FakeSecureStorage implements FlutterSecureStorage {
  final map = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => map[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => map.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeSecureStorage storage;
  late SecureKeyStore store;

  setUp(() {
    storage = FakeSecureStorage();
    store = SecureKeyStore(storage: storage);
  });

  test('stores, lists and retrieves keys', () async {
    final key = await KeyPairEd25519.generate();
    final alice = AccountId('alice.testnet');

    await store.setKey(alice, key);

    expect((await store.accounts()).single.value, 'alice.testnet');
    expect((await store.getKey(alice))!.publicKey, key.publicKey);
    // The secret actually lives in secure storage, not anywhere else.
    expect(storage.map.keys, contains('near_key_alice.testnet'));
  });

  test('removeKey forgets the account', () async {
    final alice = AccountId('alice.testnet');
    await store.setKey(alice, await KeyPairEd25519.generate());

    await store.removeKey(alice);

    expect(await store.accounts(), isEmpty);
    expect(await store.getKey(alice), isNull);
  });

  test('pending key round trip', () async {
    final key = await KeyPairEd25519.generate();

    await store.setPendingKey(key);
    expect((await store.getPendingKey())!.publicKey, key.publicKey);

    await store.clearPendingKey();
    expect(await store.getPendingKey(), isNull);
  });

  test('migrateFrom moves a legacy plain-prefs session', () async {
    SharedPreferences.setMockInitialValues({});
    final legacy = SharedPrefsKeyStore();
    final alice = AccountId('alice.testnet');
    final key = await KeyPairEd25519.generate();
    await legacy.setKey(alice, key);

    await store.migrateFrom(legacy);

    expect((await store.accounts()).single.value, 'alice.testnet');
    expect((await store.getKey(alice))!.publicKey, key.publicKey);
    // The plaintext copy is gone.
    expect(await legacy.accounts(), isEmpty);
    expect(await legacy.getKey(alice), isNull);
  });

  test('migrateFrom is a no-op when secure storage already has keys', () async {
    SharedPreferences.setMockInitialValues({});
    final legacy = SharedPrefsKeyStore();
    await legacy.setKey(
      AccountId('old.testnet'),
      await KeyPairEd25519.generate(),
    );
    final existing = await KeyPairEd25519.generate();
    await store.setKey(AccountId('new.testnet'), existing);

    await store.migrateFrom(legacy);

    expect((await store.accounts()).single.value, 'new.testnet');
    // Legacy store untouched.
    expect((await legacy.accounts()).single.value, 'old.testnet');
  });
}
