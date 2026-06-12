import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Validates the full local signing flow (Borsh -> sha256 -> ed25519 ->
/// SignedTransaction Borsh) byte-for-byte against near-api-js@7.2.0.
void main() {
  final vectors =
      jsonDecode(
            File('test/fixtures/near_api_js_vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  final params = vectors['params'] as Map<String, dynamic>;
  final key = vectors['key'] as Map<String, dynamic>;
  final txVectors = vectors['transactions'] as Map<String, dynamic>;

  final signerId = AccountId(params['signer_id'] as String);
  final receiverId = AccountId(params['receiver_id'] as String);
  final nonce = BigInt.parse(params['nonce'] as String);
  final blockHash = CryptoHash(params['block_hash_base58'] as String);

  Transaction txWith(List<Action> actions) => Transaction(
    signerId: signerId,
    receiverId: receiverId,
    nonce: nonce,
    blockHash: blockHash,
    actions: actions,
  );

  group('signTransaction matches near-api-js', () {
    late KeyPairEd25519 keyPair;

    setUpAll(() async {
      keyPair = await KeyPairEd25519.fromString(
        key['secret_key_extended_base58'] as String,
      );
    });

    test('fills in the public key from the key pair', () async {
      final signed = await signTransaction(
        txWith([TransferAction(deposit: NearToken.fromNear(1))]),
        keyPair,
      );
      expect(signed.transaction.publicKey, keyPair.publicKey);
    });

    test('transfer: signature matches', () async {
      final signed = await signTransaction(
        txWith([TransferAction(deposit: NearToken.fromNear(1))]),
        keyPair,
      );
      final expected =
          (txVectors['transfer'] as Map<String, dynamic>)['signature_base64'];
      expect(base64Encode(signed.signatureBytes), expected);
      expect(
        signed.signature,
        'ed25519:${base58Encode(base64Decode(expected as String))}',
      );
    });

    test('transfer: signed transaction Borsh bytes match', () async {
      final signed = await signTransaction(
        txWith([TransferAction(deposit: NearToken.fromNear(1))]),
        keyPair,
      );
      expect(
        base64Encode(serializeSignedTransaction(signed)),
        (txVectors['transfer']
            as Map<String, dynamic>)['signed_tx_borsh_base64'],
      );
    });

    test('multi-action: signed transaction Borsh bytes match', () async {
      final signed = await signTransaction(
        txWith([
          const CreateAccountAction(),
          TransferAction(deposit: NearToken.fromYocto('42')),
          AddKeyAction(
            publicKey: keyPair.publicKey,
            accessKey: const FullAccessKey(),
          ),
        ]),
        keyPair,
      );
      expect(
        base64Encode(serializeSignedTransaction(signed)),
        (txVectors['multi'] as Map<String, dynamic>)['signed_tx_borsh_base64'],
      );
    });

    test('exposes the transaction hash (base58 of sha256)', () async {
      final signed = await signTransaction(
        txWith([TransferAction(deposit: NearToken.fromNear(1))]),
        keyPair,
      );
      expect(
        signed.hash,
        (txVectors['transfer'] as Map<String, dynamic>)['tx_hash_base58'],
      );
    });

    test('encodeToBase64 produces the send_tx payload', () async {
      final signed = await signTransaction(
        txWith([TransferAction(deposit: NearToken.fromNear(1))]),
        keyPair,
      );
      expect(
        signed.encodeToBase64(),
        (txVectors['transfer']
            as Map<String, dynamic>)['signed_tx_borsh_base64'],
      );
    });

    test('throws StateError if nonce or blockHash missing', () async {
      final tx = Transaction(
        signerId: signerId,
        receiverId: receiverId,
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );
      expect(() => signTransaction(tx, keyPair), throwsStateError);
    });
  });
}
