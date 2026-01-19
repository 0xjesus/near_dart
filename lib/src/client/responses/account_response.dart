import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

/// Response from the `query` RPC method when requesting account information.
///
/// Contains the account's balance, storage usage, and code hash.
@immutable
class AccountView extends Equatable {
  const AccountView({
    required this.amount,
    required this.locked,
    required this.codeHash,
    required this.storageUsage,
    this.storagePaidAt,
    required this.blockHeight,
    required this.blockHash,
  });

  factory AccountView.fromJson(Map<String, dynamic> json) {
    return AccountView(
      amount: NearToken.fromYocto(json['amount'] as String),
      locked: NearToken.fromYocto(json['locked'] as String),
      codeHash: CryptoHash(json['code_hash'] as String),
      storageUsage: json['storage_usage'] as int,
      storagePaidAt: json['storage_paid_at'] as int?,
      blockHeight: json['block_height'] as int,
      blockHash: json['block_hash'] as String,
    );
  }

  /// The account's liquid balance in yoctoNEAR.
  final NearToken amount;

  /// The account's locked (staked) balance in yoctoNEAR.
  final NearToken locked;

  /// Hash of the contract code deployed to this account.
  ///
  /// A hash of all 1s indicates no contract is deployed.
  final CryptoHash codeHash;

  /// Amount of storage used by this account in bytes.
  final int storageUsage;

  /// Deprecated: Block height at which storage was last paid.
  final int? storagePaidAt;

  /// Block height at which this view was taken.
  final int blockHeight;

  /// Block hash at which this view was taken.
  final String blockHash;

  /// Returns true if this account has a contract deployed.
  bool get hasContract => codeHash.value != '11111111111111111111111111111111';

  /// Returns the total balance (liquid + locked).
  BigInt get totalBalance => amount.yoctoNear + locked.yoctoNear;

  @override
  List<Object?> get props => [
        amount,
        locked,
        codeHash,
        storageUsage,
        storagePaidAt,
        blockHeight,
        blockHash,
      ];
}

/// Response from the `query` RPC method when requesting access key information.
@immutable
class AccessKeyView extends Equatable {
  const AccessKeyView({
    required this.nonce,
    required this.permission,
    required this.blockHeight,
    required this.blockHash,
  });

  factory AccessKeyView.fromJson(Map<String, dynamic> json) {
    return AccessKeyView(
      nonce: json['nonce'] as int,
      permission: AccessKeyPermissionView.fromJson(json['permission']),
      blockHeight: json['block_height'] as int,
      blockHash: json['block_hash'] as String,
    );
  }

  /// The nonce for this access key.
  final int nonce;

  /// The permission scope for this access key.
  final AccessKeyPermissionView permission;

  /// Block height at which this view was taken.
  final int blockHeight;

  /// Block hash at which this view was taken.
  final String blockHash;

  @override
  List<Object?> get props => [nonce, permission, blockHeight, blockHash];
}

/// Access key permission view.
@immutable
sealed class AccessKeyPermissionView extends Equatable {
  const AccessKeyPermissionView();

  factory AccessKeyPermissionView.fromJson(dynamic json) {
    if (json == 'FullAccess') {
      return const FullAccessPermissionView();
    }
    if (json is Map<String, dynamic> && json.containsKey('FunctionCall')) {
      return FunctionCallPermissionView.fromJson(
        json['FunctionCall'] as Map<String, dynamic>,
      );
    }
    throw ArgumentError.value(json, 'json', 'Unknown permission type');
  }
}

/// Full access permission.
@immutable
class FullAccessPermissionView extends AccessKeyPermissionView {
  const FullAccessPermissionView();

  @override
  List<Object?> get props => [];
}

/// Function call permission with restrictions.
@immutable
class FunctionCallPermissionView extends AccessKeyPermissionView {
  const FunctionCallPermissionView({
    this.allowance,
    required this.receiverId,
    required this.methodNames,
  });

