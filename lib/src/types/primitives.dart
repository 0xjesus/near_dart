import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents a NEAR Protocol cryptographic hash (32 bytes, base58 encoded).
///
/// Used for block hashes, transaction hashes, state roots, etc.
@immutable
class CryptoHash extends Equatable {
  /// Creates a CryptoHash from a base58 encoded string.
  const CryptoHash(this.value);

  /// Creates a CryptoHash from a JSON string.
  factory CryptoHash.fromJson(String json) => CryptoHash(json);

  /// The base58 encoded hash value.
  final String value;

  /// Converts this hash to a JSON string.
  String toJson() => value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Represents a NEAR Protocol account identifier.
///
/// Account IDs follow these rules:
/// - Minimum length: 2 characters (or 64 for implicit accounts)
/// - Maximum length: 64 characters
/// - Valid characters: a-z, 0-9, `-`, `_`, `.`
/// - Cannot start or end with `-` or `.`
/// - Cannot contain `..`
@immutable
class AccountId extends Equatable {
  /// Creates an AccountId with validation.
  ///
  /// Throws [ArgumentError] if the account ID is invalid.
  AccountId(this.value) {
    _validate(value);
  }

  /// Creates an AccountId from a JSON string.
  factory AccountId.fromJson(String json) => AccountId(json);

  /// The account identifier string.
  final String value;

  static void _validate(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Account ID cannot be empty');
    }

    // Implicit accounts are 64 hex characters
    if (value.length == 64 && _isHex(value)) {
      return; // Valid implicit account
    }

    if (value.length > 64) {
      throw ArgumentError.value(
        value,
        'value',
        'Account ID cannot exceed 64 characters',
      );
    }

    // Basic character validation for named accounts
    final validPattern = RegExp(r'^[a-z0-9._-]+$');
    if (!validPattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Account ID contains invalid characters',
      );
    }
  }

  static bool _isHex(String value) {
    return RegExp(r'^[0-9a-f]+$').hasMatch(value);
  }

  /// Converts this account ID to a JSON string.
  String toJson() => value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Represents NEAR token amounts in yoctoNEAR (10^-24 NEAR).
///
/// NEAR uses yoctoNEAR as the smallest unit:
/// - 1 NEAR = 10^24 yoctoNEAR
/// - Amounts are represented as strings in JSON to preserve precision.
@immutable
class NearToken extends Equatable {
  /// Creates a NearToken from yoctoNEAR amount.
  const NearToken._(this.yoctoNear);

  /// Creates a NearToken representing zero.
  factory NearToken.zero() => NearToken._(BigInt.zero);

  /// Creates a NearToken representing 1 yoctoNEAR (smallest unit).
  factory NearToken.oneYocto() => NearToken._(BigInt.one);

  /// Creates a NearToken from a yoctoNEAR string.
  factory NearToken.fromYocto(String yoctoNear) {
    return NearToken._(BigInt.parse(yoctoNear));
  }

  /// Creates a NearToken from a JSON string (yoctoNEAR).
  factory NearToken.fromJson(String json) => NearToken.fromYocto(json);

  /// Creates a NearToken from NEAR amount (whole number only).
  ///
  /// For fractional amounts, use [fromYocto] directly with the precise
  /// yoctoNEAR value to avoid floating-point precision issues.
  factory NearToken.fromNear(int near) {
    // 1 NEAR = 10^24 yoctoNEAR
    final oneNear = BigInt.parse('1000000000000000000000000');
    return NearToken._(BigInt.from(near) * oneNear);
  }

  /// The amount in yoctoNEAR.
  final BigInt yoctoNear;

  /// Converts to NEAR (may lose precision for very large amounts).
  double toNear() {
    return yoctoNear / BigInt.parse('1000000000000000000000000');
  }

  /// Converts this amount to a JSON string (yoctoNEAR).
  String toJson() => yoctoNear.toString();

  @override
  List<Object?> get props => [yoctoNear];

  @override
  String toString() => '${toNear()} NEAR';
}

/// The type of cryptographic key.
enum KeyType {
  /// Ed25519 elliptic curve key.
  ed25519,

  /// Secp256k1 elliptic curve key (used for Ethereum compatibility).
  secp256k1,
}

/// Represents a NEAR Protocol public key.
///
/// Public keys are formatted as `{key_type}:{base58_encoded_key}`.
/// Example: `ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp`
@immutable
class PublicKey extends Equatable {
  /// Creates a PublicKey with validation.
  ///
  /// Throws [ArgumentError] if the key format is invalid.
  PublicKey(this.value) : keyType = _parseKeyType(value);

  /// Creates a PublicKey from a JSON string.
  factory PublicKey.fromJson(String json) => PublicKey(json);

  /// The full key string including type prefix.
  final String value;

  /// The type of this key.
  final KeyType keyType;

  static KeyType _parseKeyType(String value) {
    if (value.startsWith('ed25519:')) {
      return KeyType.ed25519;
    }
    if (value.startsWith('secp256k1:')) {
      return KeyType.secp256k1;
    }
    throw ArgumentError.value(
      value,
      'value',
      'Public key must start with "ed25519:" or "secp256k1:"',
    );
  }

  /// Returns the key data without the type prefix.
  String get keyData {
    final colonIndex = value.indexOf(':');
    return value.substring(colonIndex + 1);
  }

  /// Converts this key to a JSON string.
  String toJson() => value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
