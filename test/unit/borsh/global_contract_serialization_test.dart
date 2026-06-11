import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// NEP-591 Global Contracts action serialization, validated against
/// near-api-js@7.2.0 vectors.
void main() {
  final vectors =
      jsonDecode(
            File('test/fixtures/near_api_js_vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  final params = vectors['params'] as Map<String, dynamic>;
  final key = vectors['key'] as Map<String, dynamic>;
  final txVectors = vectors['transactions'] as Map<String, dynamic>;

  Transaction txWith(List<Action> actions) => Transaction(
    signerId: AccountId(params['signer_id'] as String),
    receiverId: AccountId(params['receiver_id'] as String),
    publicKey: PublicKey(key['public_key'] as String),
    nonce: BigInt.parse(params['nonce'] as String),
    blockHash: CryptoHash(params['block_hash_base58'] as String),
    actions: actions,
  );

  void expectMatches(String vectorName, List<Action> actions) {
    expect(
      base64Encode(serializeTransaction(txWith(actions))),
      (txVectors[vectorName] as Map<String, dynamic>)['tx_borsh_base64'],
      reason: 'Borsh bytes for "$vectorName" must match near-api-js',
    );
  }

  group('NEP-591 global contract actions', () {
    test('deploy_global_contract by code hash', () {
      expectMatches('deploy_global_contract_code_hash', [
        const DeployGlobalContractAction(
          code: [0, 1, 2, 3, 4, 5],
          deployMode: GlobalContractDeployMode.codeHash,
        ),
      ]);
    });

    test('deploy_global_contract by account id', () {
      expectMatches('deploy_global_contract_account_id', [
        const DeployGlobalContractAction(
          code: [0, 1, 2, 3, 4, 5],
          deployMode: GlobalContractDeployMode.accountId,
        ),
      ]);
    });

    test('use_global_contract by account id', () {
      expectMatches('use_global_contract_account_id', [
        UseGlobalContractAction(
          identifier: GlobalContractAccountId(AccountId('global.test.near')),
        ),
      ]);
    });

    test('use_global_contract by code hash', () {
      expectMatches('use_global_contract_code_hash', [
        UseGlobalContractAction(
          identifier: GlobalContractCodeHash(List.filled(32, 0xAB)),
        ),
      ]);
    });
  });
}
