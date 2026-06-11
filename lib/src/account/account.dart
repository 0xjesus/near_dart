import '../client/near_rpc_client.dart';
import '../client/responses/transaction_response.dart';
import '../crypto/key_pair.dart';
import '../crypto/sign.dart';
import '../types/block_reference.dart';
import '../types/primitives.dart';
import '../types/rpc_result.dart';
import '../wallet/actions.dart';
import '../wallet/transaction.dart';

/// A NEAR account with a local signing key — the highest-level way to
/// execute transactions.
///
/// Handles the full flow in one call: resolves the access key nonce and a
/// recent block hash, builds and Borsh-serializes the transaction, signs
/// it with ed25519, and broadcasts it via `send_tx`.
///
/// ```dart
/// final account = Account(
///   accountId: AccountId('alice.testnet'),
///   keyPair: await KeyPairEd25519.fromString('ed25519:...'),
///   client: NearRpcClient.testnet(),
/// );
///
/// final result = await account.transfer(
///   receiverId: AccountId('bob.testnet'),
///   amount: NearToken.fromNear(1),
/// );
/// ```
class Account {
  Account({
    required this.accountId,
    required this.keyPair,
    required this.client,
  });

  /// The account that signs and sends transactions.
  final AccountId accountId;

  /// The key pair used for signing. Must be registered as a full-access
  /// key (or a function-call key valid for the target contract/methods).
  final KeyPairEd25519 keyPair;

  /// The RPC client used to query state and broadcast transactions.
  final NearRpcClient client;

  /// Highest nonce used so far, so consecutive sends never reuse a nonce
  /// even when the RPC view lags behind.
  BigInt? _lastNonce;

  /// Signs and sends a transaction with the given [actions] to
  /// [receiverId].
  ///
  /// Resolves the nonce and a recent block hash from a single
  /// `view_access_key` query (final finality), then signs locally and
  /// broadcasts via `send_tx`.
  Future<RpcResult<TransactionResponse>> signAndSendTransaction({
    required AccountId receiverId,
    required List<Action> actions,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) async {
    final keyResult = await client.viewAccessKey(
      accountId: accountId,
      publicKey: keyPair.publicKey,
      blockReference: BlockReference.finality(Finality.final_),
    );

    switch (keyResult) {
      case RpcFailure(:final error):
        return RpcResult.failure(error);
      case RpcSuccess(:final value):
        final rpcNonce = BigInt.from(value.nonce);
        final lastNonce = _lastNonce;
        final nonce =
            (lastNonce != null && lastNonce >= rpcNonce
                ? lastNonce
                : rpcNonce) +
            BigInt.one;
        _lastNonce = nonce;

        final signed = await signTransaction(
          Transaction(
            signerId: accountId,
            receiverId: receiverId,
            publicKey: keyPair.publicKey,
            nonce: nonce,
            blockHash: CryptoHash(value.blockHash),
            actions: actions,
          ),
          keyPair,
        );

        return client.sendTransaction(signed, waitUntil: waitUntil);
    }
  }

  /// Transfers [amount] to [receiverId].
  Future<RpcResult<TransactionResponse>> transfer({
    required AccountId receiverId,
    required NearToken amount,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return signAndSendTransaction(
      receiverId: receiverId,
      actions: [TransferAction(deposit: amount)],
      waitUntil: waitUntil,
    );
  }

  /// Calls a state-changing method on a contract (a "change call").
  ///
  /// For read-only calls use [NearRpcClient.callFunction] instead, which
  /// needs no gas or signature.
  Future<RpcResult<TransactionResponse>> callFunction({
    required AccountId contractId,
    required String methodName,
    Object? args,
    BigInt? gas,
    NearToken? deposit,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return signAndSendTransaction(
      receiverId: contractId,
      actions: [
        FunctionCallAction(
          methodName: methodName,
          args: args,
          gas: gas,
          deposit: deposit ?? NearToken.zero(),
        ),
      ],
      waitUntil: waitUntil,
    );
  }
}