  factory FunctionCallPermissionView.fromJson(Map<String, dynamic> json) {
    return FunctionCallPermissionView(
      allowance: json['allowance'] != null
          ? NearToken.fromYocto(json['allowance'] as String)
          : null,
      receiverId: json['receiver_id'] as String,
      methodNames: (json['method_names'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  /// Maximum allowance for this key, or null for unlimited.
  final NearToken? allowance;

  /// The receiver account this key can call.
  final String receiverId;

  /// The methods this key can call, or empty for all methods.
  final List<String> methodNames;

  @override
  List<Object?> get props => [allowance, receiverId, methodNames];
}

/// Response from view_access_key_list query.
@immutable
class AccessKeyListResponse extends Equatable {
  const AccessKeyListResponse({
    required this.keys,
    required this.blockHeight,
    required this.blockHash,
  });

  factory AccessKeyListResponse.fromJson(Map<String, dynamic> json) {
    return AccessKeyListResponse(
      keys: (json['keys'] as List<dynamic>)
          .map((e) => AccessKeyInfoView.fromJson(e as Map<String, dynamic>))
          .toList(),
      blockHeight: json['block_height'] as int,
      blockHash: json['block_hash'] as String,
    );
  }

  /// List of access keys for the account.
  final List<AccessKeyInfoView> keys;

  /// Block height at which this view was taken.
  final int blockHeight;

  /// Block hash at which this view was taken.
  final String blockHash;

  @override
  List<Object?> get props => [keys, blockHeight, blockHash];
}

/// Information about an access key including its public key.
@immutable
class AccessKeyInfoView extends Equatable {
  const AccessKeyInfoView({
    required this.publicKey,
    required this.accessKey,
  });

  factory AccessKeyInfoView.fromJson(Map<String, dynamic> json) {
    return AccessKeyInfoView(
      publicKey: json['public_key'] as String,
      accessKey: AccessKeyDetailView.fromJson(
        json['access_key'] as Map<String, dynamic>,
      ),
    );
  }

  /// The public key.
  final String publicKey;

  /// The access key details.
  final AccessKeyDetailView accessKey;

  @override
  List<Object?> get props => [publicKey, accessKey];
}

/// Detailed access key information.
@immutable
class AccessKeyDetailView extends Equatable {
  const AccessKeyDetailView({
    required this.nonce,
    required this.permission,
  });

  factory AccessKeyDetailView.fromJson(Map<String, dynamic> json) {
    return AccessKeyDetailView(
      nonce: json['nonce'] as int,
      permission: AccessKeyPermissionView.fromJson(json['permission']),
    );
  }

  /// The nonce for this access key.
  final int nonce;

  /// The permission scope.
  final AccessKeyPermissionView permission;

  @override
  List<Object?> get props => [nonce, permission];
}

/// Response from view_code query.
@immutable
class ContractCodeResponse extends Equatable {
  const ContractCodeResponse({
    required this.codeBase64,
    required this.hash,
    required this.blockHeight,
    required this.blockHash,
  });

  factory ContractCodeResponse.fromJson(Map<String, dynamic> json) {
    return ContractCodeResponse(
      codeBase64: json['code_base64'] as String,
      hash: json['hash'] as String,
      blockHeight: json['block_height'] as int,
      blockHash: json['block_hash'] as String,
    );
  }

  /// Base64-encoded WASM bytecode.
  final String codeBase64;

  /// Hash of the code.
  final String hash;

  /// Block height at which this view was taken.
  final int blockHeight;

  /// Block hash at which this view was taken.
  final String blockHash;

  @override
  List<Object?> get props => [codeBase64, hash, blockHeight, blockHash];
}

/// Response from view_state query.
@immutable
class ContractStateResponse extends Equatable {
  const ContractStateResponse({
    required this.values,
    required this.blockHeight,
    required this.blockHash,
  });

  factory ContractStateResponse.fromJson(Map<String, dynamic> json) {
    return ContractStateResponse(
      values: (json['values'] as List<dynamic>)
          .map((e) => StateItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      blockHeight: json['block_height'] as int,
      blockHash: json['block_hash'] as String,
    );
  }

  /// The key-value pairs in the contract state.
  final List<StateItem> values;

  /// Block height at which this view was taken.
  final int blockHeight;

  /// Block hash at which this view was taken.
  final String blockHash;

  @override
  List<Object?> get props => [values, blockHeight, blockHash];
}

/// A single key-value pair from contract state.
@immutable
class StateItem extends Equatable {
  const StateItem({
    required this.key,
    required this.value,
  });

  factory StateItem.fromJson(Map<String, dynamic> json) {
    return StateItem(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  /// Base64-encoded key.
  final String key;

  /// Base64-encoded value.
  final String value;

  @override
  List<Object?> get props => [key, value];
}
