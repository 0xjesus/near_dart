import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Validates ed25519 key handling and signing against canonical vectors
/// generated with near-api-js@7.2.0 + tweetnacl
/// (test/fixtures/near_api_js_vectors.json).
void main() {
  final vectors =
      jsonDecode(
            File('test/fixtures/near_api_js_vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  final key = vectors['key'] as Map<String, dynamic>;
  final secretKey = key['secret_key_extended_base58'] as String;
  final expectedPublicKey = key['public_key'] as String;
  final seedB58 = key['seed_base58'] as String;
  final rawSign = vectors['raw_sign'] as Map<String, dynamic>;

  group('KeyPairEd25519', () {
    test('fromString derives the correct public key', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      expect(keyPair.publicKey.value, expectedPublicKey);
    });

    test('fromSeed derives the correct public key', () async {
      final keyPair = await KeyPairEd25519.fromSeed(base58Decode(seedB58));
      expect(keyPair.publicKey.value, expectedPublicKey);
    });

    test('toString round-trips the extended secret key', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      expect(keyPair.toString(), secretKey);
    });

    test('rejects strings without the ed25519 prefix', () {
      expect(
        () => KeyPairEd25519.fromString('secp256k1:abc'),
        throwsArgumentError,
      );
    });

    test('rejects seeds that are not 32 bytes', () {
      expect(() => KeyPairEd25519.fromSeed([1, 2, 3]), throwsArgumentError);
    });

    test('sign matches tweetnacl signature over raw message', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      final message = utf8.encode(rawSign['message_utf8'] as String);
      final signature = await keyPair.sign(message);
      expect(base64Encode(signature), rawSign['signature_over_raw_base64']);
    });

    test('sign matches tweetnacl signature over sha256(message)', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      final message = utf8.encode(rawSign['message_utf8'] as String);
      final signature = await keyPair.sign(sha256Hash(message));
      expect(base64Encode(signature), rawSign['signature_over_sha256_base64']);
    });

    test('verify accepts its own signature', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      final message = utf8.encode('verify me');
      final signature = await keyPair.sign(message);
      expect(await keyPair.verify(message, signature), isTrue);
    });

    test('verify rejects a tampered message', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      final signature = await keyPair.sign(utf8.encode('original'));
      expect(await keyPair.verify(utf8.encode('tampered'), signature), isFalse);
    });

    test('generate produces a distinct working key pair', () async {
      final a = await KeyPairEd25519.generate();
      final b = await KeyPairEd25519.generate();
      expect(a.publicKey.value, isNot(b.publicKey.value));
      expect(a.publicKey.value, startsWith('ed25519:'));

      final signature = await a.sign(utf8.encode('hello'));
      expect(signature.length, 64);
      expect(await a.verify(utf8.encode('hello'), signature), isTrue);
    });

    test('signatures are 64 bytes', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      final signature = await keyPair.sign(utf8.encode('x'));
      expect(signature.length, 64);
    });
  });
}
