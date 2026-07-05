import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:near_dart/near_dart.dart';

/// A [KeyStore] backed by the platform's secure storage:
///
/// - **Android** — Keystore-encrypted storage
/// - **iOS / macOS** — Keychain
/// - **Windows** — DPAPI (Credential Locker)
/// - **Linux** — Secret Service (libsecret)
/// - **Web** — WebCrypto-encrypted storage (best effort; see below)
///
/// This is the default key store of `NearWalletController` on non-web
/// platforms. On web there is no OS-level secret storage — keys remain
/// reachable by same-origin script, so treat web sessions as lower trust
/// regardless of the store used.
class SecureKeyStore implements KeyStore {
  /// Creates a store; [namespace] prefixes all entries so multiple
  /// apps/networks can coexist. A custom [storage] can be injected for
  /// testing.
  SecureKeyStore({this.namespace = 'near', FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final String namespace;
  final FlutterSecureStorage _storage;

  String get _keyPrefix => '${namespace}_key_';
  String get _accountsKey => '${namespace}_accounts';
  String get _pendingKey => '${namespace}_pending_key';

  @override
  Future<void> setKey(AccountId accountId, KeyPairEd25519 keyPair) async {
    await _storage.write(
      key: '$_keyPrefix${accountId.value}',
      value: keyPair.toString(),
    );
    final ids = (await accounts()).map((a) => a.value).toSet()
      ..add(accountId.value);
    await _storage.write(key: _accountsKey, value: ids.join(','));
  }

  @override
  Future<KeyPairEd25519?> getKey(AccountId accountId) async {
    final encoded = await _storage.read(key: '$_keyPrefix${accountId.value}');
    if (encoded == null) return null;
    return KeyPairEd25519.fromString(encoded);
  }

  @override
  Future<void> removeKey(AccountId accountId) async {
    await _storage.delete(key: '$_keyPrefix${accountId.value}');
    final remaining = (await accounts())
        .where((a) => a.value != accountId.value)
        .map((a) => a.value)
        .toList();
    await _storage.write(key: _accountsKey, value: remaining.join(','));
  }

  @override
  Future<List<AccountId>> accounts() async {
    final raw = await _storage.read(key: _accountsKey);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(AccountId.new)
        .toList();
  }

  @override
  Future<void> setPendingKey(KeyPairEd25519 keyPair) async {
    await _storage.write(key: _pendingKey, value: keyPair.toString());
  }

  @override
  Future<KeyPairEd25519?> getPendingKey() async {
    final encoded = await _storage.read(key: _pendingKey);
    if (encoded == null) return null;
    return KeyPairEd25519.fromString(encoded);
  }

  @override
  Future<void> clearPendingKey() => _storage.delete(key: _pendingKey);

  /// One-time migration from the plain-preferences store used by
  /// near_wallet_connect < 0.3.0: copies any keys found in [legacy] into
  /// secure storage, then removes them from the old location. No-op when
  /// this store already has accounts or the legacy store is empty.
  Future<void> migrateFrom(KeyStore legacy) async {
    if ((await accounts()).isNotEmpty) return;
    final legacyAccounts = await legacy.accounts();
    if (legacyAccounts.isEmpty) return;
    for (final accountId in legacyAccounts) {
      final key = await legacy.getKey(accountId);
      if (key == null) continue;
      await setKey(accountId, key);
      await legacy.removeKey(accountId);
    }
    await legacy.clearPendingKey();
  }
}
