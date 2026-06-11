/// Verifies the local signing pipeline (ed25519 + Borsh + base58) works on
/// the **browser/dart2js** runtime, not just the VM.
///
/// Web can't read fixture files (no dart:io), so the canonical near-api-js
/// values are inlined here. They are the same vectors validated on the VM
/// in test/unit/.
///
/// Run with: dart test --platform chrome test/platform/web_signing_test.dart
@TestOn('browser')
@Tags(['platform', 'web'])
library;

import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  // Canonical vector (near-api-js@7.2.0 + tweetnacl), key from seed 1..32.
  const secretKey =
      'ed25519:2Ana1pUpv2ZbMVkwF5FXapYeBEjdxDatLn7nvJkhgTSdZd8hbDHTd21as7EAsg7ypityqfsw2pMQKJcVDVcAEsd';
  const publicKey = 'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj';
  const blockHash = '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM';
  const expectedTxHash = 'C2fZ1CFebSnZhCGjeLREQDWcJjWKsXaqxYcUP6638swj';
  const expectedSignedTxB64 =
      'FAAAAHNlcmlhbGl6ZXIudGVzdC5uZWFyAHm1Vi6P5lT5QHixEuipi6eQH4U65pW+1+'
      'DjkQutBJZkFc1bBwAAAAASAAAAcmVjZWl2ZXIudGVzdC5uZWFyD6Rz/SaQHfKWvmrc'
      'TMTfNNBA76JDUiS2mGkQ5jDC/vYBAAAAAwAAAKHtzM4bwtMAAAAAAAAAshLNpSWCwB'
      'GgK9sh2iKfo0RnqNmmokN5dYfLSnNiI55MyZKwsr5AuA42xypNhRunY4VroEOszsuS'
      'vehG+xGeAA==';

  group('Web: base58 + Borsh (no crypto)', () {
    test('base58 round-trips a public key in JS', () {
      expect(
        base58Encode(base58Decode(publicKey.substring(8))),
        publicKey.substring(8),
      );
    });

    test('serializeTransaction produces the canonical hash in JS', () {
      final tx = Transaction(
        signerId: AccountId('serializer.test.near'),
        receiverId: AccountId('receiver.test.near'),
        publicKey: PublicKey(publicKey),
        nonce: BigInt.from(123456789),
        blockHash: const CryptoHash(blockHash),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );
      final bytes = serializeTransaction(tx);
      expect(base58Encode(sha256Hash(bytes)), expectedTxHash);
    });
  });

  group('Web: ed25519 signing (the part most likely to break in JS)', () {
    test('imports a key and derives the public key in JS', () async {
      final keyPair = await KeyPairEd25519.fromString(secretKey);
      expect(keyPair.publicKey.value, publicKey);
    });

    test('generate + sign + verify round-trips in JS', () async {
      final keyPair = await KeyPairEd25519.generate();
      final message = utf8.encode('runs in the browser');
      final signature = await keyPair.sign(message);
      expect(signature.length, 64);
      expect(await keyPair.verify(message, signature), isTrue);
      expect(await keyPair.verify(utf8.encode('tampered'), signature), isFalse);
    });

    test(
      'signs the canonical transfer to the exact same bytes in JS',
      () async {
        final keyPair = await KeyPairEd25519.fromString(secretKey);
        final signed = await signTransaction(
          Transaction(
            signerId: AccountId('serializer.test.near'),
            receiverId: AccountId('receiver.test.near'),
            nonce: BigInt.from(123456789),
            blockHash: const CryptoHash(blockHash),
            actions: [TransferAction(deposit: NearToken.fromNear(1))],
          ),
          keyPair,
        );
        expect(signed.hash, expectedTxHash);
        expect(signed.encodeToBase64(), expectedSignedTxB64);
      },
    );
  });
}
