import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../crypto/strict_ed25519.dart';
import '../encoding/base58.dart';

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

  /// nearcore's account grammar: dot-separated parts, where each part is
  /// alphanumeric runs optionally joined by single `-`/`_`. This rejects
  /// leading/trailing separators and consecutive separators (`..`, `--`,
  /// `a-.b`, …) — the full protocol rules, not just the character set.
  static final _accountPattern = RegExp(
    r'^(([a-z\d]+[\-_])*[a-z\d]+\.)*([a-z\d]+[\-_])*[a-z\d]+$',
  );

  static void _validate(String value) {
    if (value.length < 2) {
      throw ArgumentError.value(
        value,
        'value',
        'Account ID must be at least 2 characters',
      );
    }
    if (value.length > 64) {
      throw ArgumentError.value(
        value,
        'value',
        'Account ID cannot exceed 64 characters',
      );
    }
    if (!_accountPattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Account ID is invalid: allowed are lowercase alphanumeric parts '
            'joined by single ".", "-" or "_" separators (no leading, '
            'trailing or consecutive separators)',
      );
    }
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
  /// For fractional amounts, use [NearToken.parse] (exact) or [fromYocto]
  /// directly with the precise yoctoNEAR value.
  factory NearToken.fromNear(int near) {
    return NearToken._(BigInt.from(near) * _yoctoPerNear);
  }

  /// Parses a decimal NEAR amount string into an exact yoctoNEAR value.
  ///
  /// Unlike floating-point conversion, this is precise for any magnitude.
  ///
  /// ```dart
  /// NearToken.parse('1.5').yoctoNear; // 1500000000000000000000000
  /// ```
  ///
  /// Throws [FormatException] for non-numeric input, negative amounts, or
  /// more than 24 fractional digits (finer than one yoctoNEAR).
  factory NearToken.parse(String near) {
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(near);
    if (match == null) {
      throw FormatException('Invalid NEAR amount', near);
    }
    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    if (fraction.length > 24) {
      throw FormatException(
        'NEAR amount has more than 24 fractional digits (sub-yoctoNEAR)',
        near,
      );
    }
    final paddedFraction = fraction.padRight(24, '0');
    return NearToken._(
      BigInt.parse(whole) * _yoctoPerNear + BigInt.parse(paddedFraction),
    );
  }

  static final BigInt _yoctoPerNear = BigInt.parse('1000000000000000000000000');

  /// The amount in yoctoNEAR.
  final BigInt yoctoNear;

  /// Converts to NEAR as a `double` (may lose precision for large amounts).
  ///
  /// For exact, display-safe output use [toNearString].
  double toNear() {
    return yoctoNear / _yoctoPerNear;
  }

  /// Converts to an exact decimal NEAR string, with no precision loss.
  ///
  /// By default trailing zeros are trimmed (`1.5`, `5`). Pass
  /// [fractionDigits] to force a fixed number of decimals (`1.50`).
  String toNearString({int? fractionDigits}) {
    final whole = yoctoNear ~/ _yoctoPerNear;
    final fraction = yoctoNear % _yoctoPerNear;
    var fractionStr = fraction.toString().padLeft(24, '0');

    if (fractionDigits != null) {
      RangeError.checkValueInInterval(fractionDigits, 0, 24, 'fractionDigits');
      fractionStr = fractionStr.substring(0, fractionDigits);
      return fractionDigits == 0 ? '$whole' : '$whole.$fractionStr';
    }

    fractionStr = fractionStr.replaceFirst(RegExp(r'0+$'), '');
    return fractionStr.isEmpty ? '$whole' : '$whole.$fractionStr';
  }

  /// Returns the sum of two amounts.
  NearToken operator +(NearToken other) =>
      NearToken._(yoctoNear + other.yoctoNear);

  /// Returns the difference of two amounts.
  ///
  /// Throws [ArgumentError] if the result would be negative (yoctoNEAR is
  /// unsigned on-chain).
  NearToken operator -(NearToken other) {
    final result = yoctoNear - other.yoctoNear;
    if (result.isNegative) {
      throw ArgumentError(
        'NearToken subtraction would be negative: '
        '$yoctoNear - ${other.yoctoNear}',
      );
    }
    return NearToken._(result);
  }

  /// Whether this amount is less than [other].
  bool operator <(NearToken other) => yoctoNear < other.yoctoNear;

  /// Whether this amount is greater than [other].
  bool operator >(NearToken other) => yoctoNear > other.yoctoNear;

  /// Whether this amount is less than or equal to [other].
  bool operator <=(NearToken other) => yoctoNear <= other.yoctoNear;

  /// Whether this amount is greater than or equal to [other].
  bool operator >=(NearToken other) => yoctoNear >= other.yoctoNear;

  /// Compares two amounts, returning -1, 0 or 1.
  int compareTo(NearToken other) => yoctoNear.compareTo(other.yoctoNear).sign;

  /// Converts this amount to a JSON string (yoctoNEAR).
  String toJson() => yoctoNear.toString();

  @override
  List<Object?> get props => [yoctoNear];

  @override
  String toString() => '${toNearString()} NEAR';
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
    final KeyType type;
    final int expectedLength;
    if (value.startsWith('ed25519:')) {
      type = KeyType.ed25519;
      expectedLength = 32;
    } else if (value.startsWith('secp256k1:')) {
      type = KeyType.secp256k1;
      expectedLength = 64;
    } else {
      throw ArgumentError.value(
        value,
        'value',
        'Public key must start with "ed25519:" or "secp256k1:"',
      );
    }

    final data = value.substring(value.indexOf(':') + 1);
    final Uint8List bytes;
    try {
      bytes = base58Decode(data);
    } on FormatException catch (e) {
      throw ArgumentError.value(
        value,
        'value',
        'Public key data is not valid base58: ${e.message}',
      );
    }
    if (bytes.length != expectedLength) {
      throw ArgumentError.value(
        value,
        'value',
        'Decoded ${type.name} public key must be $expectedLength bytes, '
            'got ${bytes.length}',
      );
    }
    if (type == KeyType.ed25519 && !isStrictEd25519Point(bytes)) {
      throw ArgumentError.value(
        value,
        'value',
        'Ed25519 public key must be a canonical, non-identity point in the '
            'prime-order subgroup',
      );
    }
    return type;
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
