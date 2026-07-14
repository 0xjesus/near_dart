@TestOn('vm')
@Tags(['e2e', 'integration', 'testnet'])
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Full end-to-end test of local signing against the REAL testnet:
///
/// 1. Generates an ed25519 key pair with this SDK.
/// 2. Creates a throwaway funded account via the testnet faucet.
/// 3. Signs and sends a real Transfer with `Account.transfer`.
/// 4. Verifies the on-chain execution outcome and balance movement.
/// 5. Deletes the account (exercising DeleteAccountAction end-to-end).
///
/// This validates the entire pipeline — Borsh serialization, sha256,
/// ed25519 signature, nonce/blockHash resolution and `send_tx` — against
/// nearcore itself. No mocks.
Future<AccessKeyView> _waitForAccessKey({
  required NearRpcClient client,
  required AccountId accountId,
  required PublicKey publicKey,
  Duration timeout = const Duration(seconds: 30),
  Duration pollInterval = const Duration(seconds: 1),
}) async {
  final elapsed = Stopwatch()..start();
  RpcError? lastError;
  var attempts = 0;

  while (elapsed.elapsed < timeout) {
    attempts++;
    final result = await client.viewAccessKey(
      accountId: accountId,
      publicKey: publicKey,
      blockReference: BlockReference.finality(Finality.final_),
    );
    final accessKey = result.getOrNull();
    if (accessKey != null) return accessKey;
    lastError = (result as RpcFailure<AccessKeyView>).error;

    final remaining = timeout - elapsed.elapsed;
    if (remaining <= Duration.zero) break;
    await Future<void>.delayed(
      pollInterval < remaining ? pollInterval : remaining,
    );
  }

  fail(
    'Faucet-created access key did not become queryable within '
    '${timeout.inSeconds}s: account=${accountId.value}, '
    'publicKey=${publicKey.value}, attempts=$attempts, '
    'lastRpcKind=${lastError?.kind}, lastRpcCode=${lastError?.code}',
  );
}

void main() {
  const faucetUrl = 'https://helper.testnet.near.org/account';

  test('signs, sends and executes a real transfer on testnet', () async {
    final client = NearRpcClient.testnet();
    addTearDown(client.close);

    // 1. Fresh key pair from this SDK.
    final keyPair = await KeyPairEd25519.generate();
    final accountId = AccountId(
      'near-dart-e2e-${DateTime.now().millisecondsSinceEpoch}.testnet',
    );

    // 2. Fund it via the faucet.
    final faucetResponse = await http.post(
      Uri.parse(faucetUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'newAccountId': accountId.value,
        'newAccountPublicKey': keyPair.publicKey.value,
      }),
    );
    if (faucetResponse.statusCode != 200) {
      markTestSkipped(
        'Testnet faucet unavailable '
        '(HTTP ${faucetResponse.statusCode}); skipping E2E.',
      );
      return;
    }

    // Wait for the exact key needed by transaction signing, not only account
    // visibility, because faucet-created state can become queryable in stages.
    final accessKey = await _waitForAccessKey(
      client: client,
      accountId: accountId,
      publicKey: keyPair.publicKey,
    );
    expect(accessKey.nonce, greaterThanOrEqualTo(0));

    final accountResult = await client.viewAccount(
      accountId: accountId,
      blockReference: BlockReference.finality(Finality.optimistic),
    );
    if (accountResult case RpcFailure<AccountView>(:final error)) {
      fail(
        'Faucet-created account was unavailable after its access key became '
        'queryable: account=${accountId.value}, rpcKind=${error.kind}, '
        'rpcCode=${error.code}',
      );
    }
    final initialBalance = accountResult.getOrThrow().amount.yoctoNear;
    expect(initialBalance > BigInt.zero, isTrue);

    // 3. Sign and send a real transfer (0.001 NEAR to the registrar).
    final account = Account(
      accountId: accountId,
      keyPair: keyPair,
      client: client,
    );
    final transferAmount = NearToken.fromYocto('1000000000000000000000');
    final result = await account.transfer(
      receiverId: AccountId('testnet'),
      amount: transferAmount,
      waitUntil: TxExecutionStatus.executed,
    );

    // 4. Verify the on-chain outcome.
    expect(result.isSuccess, isTrue, reason: 'send_tx failed: $result');
    final outcome = result.getOrThrow();
    expect(outcome.status, isA<TransactionStatusSuccess>());
    expect(outcome.transaction.signerId, accountId.value);
    expect(outcome.transaction.publicKey, keyPair.publicKey.value);
    expect(outcome.transactionOutcome.outcome.gasBurnt, greaterThan(0));

    final afterTransfer = await client.viewAccount(
      accountId: accountId,
      blockReference: BlockReference.finality(Finality.optimistic),
    );
    final afterBalance = afterTransfer.getOrThrow().amount.yoctoNear;
    expect(
      afterBalance < initialBalance - transferAmount.yoctoNear,
      isTrue,
      reason: 'Balance must drop by at least the transfer amount + gas',
    );

    // 5. Clean up: delete the account, sending funds back to the faucet.
    final deletion = await account.signAndSendTransaction(
      receiverId: accountId,
      actions: [DeleteAccountAction(beneficiaryId: AccountId('testnet'))],
      waitUntil: TxExecutionStatus.executed,
    );
    expect(
      deletion.isSuccess,
      isTrue,
      reason: 'Account cleanup failed: $deletion',
    );
    expect(deletion.getOrThrow().status, isA<TransactionStatusSuccess>());
  });
}
