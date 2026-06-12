import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Validates Borsh transaction serialization byte-for-byte against
/// canonical vectors generated with near-api-js@7.2.0
/// (test/fixtures/near_api_js_vectors.json).
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
  final publicKey = PublicKey(key['public_key'] as String);
  final nonce = BigInt.parse(params['nonce'] as String);
  final blockHash = CryptoHash(params['block_hash_base58'] as String);

  Transaction txWith(List<Action> actions) => Transaction(
    signerId: signerId,
    receiverId: receiverId,
    publicKey: publicKey,
    nonce: nonce,
    blockHash: blockHash,
    actions: actions,
  );

  String expectedB64(String name) =>
      (txVectors[name] as Map<String, dynamic>)['tx_borsh_base64'] as String;

  void expectMatches(String vectorName, List<Action> actions) {
    final bytes = serializeTransaction(txWith(actions));
    expect(
      base64Encode(bytes),
      expectedB64(vectorName),
      reason: 'Borsh bytes for "$vectorName" must match near-api-js',
    );
  }

  group('serializeTransaction matches near-api-js', () {
    test('transfer', () {
      expectMatches('transfer', [
        TransferAction(deposit: NearToken.fromNear(1)),
      ]);
    });

    test('create_account', () {
      expectMatches('create_account', [const CreateAccountAction()]);
    });

    test('delete_account', () {
      expectMatches('delete_account', [
        DeleteAccountAction(beneficiaryId: AccountId('beneficiary.test.near')),
      ]);
    });

    test('deploy_contract', () {
      expectMatches('deploy_contract', [
        const DeployContractAction(code: [0, 1, 2, 3, 4, 5]),
      ]);
    });

    test('function_call', () {
      expectMatches('function_call', [
        FunctionCallAction(
          methodName: 'ft_transfer',
          args: {'receiver_id': 'bob.near', 'amount': '100'},
          gas: BigInt.from(30000000000000),
          deposit: NearToken.fromYocto('1'),
        ),
      ]);
    });

    test('stake', () {
      expectMatches('stake', [
        StakeAction(
          stake: NearToken.fromYocto('50000000000000000000000000'),
          publicKey: publicKey,
        ),
      ]);
    });

    test('add_key full access', () {
      expectMatches('add_key_full', [
        AddKeyAction(publicKey: publicKey, accessKey: const FullAccessKey()),
      ]);
    });

    test('add_key function call with allowance', () {
      expectMatches('add_key_fc', [
        AddKeyAction(
          publicKey: publicKey,
          accessKey: FunctionCallAccessKey(
            receiverId: AccountId('contract.test.near'),
            methodNames: const ['m1', 'm2'],
            allowance: NearToken.fromYocto('250000000000000000000000'),
          ),
        ),
      ]);
    });

    test('add_key function call without allowance', () {
      expectMatches('add_key_fc_no_allowance', [
        AddKeyAction(
          publicKey: publicKey,
          accessKey: FunctionCallAccessKey(
            receiverId: AccountId('contract.test.near'),
          ),
        ),
      ]);
    });

    test('delete_key', () {
      expectMatches('delete_key', [DeleteKeyAction(publicKey: publicKey)]);
    });

    test('multiple actions in one transaction', () {
      expectMatches('multi', [
        const CreateAccountAction(),
        TransferAction(deposit: NearToken.fromYocto('42')),
        AddKeyAction(publicKey: publicKey, accessKey: const FullAccessKey()),
      ]);
    });

    test('throws StateError when signing fields are missing', () {
      final tx = Transaction(
        signerId: signerId,
        receiverId: receiverId,
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );
      expect(() => serializeTransaction(tx), throwsStateError);
    });
  });

  group('transaction hash', () {
    test('sha256 of serialized transfer matches near-api-js', () {
      final bytes = serializeTransaction(
        txWith([TransferAction(deposit: NearToken.fromNear(1))]),
      );
      final expectedHash =
          (txVectors['transfer'] as Map<String, dynamic>)['tx_hash_base58']
              as String;
      expect(base58Encode(sha256Hash(bytes)), expectedHash);
    });
  });
}
