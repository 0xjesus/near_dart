import '../crypto/key_pair.dart';
import '../types/primitives.dart';

/// Stores ed25519 key pairs for connected accounts.
///
/// Mirrors near-api-js's KeyStore abstraction. The core ships a pure-Dart
/// [InMemoryKeyStore]; apps that need persistence (to survive a web
/// sign-in redirect, or across launches) provide their own implementation
/// backed by secure storage — see the example's `SecureStorageKeyStore`.
///
/// A "pending" key is the freshly generated key pair held during the
/// sign-in redirect round-trip, before it is confirmed and promoted to a
/// real account entry.
abstract interface class KeyStore {
  /// Stores [keyPair] for [accountId], replacing any existing entry.
  Future<void> setKey(AccountId accountId, KeyPairEd25519 keyPair);

  /// Returns the key pair for [accountId], or null if none is stored.
  Future<KeyPairEd25519?> getKey(AccountId accountId);

  /// Removes the stored key pair for [accountId], if any.
  Future<void> removeKey(AccountId accountId);

  /// Lists the accounts that have a stored key pair.
  Future<List<AccountId>> accounts();

  /// Stores the pending sign-in key pair.
  Future<void> setPendingKey(KeyPairEd25519 keyPair);

  /// Returns the pending sign-in key pair, or null.
  Future<KeyPairEd25519?> getPendingKey();

  /// Clears the pending sign-in key pair.
  Future<void> clearPendingKey();
}

/// A non-persistent [KeyStore] that keeps keys in memory.
///
/// Suitable for tests and short-lived sessions. It does NOT survive a web
/// page redirect or an app restart — use a persistent implementation for
/// the sign-in redirect flow.
class InMemoryKeyStore implements KeyStore {
  final Map<String, String> _keys = {};
  String? _pendingKey;

  @override
  Future<void> setKey(AccountId accountId, KeyPairEd25519 keyPair) async {
    _keys[accountId.value] = keyPair.toString();
  }

  @override
  Future<KeyPairEd25519?> getKey(AccountId accountId) async {
    final encoded = _keys[accountId.value];
    if (encoded == null) return null;
    return KeyPairEd25519.fromString(encoded);
  }

  @override
  Future<void> removeKey(AccountId accountId) async {
    _keys.remove(accountId.value);
  }

  @override
  Future<List<AccountId>> accounts() async {
    return _keys.keys.map(AccountId.new).toList();
  }

  @override
  Future<void> setPendingKey(KeyPairEd25519 keyPair) async {
    _pendingKey = keyPair.toString();
  }

  @override
  Future<KeyPairEd25519?> getPendingKey() async {
    final encoded = _pendingKey;
    if (encoded == null) return null;
    return KeyPairEd25519.fromString(encoded);
  }

  @override
  Future<void> clearPendingKey() async {
    _pendingKey = null;
  }
}
