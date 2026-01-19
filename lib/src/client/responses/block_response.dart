import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Response from the `block` RPC method.
///
/// Contains detailed information about a block including its header and chunks.
@immutable
class BlockResponse extends Equatable {
  const BlockResponse({
    required this.author,
    required this.header,
    required this.chunks,
  });

  factory BlockResponse.fromJson(Map<String, dynamic> json) {
    return BlockResponse(
      author: json['author'] as String,
      header: BlockHeader.fromJson(json['header'] as Map<String, dynamic>),
      chunks: (json['chunks'] as List<dynamic>)
          .map((e) => ChunkHeader.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The account ID of the block producer.
  final String author;

  /// The block header.
  final BlockHeader header;

  /// The chunk headers included in this block.
  final List<ChunkHeader> chunks;

  @override
  List<Object?> get props => [author, header, chunks];
}

/// Block header information.
@immutable
class BlockHeader extends Equatable {
  const BlockHeader({
    required this.height,
    required this.epochId,
    required this.nextEpochId,
    required this.hash,
    required this.prevHash,
    required this.prevStateRoot,
    required this.chunkReceiptsRoot,
    required this.chunkHeadersRoot,
    required this.chunkTxRoot,
    required this.outcomeRoot,
    required this.chunksIncluded,
    required this.challengesRoot,
    required this.timestamp,
    required this.timestampNanosec,
    required this.randomValue,
    required this.gasPrice,
    required this.blockOrdinal,
    required this.totalSupply,
    required this.lastFinalBlock,
    required this.lastDsFinalBlock,
    required this.nextBpHash,
    required this.blockMerkleRoot,
    required this.latestProtocolVersion,
    required this.signature,
  });

  factory BlockHeader.fromJson(Map<String, dynamic> json) {
    return BlockHeader(
      height: json['height'] as int,
      epochId: json['epoch_id'] as String,
      nextEpochId: json['next_epoch_id'] as String,
      hash: json['hash'] as String,
      prevHash: json['prev_hash'] as String,
      prevStateRoot: json['prev_state_root'] as String,
      chunkReceiptsRoot: json['chunk_receipts_root'] as String,
      chunkHeadersRoot: json['chunk_headers_root'] as String,
      chunkTxRoot: json['chunk_tx_root'] as String,
      outcomeRoot: json['outcome_root'] as String,
      chunksIncluded: json['chunks_included'] as int,
      challengesRoot: json['challenges_root'] as String,
      timestamp: json['timestamp'] as int,
      timestampNanosec: json['timestamp_nanosec'] as String,
      randomValue: json['random_value'] as String,
      gasPrice: json['gas_price'] as String,
      blockOrdinal: json['block_ordinal'] as int?,
      totalSupply: json['total_supply'] as String,
      lastFinalBlock: json['last_final_block'] as String,
      lastDsFinalBlock: json['last_ds_final_block'] as String,
      nextBpHash: json['next_bp_hash'] as String,
      blockMerkleRoot: json['block_merkle_root'] as String,
      latestProtocolVersion: json['latest_protocol_version'] as int,
      signature: json['signature'] as String,
    );
  }

  /// The block height.
  final int height;

  /// The epoch ID this block belongs to.
  final String epochId;

  /// The next epoch ID.
  final String nextEpochId;

  /// The hash of this block.
  final String hash;

  /// The hash of the previous block.
  final String prevHash;

  /// The state root of the previous block.
  final String prevStateRoot;

  /// The root of chunk receipts.
  final String chunkReceiptsRoot;

  /// The root of chunk headers.
  final String chunkHeadersRoot;

  /// The root of chunk transactions.
  final String chunkTxRoot;

  /// The root of outcomes.
  final String outcomeRoot;

  /// Number of chunks included in this block.
  final int chunksIncluded;

  /// The root of challenges.
  final String challengesRoot;

  /// Block timestamp in nanoseconds since epoch.
  final int timestamp;

  /// Block timestamp as a string.
  final String timestampNanosec;

  /// Random value for this block.
  final String randomValue;

  /// Gas price for this block.
  final String gasPrice;

  /// Block ordinal within the epoch.
  final int? blockOrdinal;

  /// Total NEAR token supply.
  final String totalSupply;

  /// Hash of the last final block.
  final String lastFinalBlock;

  /// Hash of the last doomslug final block.
  final String lastDsFinalBlock;

  /// Hash of the next block producers.
  final String nextBpHash;

  /// Merkle root of the block.
  final String blockMerkleRoot;

  /// Protocol version at this block.
  final int latestProtocolVersion;

  /// Block producer's signature.
  final String signature;

  @override
  List<Object?> get props => [
        height,
        epochId,
        nextEpochId,
        hash,
        prevHash,
        prevStateRoot,
        chunkReceiptsRoot,
        chunkHeadersRoot,
        chunkTxRoot,
        outcomeRoot,
        chunksIncluded,
        challengesRoot,
        timestamp,
        timestampNanosec,
        randomValue,
        gasPrice,
        blockOrdinal,
        totalSupply,
        lastFinalBlock,
        lastDsFinalBlock,
        nextBpHash,
        blockMerkleRoot,
        latestProtocolVersion,
        signature,
      ];
}

/// Chunk header information.
@immutable
class ChunkHeader extends Equatable {
  const ChunkHeader({
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
    required this.signature,
  });

  factory ChunkHeader.fromJson(Map<String, dynamic> json) {
    return ChunkHeader(
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
      signature: json['signature'] as String,
    );
  }

  /// Hash of the chunk.
  final String chunkHash;

  /// Hash of the previous block.
  final String prevBlockHash;

  /// Outcome root for this chunk.
  final String outcomeRoot;

  /// Previous state root.
  final String prevStateRoot;

  /// Encoded merkle root.
  final String encodedMerkleRoot;

  /// Encoded length of the chunk.
  final int encodedLength;

  /// Height at which this chunk was created.
  final int heightCreated;

  /// Height at which this chunk was included.
  final int heightIncluded;

  /// The shard ID this chunk belongs to.
  final int shardId;

  /// Gas used by this chunk.
  final int gasUsed;

  /// Gas limit for this chunk.
  final int gasLimit;

  /// NEAR tokens burnt in this chunk.
  final String balanceBurnt;

  /// Outgoing receipts root.
  final String outgoingReceiptsRoot;

  /// Transaction root.
  final String txRoot;

  /// Chunk producer's signature.
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
        signature,
      ];
}
