import 'package:near_dart/near_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A persistent [KeyStore] backed by `shared_preferences`.
///
/// This survives the MyNearWallet sign-in redirect (the page reload on web,
/// the app switch on mobile) and app restarts — which the core
/// `InMemoryKeyStore` does not.
///
/// NOTE: `shared_preferences` is plain (unencrypted) storage and is used
/// here because it works reliably on every platform including web. A
/// production mobile app should back the [KeyStore] with encrypted storage
/// (e.g. `flutter_secure_storage`) instead — the interface is the same.
class SharedPrefsKeyStore implements KeyStore {
  static const _keyPrefix = 'near_key_';
  static const _accountsKey = 'near_accounts';
  static const _pendingKey = 'near_pending_key';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<void> setKey(AccountId accountId, KeyPairEd25519 keyPair) async {
    final prefs = await _prefs;
    await prefs.setString('$_keyPrefix${accountId.value}', keyPair.toString());
    final ids = (await accounts()).map((a) => a.value).toSet()
      ..add(accountId.value);
    await prefs.setString(_accountsKey, ids.join(','));
  }

  @override
  Future<KeyPairEd25519?> getKey(AccountId accountId) async {
    final encoded = (await _prefs).getString('$_keyPrefix${accountId.value}');
    if (encoded == null) return null;
    return KeyPairEd25519.fromString(encoded);
  }

  @override
  Future<void> removeKey(AccountId accountId) async {
    final prefs = await _prefs;
    await prefs.remove('$_keyPrefix${accountId.value}');
    final remaining = (await accounts())
        .where((a) => a.value != accountId.value)
        .map((a) => a.value)
        .toList();
    await prefs.setString(_accountsKey, remaining.join(','));
  }

  @override
  Future<List<AccountId>> accounts() async {
    final raw = (await _prefs).getString(_accountsKey);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(AccountId.new)
        .toList();
  }

  @override
  Future<void> setPendingKey(KeyPairEd25519 keyPair) async {
    await (await _prefs).setString(_pendingKey, keyPair.toString());
  }

  @override
  Future<KeyPairEd25519?> getPendingKey() async {
    final encoded = (await _prefs).getString(_pendingKey);
    if (encoded == null) return null;
    return KeyPairEd25519.fromString(encoded);
  }

  @override
  Future<void> clearPendingKey() async {
    await (await _prefs).remove(_pendingKey);
  }
}
