import '../account/account.dart';
import '../client/near_rpc_client.dart';
import '../client/responses/transaction_response.dart';
import '../types/block_reference.dart';
import '../types/primitives.dart';
import '../types/rpc_result.dart';

/// NEP-145 storage balance bounds.
class StorageBalanceBounds {
  const StorageBalanceBounds({
    required this.min,
    required this.max,
    required this.raw,
  });

  factory StorageBalanceBounds.fromJson(Map<String, dynamic> json) {
    return StorageBalanceBounds(
      min: NearToken.fromYocto(json['min'] as String),
      max: json['max'] == null
          ? null
          : NearToken.fromYocto(json['max'] as String),
      raw: Map.unmodifiable(json),
    );
  }

  final NearToken min;
  final NearToken? max;
  final Map<String, dynamic> raw;
}

/// NEP-145 storage balance for an account.
class StorageBalance {
  const StorageBalance({
    required this.total,
    required this.available,
    required this.raw,
  });

  factory StorageBalance.fromJson(Map<String, dynamic> json) {
    return StorageBalance(
      total: NearToken.fromYocto(json['total'] as String),
      available: NearToken.fromYocto(json['available'] as String),
      raw: Map.unmodifiable(json),
    );
  }

  final NearToken total;
  final NearToken available;
  final Map<String, dynamic> raw;
}

/// Read-only NEP-145 storage-management helpers.
extension Nep145RpcClient on NearRpcClient {
  /// Calls `storage_balance_bounds` on [contractId].
  Future<RpcResult<StorageBalanceBounds>> storageBalanceBounds({
    required AccountId contractId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: contractId,
      methodName: 'storage_balance_bounds',
      args: const {},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) {
      final json = response.resultAsJson() as Map<String, dynamic>;
      return StorageBalanceBounds.fromJson(json);
    });
  }

  /// Calls `storage_balance_of` on [contractId].
  Future<RpcResult<StorageBalance?>> storageBalanceOf({
    required AccountId contractId,
    required AccountId accountId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: contractId,
      methodName: 'storage_balance_of',
      args: {'account_id': accountId.value},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) {
      final json = response.resultAsJson();
      return json == null
          ? null
          : StorageBalance.fromJson((json as Map).cast<String, dynamic>());
    });
  }
}

/// Transaction-building NEP-145 storage-management helpers.
extension Nep145Account on Account {
  /// Calls `storage_deposit` on [contractId].
  Future<RpcResult<TransactionResponse>> storageDeposit({
    required AccountId contractId,
    required NearToken deposit,
    AccountId? accountId,
    bool? registrationOnly,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: contractId,
      methodName: 'storage_deposit',
      args: {
        if (accountId != null) 'account_id': accountId.value,
        if (registrationOnly != null) 'registration_only': registrationOnly,
      },
      gas: gas,
      deposit: deposit,
      waitUntil: waitUntil,
    );
  }

  /// Calls `storage_withdraw` on [contractId].
  Future<RpcResult<TransactionResponse>> storageWithdraw({
    required AccountId contractId,
    NearToken? amount,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: contractId,
      methodName: 'storage_withdraw',
      args: {if (amount != null) 'amount': amount.yoctoNear.toString()},
      gas: gas,
      deposit: NearToken.oneYocto(),
      waitUntil: waitUntil,
    );
  }

  /// Calls `storage_unregister` on [contractId].
  Future<RpcResult<TransactionResponse>> storageUnregister({
    required AccountId contractId,
    bool? force,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: contractId,
      methodName: 'storage_unregister',
      args: {if (force != null) 'force': force},
      gas: gas,
      deposit: NearToken.oneYocto(),
      waitUntil: waitUntil,
    );
  }
}
