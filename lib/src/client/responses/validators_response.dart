import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_flutter/near_flutter.dart';

/// Response from the `validators` RPC method.
///
/// Contains information about current and next epoch validators.
@immutable
class ValidatorsResponse extends Equatable {
  const ValidatorsResponse({
    required this.epochStartHeight,
    required this.currentValidators,
    required this.nextValidators,
    required this.currentProposals,
    required this.epochHeight,
  });

  factory ValidatorsResponse.fromJson(Map<String, dynamic> json) {
    return ValidatorsResponse(
      epochStartHeight: json['epoch_start_height'] as int,
      currentValidators: (json['current_validators'] as List<dynamic>)
          .map((e) => ValidatorInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextValidators: (json['next_validators'] as List<dynamic>)
          .map((e) => ValidatorInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentProposals: (json['current_proposals'] as List<dynamic>)
          .map((e) => ValidatorProposal.fromJson(e as Map<String, dynamic>))
          .toList(),
      epochHeight: json['epoch_height'] as int,
    );
  }

  /// Block height at which the current epoch started.
  final int epochStartHeight;

  /// Current epoch validators.
  final List<ValidatorInfo> currentValidators;

  /// Validators for the next epoch.
  final List<ValidatorInfo> nextValidators;

  /// Current staking proposals.
  final List<ValidatorProposal> currentProposals;

  /// Current epoch height.
  final int epochHeight;

  @override
  List<Object?> get props => [
        epochStartHeight,
        currentValidators,
        nextValidators,
        currentProposals,
        epochHeight,
      ];
}

/// Information about a validator.
@immutable
class ValidatorInfo extends Equatable {
  const ValidatorInfo({
    required this.accountId,
    required this.publicKey,
    required this.stake,
    this.isSlashed = false,
    this.numProducedBlocks,
    this.numExpectedBlocks,
    this.numProducedChunks,
    this.numExpectedChunks,
  });

  factory ValidatorInfo.fromJson(Map<String, dynamic> json) {
    return ValidatorInfo(
      accountId: json['account_id'] as String,
      publicKey: json['public_key'] as String,
      stake: NearToken.fromYocto(json['stake'] as String),
      isSlashed: json['is_slashed'] as bool? ?? false,
      numProducedBlocks: json['num_produced_blocks'] as int?,
      numExpectedBlocks: json['num_expected_blocks'] as int?,
      numProducedChunks: json['num_produced_chunks'] as int?,
      numExpectedChunks: json['num_expected_chunks'] as int?,
    );
  }

  /// The validator's account ID.
  final String accountId;

  /// The validator's public key.
  final String publicKey;

  /// The validator's stake in yoctoNEAR.
  final NearToken stake;

  /// Whether this validator has been slashed.
  final bool isSlashed;

  /// Number of blocks produced by this validator.
  final int? numProducedBlocks;

  /// Number of blocks expected from this validator.
  final int? numExpectedBlocks;

  /// Number of chunks produced by this validator.
  final int? numProducedChunks;

  /// Number of chunks expected from this validator.
  final int? numExpectedChunks;

  @override
  List<Object?> get props => [
        accountId,
        publicKey,
        stake,
        isSlashed,
        numProducedBlocks,
        numExpectedBlocks,
        numProducedChunks,
        numExpectedChunks,
      ];
}

/// A staking proposal from a validator.
@immutable
class ValidatorProposal extends Equatable {
  const ValidatorProposal({
    required this.accountId,
    required this.publicKey,
    required this.stake,
  });

  factory ValidatorProposal.fromJson(Map<String, dynamic> json) {
    return ValidatorProposal(
      accountId: json['account_id'] as String,
      publicKey: json['public_key'] as String,
      stake: NearToken.fromYocto(json['stake'] as String),
    );
  }

  /// The validator's account ID.
  final String accountId;

  /// The validator's public key.
  final String publicKey;

  /// The proposed stake.
  final NearToken stake;

  @override
  List<Object?> get props => [accountId, publicKey, stake];
}
