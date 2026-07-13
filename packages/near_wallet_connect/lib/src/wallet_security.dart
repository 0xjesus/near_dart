import 'dart:collection';

import 'package:near_dart/near_dart.dart';

/// Opt-in on-chain checks applied to wallet connections and transactions.
class NearWalletSecurityPolicy {
  const NearWalletSecurityPolicy({
    this.verifyAccessKeyOnConnect = false,
    this.transactionFinality,
  });

  /// Whether a completed wallet connection must be verified on chain.
  final bool verifyAccessKeyOnConnect;

  /// The finality required after a wallet submits transactions.
  final TxExecutionStatus? transactionFinality;
}

/// Performs on-chain verification for wallet connections and submissions.
class NearWalletSecurity {
  const NearWalletSecurity(this.client);

  /// RPC client used for every verification request.
  final NearRpcClient client;

  /// Verifies that [account]'s public key exists and has the required scope.
  Future<void> verifyAccessKey({
    required WalletAccount account,
    required AccountId contractId,
    required List<String> methodNames,
    required bool requireFunctionCallScope,
  }) async {
    final result = await client.viewAccessKey(
      accountId: account.accountId,
      publicKey: account.publicKey,
      blockReference: BlockReference.finality(Finality.final_),
    );

    final AccessKeyView accessKey;
    switch (result) {
      case RpcSuccess(:final value):
        accessKey = value;
      case RpcFailure(:final error):
        if (_isMissingAccessKey(error)) {
          throw const NearSdkException(
            code: NearErrorCode.accessKeyNotFound,
            message: 'The wallet access key was not found on chain.',
          );
        }
        throw _safeRpcException(error, operation: 'verify the access key');
    }

    if (!requireFunctionCallScope) return;

    final permission = accessKey.permission;
    if (permission is! FunctionCallPermissionView ||
        permission.receiverId != contractId.value ||
        !_methodsCover(permission.methodNames, methodNames)) {
      throw const NearSdkException(
        code: NearErrorCode.accessKeyMismatch,
        message: 'The wallet access key does not match the required scope.',
      );
    }
  }

  /// Confirms each distinct transaction represented by [outcomes].
  Future<void> confirmTransactions({
    required AccountId senderAccountId,
    required List<dynamic> outcomes,
    required TxExecutionStatus waitUntil,
  }) async {
    final hashes = _extractTransactionHashes(outcomes);
    if (hashes.isEmpty) {
      throw const NearSdkException(
        code: NearErrorCode.walletResponseInvalid,
        message: 'The wallet response did not contain a transaction hash.',
      );
    }

    for (final hash in hashes) {
      final result = await client.txStatus(
        transactionHash: hash,
        senderAccountId: senderAccountId,
        waitUntil: waitUntil,
      );

      final TransactionResponse response;
      switch (result) {
        case RpcSuccess(:final value):
          response = value;
        case RpcFailure(:final error):
          throw _safeRpcException(error, operation: 'confirm the transaction');
      }

      switch (response.status) {
        case TransactionStatusSuccess() || TransactionStatusSuccessReceipt():
          break;
        case TransactionStatusFailure(:final error):
          final insufficientBalance = _containsInsufficientBalance(error);
          throw NearSdkException(
            code: insufficientBalance
                ? NearErrorCode.insufficientBalance
                : NearErrorCode.transactionFailed,
            message: insufficientBalance
                ? 'The transaction could not be completed due to insufficient balance.'
                : 'The transaction failed on chain.',
          );
        case TransactionStatusUnknown():
          throw const NearSdkException(
            code: NearErrorCode.transactionFailed,
            message: 'The transaction did not reach the requested status.',
          );
      }
    }
  }
}

bool _methodsCover(List<String> onChain, List<String> requested) {
  if (onChain.isEmpty) return true;
  if (requested.isEmpty) return false;
  final allowed = onChain.toSet();
  return requested.every(allowed.contains);
}

bool _isMissingAccessKey(RpcError error) {
  if (error.kind != RpcErrorKind.rpcError &&
      error.kind != RpcErrorKind.runtimeError &&
      error.kind != RpcErrorKind.unknown) {
    return false;
  }
  if (error.nearErrorCode == NearErrorCode.accessKeyNotFound) return true;
  final normalized = '${error.message} ${error.data}'.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );
  return normalized.contains('unknownaccesskey') ||
      normalized.contains('accesskeynotfound') ||
      normalized.contains('accesskeydoesnotexist');
}

NearSdkException _safeRpcException(
  RpcError error, {
  required String operation,
}) {
  final code = error.nearErrorCode;
  final retryable = switch (code) {
    NearErrorCode.rpcUnavailable ||
    NearErrorCode.rpcTimeout ||
    NearErrorCode.rateLimited => true,
    _ => false,
  };
  final message = switch (code) {
    NearErrorCode.rpcTimeout =>
      'The RPC request timed out while trying to $operation.',
    NearErrorCode.rateLimited =>
      'The RPC endpoint rate-limited the request to $operation.',
    NearErrorCode.rpcUnavailable =>
      'The RPC endpoint was unavailable while trying to $operation.',
    NearErrorCode.invalidResponse =>
      'The RPC endpoint returned an invalid response while trying to $operation.',
    NearErrorCode.cancelled => 'The RPC request to $operation was cancelled.',
    _ => 'The RPC request could not $operation.',
  };
  return NearSdkException(code: code, message: message, retryable: retryable);
}

List<String> _extractTransactionHashes(List<dynamic> outcomes) {
  final hashes = LinkedHashSet<String>();

  void extract(Object? value) {
    switch (value) {
      case String() when value.isNotEmpty:
        hashes.add(value);
      case TransactionResult(:final transactionHash):
        if (transactionHash.value.isNotEmpty) hashes.add(transactionHash.value);
      case List():
        for (final item in value) {
          extract(item);
        }
      case Map():
        for (final entry in value.entries) {
          if (entry.key case final String key
              when key == 'transactionHash' ||
                  key == 'transaction_hash' ||
                  key == 'txHash' ||
                  key == 'hash' ||
                  key == 'transaction' ||
                  key == 'transactionHashes') {
            extract(entry.value);
          }
        }
    }
  }

  extract(outcomes);
  return hashes.toList(growable: false);
}

bool _containsInsufficientBalance(Map<String, dynamic> failure) {
  final normalized = failure.toString().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );
  return normalized.contains('insufficientbalance') ||
      normalized.contains('lackbalance') ||
      normalized.contains('notenoughbalance');
}
