import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Canonical hashes generated with near-kit@0.15.0 `serializeNep413Message`
/// (the verifier used by better-near-auth), nonce = bytes 0..31.
void main() {
  final nonce = List<int>.generate(32, (i) => i);

  group('Nep413Payload', () {
    test('hash matches near-kit (no callbackUrl)', () {
      final payload = Nep413Payload(
        message: 'Sign in to nearbuilders.org',
        recipient: 'nearbuilders.org',
        nonce: nonce,
      );
      expect(
        _hex(payload.hash()),
        'e3d06d4045a76d8281580760de255b9408dffdff686edc10d04ab2b44bbc0472',
      );
    });

    test('hash matches near-kit (with callbackUrl + unicode)', () {
      final payload = Nep413Payload(
        message: 'hola ☕ señor',
        recipient: 'app.testnet',
        nonce: nonce,
        callbackUrl: 'nearcoffee://callback/success',
      );
      expect(
        _hex(payload.hash()),
        '764cf074303ca1652e52548c3585b7f99b4b1a8835b7486ee6beb3047ea55778',
      );
    });

    test('rejects a nonce that is not 32 bytes', () {
      expect(
        () => Nep413Payload(message: 'm', recipient: 'r', nonce: [1, 2, 3]),
        throwsArgumentError,
      );
    });
  });

  group('signNep413Message', () {
    test('produces a base64 signature the same key verifies', () async {
      final keyPair = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'Sign in to example.com',
        recipient: 'example.com',
        nonce: nonce,
      );
      final signed = await signNep413Message(
        payload: payload,
        keyPair: keyPair,
        accountId: AccountId('alice.testnet'),
      );
      expect(signed.publicKey, keyPair.publicKey);
      final ok = await keyPair.verify(
        payload.hash(),
        base64Decode(signed.signature),
      );
      expect(ok, isTrue);
    });
  });

  group('generateNep413Nonce', () {
    test('is 32 bytes and embeds a current big-endian timestamp', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final n = generateNep413Nonce();
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(n.length, 32);
      var ts = 0;
      for (var i = 0; i < 8; i++) {
        ts = ts * 256 + n[i];
      }
      expect(ts, inInclusiveRange(before, after));
    });
  });
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
