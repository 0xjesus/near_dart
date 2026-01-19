import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Response from the `chunk` RPC method.
///
/// Contains detailed information about a specific chunk.
@immutable
class ChunkResponse extends Equatable {
  const ChunkResponse({
    required this.author,
    required this.header,
    required this.transactions,
    required this.receipts,
  });

  factory ChunkResponse.fromJson(Map<String, dynamic> json) {
    return ChunkResponse(
      author: json['author'] as String,
      header: ChunkHeaderView.fromJson(json['header'] as Map<String, dynamic>),
      transactions: (json['transactions'] as List<dynamic>).toList(),
      receipts: (json['receipts'] as List<dynamic>).toList(),
    );
  }

  /// The chunk producer's account ID.
  final String author;

  /// The chunk header.
  final ChunkHeaderView header;

  /// Transactions in this chunk.
  final List<dynamic> transactions;

  /// Receipts in this chunk.
  final List<dynamic> receipts;

  @override
  List<Object?> get props => [author, header, transactions, receipts];
}

/// Detailed chunk header view.
@immutable
class ChunkHeaderView extends Equatable {
  const ChunkHeaderView({
    required this.chunkHash,
    required this.prevBlockHash,
    required this.outcomeRoot,
    required this.prevStateRoot,
    required this.encodedMerkleRoot,
    required this.encodedLength,
    required this.heightCreated,
    required this.heightIncluded,
    required this.shardId,
    required this.gasUsed,
    required this.gasLimit,
    required this.balanceBurnt,
    required this.outgoingReceiptsRoot,
    required this.txRoot,
    required this.validatorProposals,
    required this.signature,
  });

  factory ChunkHeaderView.fromJson(Map<String, dynamic> json) {
    return ChunkHeaderView(
      chunkHash: json['chunk_hash'] as String,
      prevBlockHash: json['prev_block_hash'] as String,
      outcomeRoot: json['outcome_root'] as String,
      prevStateRoot: json['prev_state_root'] as String,
      encodedMerkleRoot: json['encoded_merkle_root'] as String,
      encodedLength: json['encoded_length'] as int,
      heightCreated: json['height_created'] as int,
      heightIncluded: json['height_included'] as int,
      shardId: json['shard_id'] as int,
      gasUsed: json['gas_used'] as int,
      gasLimit: json['gas_limit'] as int,
      balanceBurnt: json['balance_burnt'] as String,
      outgoingReceiptsRoot: json['outgoing_receipts_root'] as String,
      txRoot: json['tx_root'] as String,
      validatorProposals: (json['validator_proposals'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      signature: json['signature'] as String,
    );
  }

  final String chunkHash;
  final String prevBlockHash;
  final String outcomeRoot;
  final String prevStateRoot;
  final String encodedMerkleRoot;
  final int encodedLength;
  final int heightCreated;
  final int heightIncluded;
  final int shardId;
  final int gasUsed;
  final int gasLimit;
  final String balanceBurnt;
  final String outgoingReceiptsRoot;
  final String txRoot;
  final List<Map<String, dynamic>> validatorProposals;
  final String signature;

  @override
  List<Object?> get props => [
        chunkHash,
        prevBlockHash,
        outcomeRoot,
        prevStateRoot,
        encodedMerkleRoot,
        encodedLength,
        heightCreated,
        heightIncluded,
        shardId,
        gasUsed,
        gasLimit,
        balanceBurnt,
        outgoingReceiptsRoot,
        txRoot,
        validatorProposals,
        signature,
      ];
}
