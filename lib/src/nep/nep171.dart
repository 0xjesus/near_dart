import '../account/account.dart';
import '../client/near_rpc_client.dart';
import '../client/responses/transaction_response.dart';
import '../types/block_reference.dart';
import '../types/primitives.dart';
import '../types/rpc_result.dart';

/// NEP-171 NFT contract metadata.
class NonFungibleTokenMetadata {
  const NonFungibleTokenMetadata({
    required this.spec,
    required this.name,
    required this.symbol,
    required this.raw,
    this.icon,
    this.baseUri,
    this.reference,
    this.referenceHash,
  });

  factory NonFungibleTokenMetadata.fromJson(Map<String, dynamic> json) {
    return NonFungibleTokenMetadata(
      spec: json['spec'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      icon: json['icon'] as String?,
      baseUri: json['base_uri'] as String?,
      reference: json['reference'] as String?,
      referenceHash: json['reference_hash'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final String spec;
  final String name;
  final String symbol;
  final String? icon;
  final String? baseUri;
  final String? reference;
  final String? referenceHash;
  final Map<String, dynamic> raw;
}

/// NEP-171 NFT token metadata.
class NftTokenMetadata {
  const NftTokenMetadata({
    required this.raw,
    this.title,
    this.description,
    this.media,
    this.mediaHash,
    this.copies,
    this.issuedAt,
    this.expiresAt,
    this.startsAt,
    this.updatedAt,
    this.extra,
    this.reference,
    this.referenceHash,
  });

  factory NftTokenMetadata.fromJson(Map<String, dynamic> json) {
    return NftTokenMetadata(
      title: json['title'] as String?,
      description: json['description'] as String?,
      media: json['media'] as String?,
      mediaHash: json['media_hash'] as String?,
      copies: json['copies'] as int?,
      issuedAt: json['issued_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      startsAt: json['starts_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      extra: json['extra'] as String?,
      reference: json['reference'] as String?,
      referenceHash: json['reference_hash'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final String? title;
  final String? description;
  final String? media;
  final String? mediaHash;
  final int? copies;
  final String? issuedAt;
  final String? expiresAt;
  final String? startsAt;
  final String? updatedAt;
  final String? extra;
  final String? reference;
  final String? referenceHash;
  final Map<String, dynamic> raw;
}

/// NEP-171 NFT token object.
class NftToken {
  const NftToken({
    required this.tokenId,
    required this.ownerId,
    required this.raw,
    this.metadata,
    this.approvedAccountIds,
  });

  factory NftToken.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    final approved = json['approved_account_ids'];
    return NftToken(
      tokenId: json['token_id'] as String,
      ownerId: AccountId(json['owner_id'] as String),
      metadata: metadata == null
          ? null
          : NftTokenMetadata.fromJson(
              (metadata as Map).cast<String, dynamic>(),
            ),
      approvedAccountIds: approved == null
          ? null
          : (approved as Map).cast<String, dynamic>(),
      raw: Map.unmodifiable(json),
    );
  }

  final String tokenId;
  final AccountId ownerId;
  final NftTokenMetadata? metadata;
  final Map<String, dynamic>? approvedAccountIds;
  final Map<String, dynamic> raw;
}

/// Read-only NEP-171 NFT helpers.
extension Nep171RpcClient on NearRpcClient {
  /// Calls `nft_metadata` on [contractId].
  Future<RpcResult<NonFungibleTokenMetadata>> nftMetadata({
    required AccountId contractId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: contractId,
      methodName: 'nft_metadata',
      args: const {},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) {
      final json = response.resultAsJson() as Map<String, dynamic>;
      return NonFungibleTokenMetadata.fromJson(json);
    });
  }

  /// Calls `nft_token` on [contractId].
  Future<RpcResult<NftToken?>> nftToken({
    required AccountId contractId,
    required String tokenId,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: contractId,
      methodName: 'nft_token',
      args: {'token_id': tokenId},
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) {
      final json = response.resultAsJson();
      return json == null
          ? null
          : NftToken.fromJson((json as Map).cast<String, dynamic>());
    });
  }

  /// Calls `nft_tokens_for_owner` on [contractId].
  Future<RpcResult<List<NftToken>>> nftTokensForOwner({
    required AccountId contractId,
    required AccountId accountId,
    int? fromIndex,
    int? limit,
    BlockReference? blockReference,
  }) async {
    return (await callFunction(
      accountId: contractId,
      methodName: 'nft_tokens_for_owner',
      args: {
        'account_id': accountId.value,
        if (fromIndex != null) 'from_index': fromIndex.toString(),
        if (limit != null) 'limit': limit,
      },
      blockReference:
          blockReference ?? BlockReference.finality(Finality.final_),
    )).map((response) {
      final json = response.resultAsJson() as List;
      return json
          .whereType<Map>()
          .map((m) => NftToken.fromJson(m.cast<String, dynamic>()))
          .toList();
    });
  }
}

/// Transaction-building NEP-171 NFT helpers.
extension Nep171Account on Account {
  /// Calls `nft_transfer` on [contractId].
  Future<RpcResult<TransactionResponse>> nftTransfer({
    required AccountId contractId,
    required AccountId receiverId,
    required String tokenId,
    int? approvalId,
    String? memo,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: contractId,
      methodName: 'nft_transfer',
      args: {
        'receiver_id': receiverId.value,
        'token_id': tokenId,
        if (approvalId != null) 'approval_id': approvalId,
        if (memo != null) 'memo': memo,
      },
      gas: gas,
      deposit: NearToken.oneYocto(),
      waitUntil: waitUntil,
    );
  }

  /// Calls `nft_transfer_call` on [contractId].
  Future<RpcResult<TransactionResponse>> nftTransferCall({
    required AccountId contractId,
    required AccountId receiverId,
    required String tokenId,
    required String msg,
    int? approvalId,
    String? memo,
    BigInt? gas,
    TxExecutionStatus waitUntil = TxExecutionStatus.executedOptimistic,
  }) {
    return callFunction(
      contractId: contractId,
      methodName: 'nft_transfer_call',
      args: {
        'receiver_id': receiverId.value,
        'token_id': tokenId,
        'msg': msg,
        if (approvalId != null) 'approval_id': approvalId,
        if (memo != null) 'memo': memo,
      },
      gas: gas,
      deposit: NearToken.oneYocto(),
      waitUntil: waitUntil,
    );
  }
}
