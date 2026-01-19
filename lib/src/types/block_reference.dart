import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'primitives.dart';

/// Finality options for querying the blockchain.
///
/// - [optimistic]: Use the latest block regardless of finality.
/// - [final_]: Use the latest finalized block (recommended for most queries).
enum Finality {
  /// Queries the most recent block, which may still be reorganized.
  optimistic,

  /// Queries the most recent finalized block (irreversible).
  final_,
}

/// Extension to convert Finality to JSON string.
extension FinalityJson on Finality {
  /// Converts this finality to its JSON representation.
  String toJson() {
    switch (this) {
      case Finality.optimistic:
        return 'optimistic';
      case Finality.final_:
        return 'final';
    }
  }
}

/// Specifies how to reference a block in RPC queries.
///
/// There are three ways to reference a block:
/// 1. By finality: [BlockReference.finality]
/// 2. By block height: [BlockReference.blockId]
/// 3. By block hash: [BlockReference.blockHash]
@immutable
sealed class BlockReference extends Equatable {
  const BlockReference();

  /// Creates a reference by finality level.
  factory BlockReference.finality(Finality finality) = FinalityBlockReference;

  /// Creates a reference by block height.
  factory BlockReference.blockId(int blockHeight) = HeightBlockReference;

  /// Creates a reference by block hash.
  factory BlockReference.blockHash(CryptoHash hash) = HashBlockReference;

  /// Converts this reference to a JSON map.
  Map<String, dynamic> toJson();
}

/// References a block by finality level.
@immutable
class FinalityBlockReference extends BlockReference {
  /// Creates a finality block reference.
  const FinalityBlockReference(this.finality);

  /// The finality level to query.
  final Finality finality;

  @override
  Map<String, dynamic> toJson() => {'finality': finality.toJson()};

  @override
  List<Object?> get props => [finality];
}

/// References a block by height.
@immutable
class HeightBlockReference extends BlockReference {
  /// Creates a block height reference.
  const HeightBlockReference(this.blockHeight);

  /// The block height.
  final int blockHeight;

  @override
  Map<String, dynamic> toJson() => {'block_id': blockHeight};

  @override
  List<Object?> get props => [blockHeight];
}

/// References a block by hash.
@immutable
class HashBlockReference extends BlockReference {
  /// Creates a block hash reference.
  const HashBlockReference(this.blockHash);

  /// The block hash.
  final CryptoHash blockHash;

  @override
  Map<String, dynamic> toJson() => {'block_id': blockHash.toJson()};

  @override
  List<Object?> get props => [blockHash];
}
