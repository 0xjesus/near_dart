import '../account/account.dart';
import '../client/near_rpc_client.dart';
import '../client/responses/transaction_response.dart';
import '../types/block_reference.dart';
import '../types/primitives.dart';
import '../types/rpc_result.dart';

/// NEP-141 fungible-token metadata.
class FungibleTokenMetadata {
  const FungibleTokenMetadata({
    required this.spec,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.raw,
    this.icon,
    this.reference,
    this.referenceHash,
  });

  factory FungibleTokenMetadata.fromJson(Map<String, dynamic> json) {
    return FungibleTokenMetadata(
      spec: json['spec'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      icon: json['icon'] as String?,
      reference: json['reference'] as String?,
      referenceHash: json['reference_hash'] as String?,
      decimals: json['decimals'] as int,
      raw: Map.unmodifiable(json),
    );
  }

  final String spec;
  final String name;
  final String symbol;
  final String? icon;
  final String? reference;
  final String? referenceHash;
  final int decimals;
  final Map<String, dynamic> raw;
}

/// Read-only NEP-141 helpers.
extension Nep141RpcClient on NearRpcClient {
  /// Calls `ft_metadata` on [tokenId].
  Future<RpcResult<FungibleTokenMetadata>> ftMetadata({
    required AccountId tokenId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: tokenId,
      methodName: 'ft_metadata',
      args: const {},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) {
      final json = response.resultAsJson() as Map<String, dynamic>;
      return FungibleTokenMetadata.fromJson(json);
    });
  }

  /// Calls `ft_total_supply` on [tokenId].
  Future<RpcResult<BigInt>> ftTotalSupply({
    required AccountId tokenId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: tokenId,
      methodName: 'ft_total_supply',
      args: const {},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) => BigInt.parse(response.resultAsJson() as String));
  }

  /// Calls `ft_balance_of` for [accountId] on [tokenId].
  Future<RpcResult<BigInt>> ftBalanceOf({
    required AccountId tokenId,
    required AccountId accountId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: tokenId,
      methodName: 'ft_balance_of',
      args: {'account_id': accountId.value},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) => BigInt.parse(response.resultAsJson() as String));
  }
}

/// Transaction-building NEP-141 helpers.
extension Nep141Account on Account {
  /// Calls `ft_transfer` on [tokenId].
  ///
  /// NEP-141 requires exactly 1 yoctoNEAR attached to prove full-access-key
  /// intent.
  Future<RpcResult<TransactionResponse>> ftTransfer({
    required AccountId tokenId,
    required AccountId receiverId,
    required BigInt amount,
    String? memo,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: tokenId,
      methodName: 'ft_transfer',
      args: {
        'receiver_id': receiverId.value,
        'amount': amount.toString(),
        if (memo != null) 'memo': memo,
      },
      gas: gas,
      deposit: NearToken.oneYocto(),
      waitUntil: waitUntil,
    );
  }

  /// Calls `ft_transfer_call` on [tokenId].
  Future<RpcResult<TransactionResponse>> ftTransferCall({
    required AccountId tokenId,
    required AccountId receiverId,
    required BigInt amount,
    required String msg,
    String? memo,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: tokenId,
      methodName: 'ft_transfer_call',
      args: {
        'receiver_id': receiverId.value,
        'amount': amount.toString(),
        'msg': msg,
        if (memo != null) 'memo': memo,
      },
      gas: gas,
      deposit: NearToken.oneYocto(),
      waitUntil: waitUntil,
    );
  }
}
