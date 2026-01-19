import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Response from the `status` RPC method.
///
/// Contains information about the node's status, version, and sync status.
@immutable
class StatusResponse extends Equatable {
  const StatusResponse({
    required this.version,
    required this.chainId,
    required this.protocolVersion,
    required this.latestProtocolVersion,
    required this.rpcAddr,
    required this.syncInfo,
    this.validatorAccountId,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      version: VersionInfo.fromJson(json['version'] as Map<String, dynamic>),
      chainId: json['chain_id'] as String,
      protocolVersion: json['protocol_version'] as int,
      latestProtocolVersion: json['latest_protocol_version'] as int,
      rpcAddr: json['rpc_addr'] as String?,
      syncInfo: SyncInfo.fromJson(json['sync_info'] as Map<String, dynamic>),
      validatorAccountId: json['validator_account_id'] as String?,
    );
  }

  /// The node's version information.
  final VersionInfo version;

  /// The chain ID (e.g., "mainnet", "testnet").
  final String chainId;

  /// The current protocol version.
  final int protocolVersion;

  /// The latest protocol version supported by this node.
  final int latestProtocolVersion;

  /// The RPC address of this node.
  final String? rpcAddr;

  /// Synchronization status information.
  final SyncInfo syncInfo;

  /// The validator account ID, if this node is a validator.
  final String? validatorAccountId;

  @override
  List<Object?> get props => [
        version,
        chainId,
        protocolVersion,
        latestProtocolVersion,
        rpcAddr,
        syncInfo,
        validatorAccountId,
      ];
}

/// Version information for the NEAR node.
@immutable
class VersionInfo extends Equatable {
  const VersionInfo({
    required this.version,
    this.build,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      build: json['build'] as String?,
    );
  }

  /// The version string (e.g., "1.35.0").
  final String version;

  /// The build type (e.g., "stable", "nightly").
  final String? build;

  @override
  List<Object?> get props => [version, build];
}

/// Synchronization status information.
@immutable
class SyncInfo extends Equatable {
  const SyncInfo({
    required this.latestBlockHash,
    required this.latestBlockHeight,
    required this.latestStateRoot,
    required this.latestBlockTime,
    required this.syncing,
    this.earliestBlockHash,
    this.earliestBlockHeight,
    this.earliestBlockTime,
  });

  factory SyncInfo.fromJson(Map<String, dynamic> json) {
    return SyncInfo(
      latestBlockHash: json['latest_block_hash'] as String,
      latestBlockHeight: json['latest_block_height'] as int,
      latestStateRoot: json['latest_state_root'] as String,
      latestBlockTime: json['latest_block_time'] as String,
      syncing: json['syncing'] as bool,
      earliestBlockHash: json['earliest_block_hash'] as String?,
      earliestBlockHeight: json['earliest_block_height'] as int?,
      earliestBlockTime: json['earliest_block_time'] as String?,
    );
  }

  /// Hash of the latest block.
  final String latestBlockHash;

  /// Height of the latest block.
  final int latestBlockHeight;

  /// State root of the latest block.
  final String latestStateRoot;

  /// Timestamp of the latest block.
  final String latestBlockTime;

  /// Whether the node is currently syncing.
  final bool syncing;

  /// Hash of the earliest available block (for archival nodes).
  final String? earliestBlockHash;

  /// Height of the earliest available block.
  final int? earliestBlockHeight;

  /// Timestamp of the earliest available block.
  final String? earliestBlockTime;

  @override
  List<Object?> get props => [
        latestBlockHash,
        latestBlockHeight,
        latestStateRoot,
        latestBlockTime,
        syncing,
        earliestBlockHash,
        earliestBlockHeight,
        earliestBlockTime,
      ];
}
