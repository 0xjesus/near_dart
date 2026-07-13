import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as c;
import 'package:meta/meta.dart';

import '../encoding/base58.dart';
import '../types/primitives.dart';
import 'strict_ed25519.dart';

/// An ed25519 key pair capable of signing NEAR transactions and messages.
///
/// Secret keys use the NEAR "extended" format: 64 bytes (32-byte seed
/// followed by the 32-byte public key), base58 encoded with an `ed25519:`
/// prefix — the same format used by near-api-js, near-cli and wallet
/// exports.
///
/// ```dart
/// final keyPair = await KeyPairEd25519.fromString('ed25519:3D4YudUahN1...');
/// final signature = await keyPair.sign(messageBytes);
/// ```
@immutable
class KeyPairEd25519 {
  KeyPairEd25519._(this._keyPair, this._seed, List<int> publicKeyBytes)
    : publicKey = PublicKey('ed25519:${base58Encode(publicKeyBytes)}'),
      _publicKeyBytes = Uint8List.fromList(publicKeyBytes);

  static final c.Ed25519 _algorithm = c.Ed25519();

  final c.SimpleKeyPair _keyPair;
  final Uint8List _seed;
  final Uint8List _publicKeyBytes;

  /// The NEAR-formatted public key (`ed25519:<base58>`).
  final PublicKey publicKey;

  /// Creates a key pair from a 32-byte seed.
  ///
  /// Throws [ArgumentError] if [seed] is not exactly 32 bytes.
  static Future<KeyPairEd25519> fromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw ArgumentError.value(
        seed.length,
        'seed',
        'ed25519 seed must be exactly 32 bytes',
      );
    }
    final keyPair = await _algorithm.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    return KeyPairEd25519._(keyPair, Uint8List.fromList(seed), publicKey.bytes);
  }

  /// Creates a key pair from a NEAR-formatted secret key string:
  /// `ed25519:<base58 of 64-byte (seed || public key)>`.
  ///
  /// Also accepts a bare 32-byte seed for convenience.
  static Future<KeyPairEd25519> fromString(String secretKey) async {
    const prefix = 'ed25519:';
    if (!secretKey.startsWith(prefix)) {
      throw ArgumentError.value(
        secretKey,
        'secretKey',
        'Secret key must start with "ed25519:"',
      );
    }
    final bytes = base58Decode(secretKey.substring(prefix.length));
    if (bytes.length == 64) {
      return fromSeed(bytes.sublist(0, 32));
    }
    if (bytes.length == 32) {
      return fromSeed(bytes);
    }
    throw ArgumentError.value(
      secretKey,
      'secretKey',
      'Secret key must decode to 64 bytes (seed || public key) or 32 bytes '
          '(seed), got ${bytes.length}',
    );
  }

  /// Generates a new random key pair using a cryptographically secure RNG.
  static Future<KeyPairEd25519> generate() async {
    final keyPair = await _algorithm.newKeyPair();
    final seed = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    return KeyPairEd25519._(keyPair, Uint8List.fromList(seed), publicKey.bytes);
  }

  /// Signs [message] and returns the 64-byte detached signature.
  ///
  /// Note: NEAR transactions sign `sha256(borsh(transaction))` — see
  /// `signTransaction` for the full flow.
  Future<Uint8List> sign(List<int> message) async {
    final signature = await _algorithm.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verifies a detached [signature] over [message] with this public key.
  Future<bool> verify(List<int> message, List<int> signature) =>
      verifySignature(
        message: message,
        signature: signature,
        publicKey: publicKey,
      );

  /// The NEAR-formatted extended secret key (`ed25519:<base58>`).
  ///
  /// Handle with care: this is the private key material.
  @override
  String toString() =>
      'ed25519:${base58Encode([..._seed, ..._publicKeyBytes])}';
}

/// Verifies a detached ed25519 [signature] over [message] against any
/// NEAR-formatted [publicKey], without needing the secret key.
Future<bool> verifySignature({
  required List<int> message,
  required List<int> signature,
  required PublicKey publicKey,
}) async {
  if (publicKey.keyType != KeyType.ed25519) {
    throw ArgumentError.value(
      publicKey.value,
      'publicKey',
      'Only ed25519 signature verification is supported',
    );
  }
  try {
    final publicKeyBytes = base58Decode(publicKey.keyData);
    if (!isStrictEd25519Point(publicKeyBytes) || signature.length != 64) {
      return false;
    }
    if (!isStrictEd25519Point(signature.sublist(0, 32)) ||
        !isCanonicalEd25519Scalar(signature.sublist(32))) {
      return false;
    }
    return c.Ed25519().verify(
      message,
      signature: c.Signature(
        signature,
        publicKey: c.SimplePublicKey(
          publicKeyBytes,
          type: c.KeyPairType.ed25519,
        ),
      ),
    );
  } catch (_) {
    return false;
  }
}
