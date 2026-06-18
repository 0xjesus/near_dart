// GENERATED CODE — DO NOT EDIT BY HAND.
// Source: nearcore OpenAPI 1.2.11
// Regenerate: dart run tool/generate.dart
//
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, prefer_const_constructors

/// Generated from `AccessKey`.
class AccessKey {
  const AccessKey({this.nonce, this.permission});

  factory AccessKey.fromJson(Map<String, dynamic> json) => AccessKey(
    nonce: json[r'nonce'] == null ? null : (json[r'nonce'] as num).toInt(),
    permission: json[r'permission'] == null
        ? null
        : AccessKeyPermission.fromJson(json[r'permission']),
  );

  final int? nonce;
  final AccessKeyPermission? permission;

  Map<String, dynamic> toJson() => {
    if (nonce != null) r'nonce': nonce,
    if (permission != null) r'permission': permission?.toJson(),
  };
}

/// Generated from `AccessKeyCreationConfigView`.
class AccessKeyCreationConfigView {
  const AccessKeyCreationConfigView({
    this.full_access_cost,
    this.function_call_cost,
    this.function_call_cost_per_byte,
  });

  factory AccessKeyCreationConfigView.fromJson(Map<String, dynamic> json) =>
      AccessKeyCreationConfigView(
        full_access_cost: json[r'full_access_cost'] == null
            ? null
            : Fee.fromJson(json[r'full_access_cost']),
        function_call_cost: json[r'function_call_cost'] == null
            ? null
            : Fee.fromJson(json[r'function_call_cost']),
        function_call_cost_per_byte:
            json[r'function_call_cost_per_byte'] == null
            ? null
            : Fee.fromJson(json[r'function_call_cost_per_byte']),
      );

  final Fee? full_access_cost;
  final Fee? function_call_cost;
  final Fee? function_call_cost_per_byte;

  Map<String, dynamic> toJson() => {
    if (full_access_cost != null)
      r'full_access_cost': full_access_cost?.toJson(),
    if (function_call_cost != null)
      r'function_call_cost': function_call_cost?.toJson(),
    if (function_call_cost_per_byte != null)
      r'function_call_cost_per_byte': function_call_cost_per_byte?.toJson(),
  };
}

/// Generated from `AccessKeyInfoView`.
class AccessKeyInfoView {
  const AccessKeyInfoView({this.access_key, this.public_key});

  factory AccessKeyInfoView.fromJson(Map<String, dynamic> json) =>
      AccessKeyInfoView(
        access_key: json[r'access_key'] == null
            ? null
            : AccessKeyView.fromJson(json[r'access_key']),
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKeyHandle,
      );

  final AccessKeyView? access_key;
  final PublicKeyHandle? public_key;

  Map<String, dynamic> toJson() => {
    if (access_key != null) r'access_key': access_key?.toJson(),
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `AccessKeyList`.
class AccessKeyList {
  const AccessKeyList({this.keys});

  factory AccessKeyList.fromJson(Map<String, dynamic> json) => AccessKeyList(
    keys: json[r'keys'] == null
        ? null
        : (json[r'keys'] as List)
              .map<AccessKeyInfoView>((e) => AccessKeyInfoView.fromJson(e))
              .toList(),
  );

  final List<AccessKeyInfoView>? keys;

  Map<String, dynamic> toJson() => {
    if (keys != null) r'keys': keys?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `AccessKeyPermission`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class AccessKeyPermission {
  const AccessKeyPermission(this.json);
  factory AccessKeyPermission.fromJson(dynamic json) =>
      AccessKeyPermission(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `AccessKeyPermissionView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class AccessKeyPermissionView {
  const AccessKeyPermissionView(this.json);
  factory AccessKeyPermissionView.fromJson(dynamic json) =>
      AccessKeyPermissionView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `AccessKeyView`.
class AccessKeyView {
  const AccessKeyView({this.nonce, this.permission});

  factory AccessKeyView.fromJson(Map<String, dynamic> json) => AccessKeyView(
    nonce: json[r'nonce'] == null ? null : (json[r'nonce'] as num).toInt(),
    permission: json[r'permission'] == null
        ? null
        : AccessKeyPermissionView.fromJson(json[r'permission']),
  );

  final int? nonce;
  final AccessKeyPermissionView? permission;

  Map<String, dynamic> toJson() => {
    if (nonce != null) r'nonce': nonce,
    if (permission != null) r'permission': permission?.toJson(),
  };
}

/// Union type generated from `AccountContractView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class AccountContractView {
  const AccountContractView(this.json);
  factory AccountContractView.fromJson(dynamic json) =>
      AccountContractView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `AccountCreationConfigView`.
class AccountCreationConfigView {
  const AccountCreationConfigView({
    this.min_allowed_top_level_account_length,
    this.registrar_account_id,
  });

  factory AccountCreationConfigView.fromJson(Map<String, dynamic> json) =>
      AccountCreationConfigView(
        min_allowed_top_level_account_length:
            json[r'min_allowed_top_level_account_length'] == null
            ? null
            : (json[r'min_allowed_top_level_account_length'] as num).toInt(),
        registrar_account_id: json[r'registrar_account_id'] == null
            ? null
            : json[r'registrar_account_id'] as AccountId,
      );

  final int? min_allowed_top_level_account_length;
  final AccountId? registrar_account_id;

  Map<String, dynamic> toJson() => {
    if (min_allowed_top_level_account_length != null)
      r'min_allowed_top_level_account_length':
          min_allowed_top_level_account_length,
    if (registrar_account_id != null)
      r'registrar_account_id': registrar_account_id,
  };
}

/// Generated from `AccountDataView`.
class AccountDataView {
  const AccountDataView({
    this.account_key,
    this.peer_id,
    this.proxies,
    this.timestamp,
  });

  factory AccountDataView.fromJson(
    Map<String, dynamic> json,
  ) => AccountDataView(
    account_key: json[r'account_key'] == null
        ? null
        : json[r'account_key'] as PublicKey,
    peer_id: json[r'peer_id'] == null ? null : json[r'peer_id'] as PublicKey,
    proxies: json[r'proxies'] == null
        ? null
        : (json[r'proxies'] as List)
              .map<Tier1ProxyView>((e) => Tier1ProxyView.fromJson(e))
              .toList(),
    timestamp: json[r'timestamp'] == null ? null : json[r'timestamp'] as String,
  );

  final PublicKey? account_key;
  final PublicKey? peer_id;
  final List<Tier1ProxyView>? proxies;
  final String? timestamp;

  Map<String, dynamic> toJson() => {
    if (account_key != null) r'account_key': account_key,
    if (peer_id != null) r'peer_id': peer_id,
    if (proxies != null) r'proxies': proxies?.map((e) => e.toJson()).toList(),
    if (timestamp != null) r'timestamp': timestamp,
  };
}

/// Alias for `AccountId`.
typedef AccountId = String;

/// Alias for `AccountIdValidityRulesVersion`.
typedef AccountIdValidityRulesVersion = int;

/// Generated from `AccountInfo`.
class AccountInfo {
  const AccountInfo({this.account_id, this.amount, this.public_key});

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
    account_id: json[r'account_id'] == null
        ? null
        : json[r'account_id'] as AccountId,
    amount: json[r'amount'] == null ? null : json[r'amount'] as NearToken,
    public_key: json[r'public_key'] == null
        ? null
        : json[r'public_key'] as PublicKey,
  );

  final AccountId? account_id;
  final NearToken? amount;
  final PublicKey? public_key;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (amount != null) r'amount': amount,
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `AccountView`.
class AccountView {
  const AccountView({
    this.amount,
    this.code_hash,
    this.global_contract_account_id,
    this.global_contract_hash,
    this.locked,
    this.storage_paid_at,
    this.storage_usage,
  });

  factory AccountView.fromJson(Map<String, dynamic> json) => AccountView(
    amount: json[r'amount'] == null ? null : json[r'amount'] as NearToken,
    code_hash: json[r'code_hash'] == null
        ? null
        : json[r'code_hash'] as CryptoHash,
    global_contract_account_id: json[r'global_contract_account_id'] == null
        ? null
        : json[r'global_contract_account_id'],
    global_contract_hash: json[r'global_contract_hash'] == null
        ? null
        : json[r'global_contract_hash'],
    locked: json[r'locked'] == null ? null : json[r'locked'] as NearToken,
    storage_paid_at: json[r'storage_paid_at'] == null
        ? null
        : (json[r'storage_paid_at'] as num).toInt(),
    storage_usage: json[r'storage_usage'] == null
        ? null
        : (json[r'storage_usage'] as num).toInt(),
  );

  final NearToken? amount;
  final CryptoHash? code_hash;
  final dynamic? global_contract_account_id;
  final dynamic? global_contract_hash;
  final NearToken? locked;
  final int? storage_paid_at;
  final int? storage_usage;

  Map<String, dynamic> toJson() => {
    if (amount != null) r'amount': amount,
    if (code_hash != null) r'code_hash': code_hash,
    if (global_contract_account_id != null)
      r'global_contract_account_id': global_contract_account_id,
    if (global_contract_hash != null)
      r'global_contract_hash': global_contract_hash,
    if (locked != null) r'locked': locked,
    if (storage_paid_at != null) r'storage_paid_at': storage_paid_at,
    if (storage_usage != null) r'storage_usage': storage_usage,
  };
}

/// Generated from `AccountWithPublicKey`.
class AccountWithPublicKey {
  const AccountWithPublicKey({this.account_id, this.public_key});

  factory AccountWithPublicKey.fromJson(Map<String, dynamic> json) =>
      AccountWithPublicKey(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
      );

  final AccountId? account_id;
  final PublicKey? public_key;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `ActionCreationConfigView`.
class ActionCreationConfigView {
  const ActionCreationConfigView({
    this.add_key_cost,
    this.create_account_cost,
    this.delegate_cost,
    this.delete_account_cost,
    this.delete_key_cost,
    this.deploy_contract_cost,
    this.deploy_contract_cost_per_byte,
    this.function_call_cost,
    this.function_call_cost_per_byte,
    this.stake_cost,
    this.transfer_cost,
  });

  factory ActionCreationConfigView.fromJson(Map<String, dynamic> json) =>
      ActionCreationConfigView(
        add_key_cost: json[r'add_key_cost'] == null
            ? null
            : AccessKeyCreationConfigView.fromJson(json[r'add_key_cost']),
        create_account_cost: json[r'create_account_cost'] == null
            ? null
            : Fee.fromJson(json[r'create_account_cost']),
        delegate_cost: json[r'delegate_cost'] == null
            ? null
            : Fee.fromJson(json[r'delegate_cost']),
        delete_account_cost: json[r'delete_account_cost'] == null
            ? null
            : Fee.fromJson(json[r'delete_account_cost']),
        delete_key_cost: json[r'delete_key_cost'] == null
            ? null
            : Fee.fromJson(json[r'delete_key_cost']),
        deploy_contract_cost: json[r'deploy_contract_cost'] == null
            ? null
            : Fee.fromJson(json[r'deploy_contract_cost']),
        deploy_contract_cost_per_byte:
            json[r'deploy_contract_cost_per_byte'] == null
            ? null
            : Fee.fromJson(json[r'deploy_contract_cost_per_byte']),
        function_call_cost: json[r'function_call_cost'] == null
            ? null
            : Fee.fromJson(json[r'function_call_cost']),
        function_call_cost_per_byte:
            json[r'function_call_cost_per_byte'] == null
            ? null
            : Fee.fromJson(json[r'function_call_cost_per_byte']),
        stake_cost: json[r'stake_cost'] == null
            ? null
            : Fee.fromJson(json[r'stake_cost']),
        transfer_cost: json[r'transfer_cost'] == null
            ? null
            : Fee.fromJson(json[r'transfer_cost']),
      );

  final AccessKeyCreationConfigView? add_key_cost;
  final Fee? create_account_cost;
  final Fee? delegate_cost;
  final Fee? delete_account_cost;
  final Fee? delete_key_cost;
  final Fee? deploy_contract_cost;
  final Fee? deploy_contract_cost_per_byte;
  final Fee? function_call_cost;
  final Fee? function_call_cost_per_byte;
  final Fee? stake_cost;
  final Fee? transfer_cost;

  Map<String, dynamic> toJson() => {
    if (add_key_cost != null) r'add_key_cost': add_key_cost?.toJson(),
    if (create_account_cost != null)
      r'create_account_cost': create_account_cost?.toJson(),
    if (delegate_cost != null) r'delegate_cost': delegate_cost?.toJson(),
    if (delete_account_cost != null)
      r'delete_account_cost': delete_account_cost?.toJson(),
    if (delete_key_cost != null) r'delete_key_cost': delete_key_cost?.toJson(),
    if (deploy_contract_cost != null)
      r'deploy_contract_cost': deploy_contract_cost?.toJson(),
    if (deploy_contract_cost_per_byte != null)
      r'deploy_contract_cost_per_byte': deploy_contract_cost_per_byte?.toJson(),
    if (function_call_cost != null)
      r'function_call_cost': function_call_cost?.toJson(),
    if (function_call_cost_per_byte != null)
      r'function_call_cost_per_byte': function_call_cost_per_byte?.toJson(),
    if (stake_cost != null) r'stake_cost': stake_cost?.toJson(),
    if (transfer_cost != null) r'transfer_cost': transfer_cost?.toJson(),
  };
}

/// Generated from `ActionError`.
class ActionError {
  const ActionError({this.index, this.kind});

  factory ActionError.fromJson(Map<String, dynamic> json) => ActionError(
    index: json[r'index'] == null ? null : (json[r'index'] as num).toInt(),
    kind: json[r'kind'] == null
        ? null
        : ActionErrorKind.fromJson(json[r'kind']),
  );

  final int? index;
  final ActionErrorKind? kind;

  Map<String, dynamic> toJson() => {
    if (index != null) r'index': index,
    if (kind != null) r'kind': kind?.toJson(),
  };
}

/// Union type generated from `ActionErrorKind`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ActionErrorKind {
  const ActionErrorKind(this.json);
  factory ActionErrorKind.fromJson(dynamic json) => ActionErrorKind(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ActionView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ActionView {
  const ActionView(this.json);
  factory ActionView.fromJson(dynamic json) => ActionView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ActionsValidationError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ActionsValidationError {
  const ActionsValidationError(this.json);
  factory ActionsValidationError.fromJson(dynamic json) =>
      ActionsValidationError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `AddKeyAction`.
class AddKeyAction {
  const AddKeyAction({this.access_key, this.public_key});

  factory AddKeyAction.fromJson(Map<String, dynamic> json) => AddKeyAction(
    access_key: json[r'access_key'] == null
        ? null
        : AccessKey.fromJson(json[r'access_key']),
    public_key: json[r'public_key'] == null
        ? null
        : json[r'public_key'] as PublicKey,
  );

  final AccessKey? access_key;
  final PublicKey? public_key;

  Map<String, dynamic> toJson() => {
    if (access_key != null) r'access_key': access_key?.toJson(),
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `BandwidthRequest`.
class BandwidthRequest {
  const BandwidthRequest({this.requested_values_bitmap, this.to_shard});

  factory BandwidthRequest.fromJson(Map<String, dynamic> json) =>
      BandwidthRequest(
        requested_values_bitmap: json[r'requested_values_bitmap'] == null
            ? null
            : BandwidthRequestBitmap.fromJson(json[r'requested_values_bitmap']),
        to_shard: json[r'to_shard'] == null
            ? null
            : (json[r'to_shard'] as num).toInt(),
      );

  final BandwidthRequestBitmap? requested_values_bitmap;
  final int? to_shard;

  Map<String, dynamic> toJson() => {
    if (requested_values_bitmap != null)
      r'requested_values_bitmap': requested_values_bitmap?.toJson(),
    if (to_shard != null) r'to_shard': to_shard,
  };
}

/// Generated from `BandwidthRequestBitmap`.
class BandwidthRequestBitmap {
  const BandwidthRequestBitmap({this.data});

  factory BandwidthRequestBitmap.fromJson(Map<String, dynamic> json) =>
      BandwidthRequestBitmap(
        data: json[r'data'] == null
            ? null
            : (json[r'data'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
      );

  final List<int>? data;

  Map<String, dynamic> toJson() => {if (data != null) r'data': data};
}

/// Union type generated from `BandwidthRequests`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class BandwidthRequests {
  const BandwidthRequests(this.json);
  factory BandwidthRequests.fromJson(dynamic json) => BandwidthRequests(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `BandwidthRequestsV1`.
class BandwidthRequestsV1 {
  const BandwidthRequestsV1({this.requests});

  factory BandwidthRequestsV1.fromJson(Map<String, dynamic> json) =>
      BandwidthRequestsV1(
        requests: json[r'requests'] == null
            ? null
            : (json[r'requests'] as List)
                  .map<BandwidthRequest>((e) => BandwidthRequest.fromJson(e))
                  .toList(),
      );

  final List<BandwidthRequest>? requests;

  Map<String, dynamic> toJson() => {
    if (requests != null)
      r'requests': requests?.map((e) => e.toJson()).toList(),
  };
}

/// Generated from `BlockHeaderInnerLiteView`.
class BlockHeaderInnerLiteView {
  const BlockHeaderInnerLiteView({
    this.block_merkle_root,
    this.epoch_id,
    this.height,
    this.next_bp_hash,
    this.next_epoch_id,
    this.outcome_root,
    this.prev_state_root,
    this.timestamp,
    this.timestamp_nanosec,
  });

  factory BlockHeaderInnerLiteView.fromJson(Map<String, dynamic> json) =>
      BlockHeaderInnerLiteView(
        block_merkle_root: json[r'block_merkle_root'] == null
            ? null
            : json[r'block_merkle_root'] as CryptoHash,
        epoch_id: json[r'epoch_id'] == null
            ? null
            : json[r'epoch_id'] as CryptoHash,
        height: json[r'height'] == null
            ? null
            : (json[r'height'] as num).toInt(),
        next_bp_hash: json[r'next_bp_hash'] == null
            ? null
            : json[r'next_bp_hash'] as CryptoHash,
        next_epoch_id: json[r'next_epoch_id'] == null
            ? null
            : json[r'next_epoch_id'] as CryptoHash,
        outcome_root: json[r'outcome_root'] == null
            ? null
            : json[r'outcome_root'] as CryptoHash,
        prev_state_root: json[r'prev_state_root'] == null
            ? null
            : json[r'prev_state_root'] as CryptoHash,
        timestamp: json[r'timestamp'] == null
            ? null
            : (json[r'timestamp'] as num).toInt(),
        timestamp_nanosec: json[r'timestamp_nanosec'] == null
            ? null
            : json[r'timestamp_nanosec'] as String,
      );

  final CryptoHash? block_merkle_root;
  final CryptoHash? epoch_id;
  final int? height;
  final CryptoHash? next_bp_hash;
  final CryptoHash? next_epoch_id;
  final CryptoHash? outcome_root;
  final CryptoHash? prev_state_root;
  final int? timestamp;
  final String? timestamp_nanosec;

  Map<String, dynamic> toJson() => {
    if (block_merkle_root != null) r'block_merkle_root': block_merkle_root,
    if (epoch_id != null) r'epoch_id': epoch_id,
    if (height != null) r'height': height,
    if (next_bp_hash != null) r'next_bp_hash': next_bp_hash,
    if (next_epoch_id != null) r'next_epoch_id': next_epoch_id,
    if (outcome_root != null) r'outcome_root': outcome_root,
    if (prev_state_root != null) r'prev_state_root': prev_state_root,
    if (timestamp != null) r'timestamp': timestamp,
    if (timestamp_nanosec != null) r'timestamp_nanosec': timestamp_nanosec,
  };
}

/// Generated from `BlockHeaderView`.
class BlockHeaderView {
  const BlockHeaderView({
    this.approvals,
    this.block_body_hash,
    this.block_merkle_root,
    this.block_ordinal,
    this.challenges_result,
    this.challenges_root,
    this.chunk_endorsements,
    this.chunk_headers_root,
    this.chunk_mask,
    this.chunk_receipts_root,
    this.chunk_tx_root,
    this.chunks_included,
    this.epoch_id,
    this.epoch_sync_data_hash,
    this.gas_price,
    this.hash,
    this.height,
    this.last_ds_final_block,
    this.last_final_block,
    this.latest_protocol_version,
    this.next_bp_hash,
    this.next_epoch_id,
    this.outcome_root,
    this.prev_hash,
    this.prev_height,
    this.prev_last_certified_block_epoch_id,
    this.prev_state_root,
    this.random_value,
    this.rent_paid,
    this.shard_split,
    this.signature,
    this.spice_chunk_endorsement_stats,
    this.timestamp,
    this.timestamp_nanosec,
    this.total_supply,
    this.validator_proposals,
    this.validator_reward,
  });

  factory BlockHeaderView.fromJson(
    Map<String, dynamic> json,
  ) => BlockHeaderView(
    approvals: json[r'approvals'] == null
        ? null
        : (json[r'approvals'] as List).map<dynamic>((e) => e).toList(),
    block_body_hash: json[r'block_body_hash'] == null
        ? null
        : json[r'block_body_hash'],
    block_merkle_root: json[r'block_merkle_root'] == null
        ? null
        : json[r'block_merkle_root'] as CryptoHash,
    block_ordinal: json[r'block_ordinal'] == null
        ? null
        : (json[r'block_ordinal'] as num).toInt(),
    challenges_result: json[r'challenges_result'] == null
        ? null
        : (json[r'challenges_result'] as List)
              .map<SlashedValidator>((e) => SlashedValidator.fromJson(e))
              .toList(),
    challenges_root: json[r'challenges_root'] == null
        ? null
        : json[r'challenges_root'] as CryptoHash,
    chunk_endorsements: json[r'chunk_endorsements'] == null
        ? null
        : (json[r'chunk_endorsements'] as List)
              .map<List<int>>(
                (e) => (e as List).map<int>((e) => (e as num).toInt()).toList(),
              )
              .toList(),
    chunk_headers_root: json[r'chunk_headers_root'] == null
        ? null
        : json[r'chunk_headers_root'] as CryptoHash,
    chunk_mask: json[r'chunk_mask'] == null
        ? null
        : (json[r'chunk_mask'] as List).map<bool>((e) => e as bool).toList(),
    chunk_receipts_root: json[r'chunk_receipts_root'] == null
        ? null
        : json[r'chunk_receipts_root'] as CryptoHash,
    chunk_tx_root: json[r'chunk_tx_root'] == null
        ? null
        : json[r'chunk_tx_root'] as CryptoHash,
    chunks_included: json[r'chunks_included'] == null
        ? null
        : (json[r'chunks_included'] as num).toInt(),
    epoch_id: json[r'epoch_id'] == null
        ? null
        : json[r'epoch_id'] as CryptoHash,
    epoch_sync_data_hash: json[r'epoch_sync_data_hash'] == null
        ? null
        : json[r'epoch_sync_data_hash'],
    gas_price: json[r'gas_price'] == null
        ? null
        : json[r'gas_price'] as NearToken,
    hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
    height: json[r'height'] == null ? null : (json[r'height'] as num).toInt(),
    last_ds_final_block: json[r'last_ds_final_block'] == null
        ? null
        : json[r'last_ds_final_block'] as CryptoHash,
    last_final_block: json[r'last_final_block'] == null
        ? null
        : json[r'last_final_block'] as CryptoHash,
    latest_protocol_version: json[r'latest_protocol_version'] == null
        ? null
        : (json[r'latest_protocol_version'] as num).toInt(),
    next_bp_hash: json[r'next_bp_hash'] == null
        ? null
        : json[r'next_bp_hash'] as CryptoHash,
    next_epoch_id: json[r'next_epoch_id'] == null
        ? null
        : json[r'next_epoch_id'] as CryptoHash,
    outcome_root: json[r'outcome_root'] == null
        ? null
        : json[r'outcome_root'] as CryptoHash,
    prev_hash: json[r'prev_hash'] == null
        ? null
        : json[r'prev_hash'] as CryptoHash,
    prev_height: json[r'prev_height'] == null
        ? null
        : (json[r'prev_height'] as num).toInt(),
    prev_last_certified_block_epoch_id:
        json[r'prev_last_certified_block_epoch_id'] == null
        ? null
        : json[r'prev_last_certified_block_epoch_id'],
    prev_state_root: json[r'prev_state_root'] == null
        ? null
        : json[r'prev_state_root'] as CryptoHash,
    random_value: json[r'random_value'] == null
        ? null
        : json[r'random_value'] as CryptoHash,
    rent_paid: json[r'rent_paid'] == null
        ? null
        : json[r'rent_paid'] as NearToken,
    shard_split: json[r'shard_split'] == null
        ? null
        : (json[r'shard_split'] as List),
    signature: json[r'signature'] == null
        ? null
        : json[r'signature'] as Signature,
    spice_chunk_endorsement_stats:
        json[r'spice_chunk_endorsement_stats'] == null
        ? null
        : (json[r'spice_chunk_endorsement_stats'] as List)
              .map<SpiceChunkEndorsementStats>(
                (e) => SpiceChunkEndorsementStats.fromJson(e),
              )
              .toList(),
    timestamp: json[r'timestamp'] == null
        ? null
        : (json[r'timestamp'] as num).toInt(),
    timestamp_nanosec: json[r'timestamp_nanosec'] == null
        ? null
        : json[r'timestamp_nanosec'] as String,
    total_supply: json[r'total_supply'] == null
        ? null
        : json[r'total_supply'] as NearToken,
    validator_proposals: json[r'validator_proposals'] == null
        ? null
        : (json[r'validator_proposals'] as List)
              .map<ValidatorStakeView>((e) => ValidatorStakeView.fromJson(e))
              .toList(),
    validator_reward: json[r'validator_reward'] == null
        ? null
        : json[r'validator_reward'] as NearToken,
  );

  final List<dynamic>? approvals;
  final dynamic? block_body_hash;
  final CryptoHash? block_merkle_root;
  final int? block_ordinal;
  final List<SlashedValidator>? challenges_result;
  final CryptoHash? challenges_root;
  final List<List<int>>? chunk_endorsements;
  final CryptoHash? chunk_headers_root;
  final List<bool>? chunk_mask;
  final CryptoHash? chunk_receipts_root;
  final CryptoHash? chunk_tx_root;
  final int? chunks_included;
  final CryptoHash? epoch_id;
  final dynamic? epoch_sync_data_hash;
  final NearToken? gas_price;
  final CryptoHash? hash;
  final int? height;
  final CryptoHash? last_ds_final_block;
  final CryptoHash? last_final_block;
  final int? latest_protocol_version;
  final CryptoHash? next_bp_hash;
  final CryptoHash? next_epoch_id;
  final CryptoHash? outcome_root;
  final CryptoHash? prev_hash;
  final int? prev_height;
  final dynamic? prev_last_certified_block_epoch_id;
  final CryptoHash? prev_state_root;
  final CryptoHash? random_value;
  final NearToken? rent_paid;
  final List<Object?>? shard_split;
  final Signature? signature;
  final List<SpiceChunkEndorsementStats>? spice_chunk_endorsement_stats;
  final int? timestamp;
  final String? timestamp_nanosec;
  final NearToken? total_supply;
  final List<ValidatorStakeView>? validator_proposals;
  final NearToken? validator_reward;

  Map<String, dynamic> toJson() => {
    if (approvals != null) r'approvals': approvals,
    if (block_body_hash != null) r'block_body_hash': block_body_hash,
    if (block_merkle_root != null) r'block_merkle_root': block_merkle_root,
    if (block_ordinal != null) r'block_ordinal': block_ordinal,
    if (challenges_result != null)
      r'challenges_result': challenges_result?.map((e) => e.toJson()).toList(),
    if (challenges_root != null) r'challenges_root': challenges_root,
    if (chunk_endorsements != null) r'chunk_endorsements': chunk_endorsements,
    if (chunk_headers_root != null) r'chunk_headers_root': chunk_headers_root,
    if (chunk_mask != null) r'chunk_mask': chunk_mask,
    if (chunk_receipts_root != null)
      r'chunk_receipts_root': chunk_receipts_root,
    if (chunk_tx_root != null) r'chunk_tx_root': chunk_tx_root,
    if (chunks_included != null) r'chunks_included': chunks_included,
    if (epoch_id != null) r'epoch_id': epoch_id,
    if (epoch_sync_data_hash != null)
      r'epoch_sync_data_hash': epoch_sync_data_hash,
    if (gas_price != null) r'gas_price': gas_price,
    if (hash != null) r'hash': hash,
    if (height != null) r'height': height,
    if (last_ds_final_block != null)
      r'last_ds_final_block': last_ds_final_block,
    if (last_final_block != null) r'last_final_block': last_final_block,
    if (latest_protocol_version != null)
      r'latest_protocol_version': latest_protocol_version,
    if (next_bp_hash != null) r'next_bp_hash': next_bp_hash,
    if (next_epoch_id != null) r'next_epoch_id': next_epoch_id,
    if (outcome_root != null) r'outcome_root': outcome_root,
    if (prev_hash != null) r'prev_hash': prev_hash,
    if (prev_height != null) r'prev_height': prev_height,
    if (prev_last_certified_block_epoch_id != null)
      r'prev_last_certified_block_epoch_id': prev_last_certified_block_epoch_id,
    if (prev_state_root != null) r'prev_state_root': prev_state_root,
    if (random_value != null) r'random_value': random_value,
    if (rent_paid != null) r'rent_paid': rent_paid,
    if (shard_split != null) r'shard_split': shard_split,
    if (signature != null) r'signature': signature,
    if (spice_chunk_endorsement_stats != null)
      r'spice_chunk_endorsement_stats': spice_chunk_endorsement_stats
          ?.map((e) => e.toJson())
          .toList(),
    if (timestamp != null) r'timestamp': timestamp,
    if (timestamp_nanosec != null) r'timestamp_nanosec': timestamp_nanosec,
    if (total_supply != null) r'total_supply': total_supply,
    if (validator_proposals != null)
      r'validator_proposals': validator_proposals
          ?.map((e) => e.toJson())
          .toList(),
    if (validator_reward != null) r'validator_reward': validator_reward,
  };
}

/// Union type generated from `BlockId`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class BlockId {
  const BlockId(this.json);
  factory BlockId.fromJson(dynamic json) => BlockId(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `BlockReference`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class BlockReference {
  const BlockReference(this.json);
  factory BlockReference.fromJson(dynamic json) => BlockReference(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `BlockStatusView`.
class BlockStatusView {
  const BlockStatusView({this.hash, this.height});

  factory BlockStatusView.fromJson(Map<String, dynamic> json) =>
      BlockStatusView(
        hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
        height: json[r'height'] == null
            ? null
            : (json[r'height'] as num).toInt(),
      );

  final CryptoHash? hash;
  final int? height;

  Map<String, dynamic> toJson() => {
    if (hash != null) r'hash': hash,
    if (height != null) r'height': height,
  };
}

/// Generated from `CallResult`.
class CallResult {
  const CallResult({this.logs, this.result});

  factory CallResult.fromJson(Map<String, dynamic> json) => CallResult(
    logs: json[r'logs'] == null
        ? null
        : (json[r'logs'] as List).map<String>((e) => e as String).toList(),
    result: json[r'result'] == null
        ? null
        : (json[r'result'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
  );

  final List<String>? logs;
  final List<int>? result;

  Map<String, dynamic> toJson() => {
    if (logs != null) r'logs': logs,
    if (result != null) r'result': result,
  };
}

/// Generated from `CatchupStatusView`.
class CatchupStatusView {
  const CatchupStatusView({
    this.blocks_to_catchup,
    this.shard_sync_status,
    this.sync_block_hash,
    this.sync_block_height,
  });

  factory CatchupStatusView.fromJson(Map<String, dynamic> json) =>
      CatchupStatusView(
        blocks_to_catchup: json[r'blocks_to_catchup'] == null
            ? null
            : (json[r'blocks_to_catchup'] as List)
                  .map<BlockStatusView>((e) => BlockStatusView.fromJson(e))
                  .toList(),
        shard_sync_status: json[r'shard_sync_status'] == null
            ? null
            : (json[r'shard_sync_status'] as Map).cast<String, dynamic>(),
        sync_block_hash: json[r'sync_block_hash'] == null
            ? null
            : json[r'sync_block_hash'] as CryptoHash,
        sync_block_height: json[r'sync_block_height'] == null
            ? null
            : (json[r'sync_block_height'] as num).toInt(),
      );

  final List<BlockStatusView>? blocks_to_catchup;
  final Map<String, dynamic>? shard_sync_status;
  final CryptoHash? sync_block_hash;
  final int? sync_block_height;

  Map<String, dynamic> toJson() => {
    if (blocks_to_catchup != null)
      r'blocks_to_catchup': blocks_to_catchup?.map((e) => e.toJson()).toList(),
    if (shard_sync_status != null) r'shard_sync_status': shard_sync_status,
    if (sync_block_hash != null) r'sync_block_hash': sync_block_hash,
    if (sync_block_height != null) r'sync_block_height': sync_block_height,
  };
}

/// Generated from `ChunkDistributionNetworkConfig`.
class ChunkDistributionNetworkConfig {
  const ChunkDistributionNetworkConfig({this.enabled, this.uris});

  factory ChunkDistributionNetworkConfig.fromJson(Map<String, dynamic> json) =>
      ChunkDistributionNetworkConfig(
        enabled: json[r'enabled'] == null ? null : json[r'enabled'] as bool,
        uris: json[r'uris'] == null
            ? null
            : ChunkDistributionUris.fromJson(json[r'uris']),
      );

  final bool? enabled;
  final ChunkDistributionUris? uris;

  Map<String, dynamic> toJson() => {
    if (enabled != null) r'enabled': enabled,
    if (uris != null) r'uris': uris?.toJson(),
  };
}

/// Generated from `ChunkDistributionUris`.
class ChunkDistributionUris {
  const ChunkDistributionUris({this.get, this.set});

  factory ChunkDistributionUris.fromJson(Map<String, dynamic> json) =>
      ChunkDistributionUris(
        get: json[r'get'] == null ? null : json[r'get'] as String,
        set: json[r'set'] == null ? null : json[r'set'] as String,
      );

  final String? get;
  final String? set;

  Map<String, dynamic> toJson() => {
    if (get != null) r'get': get,
    if (set != null) r'set': set,
  };
}

/// Alias for `ChunkHash`.
typedef ChunkHash = CryptoHash;

/// Generated from `ChunkHeaderView`.
class ChunkHeaderView {
  const ChunkHeaderView({
    this.balance_burnt,
    this.bandwidth_requests,
    this.chunk_hash,
    this.congestion_info,
    this.encoded_length,
    this.encoded_merkle_root,
    this.gas_limit,
    this.gas_used,
    this.height_created,
    this.height_included,
    this.outcome_root,
    this.outgoing_receipts_root,
    this.prev_block_hash,
    this.prev_state_root,
    this.proposed_split,
    this.rent_paid,
    this.shard_id,
    this.signature,
    this.tx_root,
    this.validator_proposals,
    this.validator_reward,
  });

  factory ChunkHeaderView.fromJson(
    Map<String, dynamic> json,
  ) => ChunkHeaderView(
    balance_burnt: json[r'balance_burnt'] == null
        ? null
        : json[r'balance_burnt'] as NearToken,
    bandwidth_requests: json[r'bandwidth_requests'] == null
        ? null
        : json[r'bandwidth_requests'],
    chunk_hash: json[r'chunk_hash'] == null
        ? null
        : json[r'chunk_hash'] as CryptoHash,
    congestion_info: json[r'congestion_info'] == null
        ? null
        : json[r'congestion_info'],
    encoded_length: json[r'encoded_length'] == null
        ? null
        : (json[r'encoded_length'] as num).toInt(),
    encoded_merkle_root: json[r'encoded_merkle_root'] == null
        ? null
        : json[r'encoded_merkle_root'] as CryptoHash,
    gas_limit: json[r'gas_limit'] == null
        ? null
        : json[r'gas_limit'] as NearGas,
    gas_used: json[r'gas_used'] == null ? null : json[r'gas_used'] as NearGas,
    height_created: json[r'height_created'] == null
        ? null
        : (json[r'height_created'] as num).toInt(),
    height_included: json[r'height_included'] == null
        ? null
        : (json[r'height_included'] as num).toInt(),
    outcome_root: json[r'outcome_root'] == null
        ? null
        : json[r'outcome_root'] as CryptoHash,
    outgoing_receipts_root: json[r'outgoing_receipts_root'] == null
        ? null
        : json[r'outgoing_receipts_root'] as CryptoHash,
    prev_block_hash: json[r'prev_block_hash'] == null
        ? null
        : json[r'prev_block_hash'] as CryptoHash,
    prev_state_root: json[r'prev_state_root'] == null
        ? null
        : json[r'prev_state_root'] as CryptoHash,
    proposed_split: json[r'proposed_split'] == null
        ? null
        : json[r'proposed_split'],
    rent_paid: json[r'rent_paid'] == null
        ? null
        : json[r'rent_paid'] as NearToken,
    shard_id: json[r'shard_id'] == null ? null : json[r'shard_id'] as ShardId,
    signature: json[r'signature'] == null
        ? null
        : json[r'signature'] as Signature,
    tx_root: json[r'tx_root'] == null ? null : json[r'tx_root'] as CryptoHash,
    validator_proposals: json[r'validator_proposals'] == null
        ? null
        : (json[r'validator_proposals'] as List)
              .map<ValidatorStakeView>((e) => ValidatorStakeView.fromJson(e))
              .toList(),
    validator_reward: json[r'validator_reward'] == null
        ? null
        : json[r'validator_reward'] as NearToken,
  );

  final NearToken? balance_burnt;
  final dynamic? bandwidth_requests;
  final CryptoHash? chunk_hash;
  final dynamic? congestion_info;
  final int? encoded_length;
  final CryptoHash? encoded_merkle_root;
  final NearGas? gas_limit;
  final NearGas? gas_used;
  final int? height_created;
  final int? height_included;
  final CryptoHash? outcome_root;
  final CryptoHash? outgoing_receipts_root;
  final CryptoHash? prev_block_hash;
  final CryptoHash? prev_state_root;
  final dynamic? proposed_split;
  final NearToken? rent_paid;
  final ShardId? shard_id;
  final Signature? signature;
  final CryptoHash? tx_root;
  final List<ValidatorStakeView>? validator_proposals;
  final NearToken? validator_reward;

  Map<String, dynamic> toJson() => {
    if (balance_burnt != null) r'balance_burnt': balance_burnt,
    if (bandwidth_requests != null) r'bandwidth_requests': bandwidth_requests,
    if (chunk_hash != null) r'chunk_hash': chunk_hash,
    if (congestion_info != null) r'congestion_info': congestion_info,
    if (encoded_length != null) r'encoded_length': encoded_length,
    if (encoded_merkle_root != null)
      r'encoded_merkle_root': encoded_merkle_root,
    if (gas_limit != null) r'gas_limit': gas_limit,
    if (gas_used != null) r'gas_used': gas_used,
    if (height_created != null) r'height_created': height_created,
    if (height_included != null) r'height_included': height_included,
    if (outcome_root != null) r'outcome_root': outcome_root,
    if (outgoing_receipts_root != null)
      r'outgoing_receipts_root': outgoing_receipts_root,
    if (prev_block_hash != null) r'prev_block_hash': prev_block_hash,
    if (prev_state_root != null) r'prev_state_root': prev_state_root,
    if (proposed_split != null) r'proposed_split': proposed_split,
    if (rent_paid != null) r'rent_paid': rent_paid,
    if (shard_id != null) r'shard_id': shard_id,
    if (signature != null) r'signature': signature,
    if (tx_root != null) r'tx_root': tx_root,
    if (validator_proposals != null)
      r'validator_proposals': validator_proposals
          ?.map((e) => e.toJson())
          .toList(),
    if (validator_reward != null) r'validator_reward': validator_reward,
  };
}

/// Generated from `CloudArchivalWriterConfig`.
class CloudArchivalWriterConfig {
  const CloudArchivalWriterConfig({
    this.archive_block_data,
    this.polling_interval,
    this.snapshot_every_n_epochs,
  });

  factory CloudArchivalWriterConfig.fromJson(Map<String, dynamic> json) =>
      CloudArchivalWriterConfig(
        archive_block_data: json[r'archive_block_data'] == null
            ? null
            : json[r'archive_block_data'] as bool,
        polling_interval: json[r'polling_interval'] == null
            ? null
            : DurationAsStdSchemaProvider.fromJson(json[r'polling_interval']),
        snapshot_every_n_epochs: json[r'snapshot_every_n_epochs'] == null
            ? null
            : (json[r'snapshot_every_n_epochs'] as num).toInt(),
      );

  final bool? archive_block_data;
  final DurationAsStdSchemaProvider? polling_interval;
  final int? snapshot_every_n_epochs;

  Map<String, dynamic> toJson() => {
    if (archive_block_data != null) r'archive_block_data': archive_block_data,
    if (polling_interval != null)
      r'polling_interval': polling_interval?.toJson(),
    if (snapshot_every_n_epochs != null)
      r'snapshot_every_n_epochs': snapshot_every_n_epochs,
  };
}

/// Union type generated from `CompilationError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class CompilationError {
  const CompilationError(this.json);
  factory CompilationError.fromJson(dynamic json) => CompilationError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `CongestionControlConfigView`.
class CongestionControlConfigView {
  const CongestionControlConfigView({
    this.allowed_shard_outgoing_gas,
    this.max_congestion_incoming_gas,
    this.max_congestion_memory_consumption,
    this.max_congestion_missed_chunks,
    this.max_congestion_outgoing_gas,
    this.max_outgoing_gas,
    this.max_tx_gas,
    this.min_outgoing_gas,
    this.min_tx_gas,
    this.outgoing_receipts_big_size_limit,
    this.outgoing_receipts_usual_size_limit,
    this.reject_tx_congestion_threshold,
  });

  factory CongestionControlConfigView.fromJson(
    Map<String, dynamic> json,
  ) => CongestionControlConfigView(
    allowed_shard_outgoing_gas: json[r'allowed_shard_outgoing_gas'] == null
        ? null
        : json[r'allowed_shard_outgoing_gas'] as NearGas,
    max_congestion_incoming_gas: json[r'max_congestion_incoming_gas'] == null
        ? null
        : json[r'max_congestion_incoming_gas'] as NearGas,
    max_congestion_memory_consumption:
        json[r'max_congestion_memory_consumption'] == null
        ? null
        : (json[r'max_congestion_memory_consumption'] as num).toInt(),
    max_congestion_missed_chunks: json[r'max_congestion_missed_chunks'] == null
        ? null
        : (json[r'max_congestion_missed_chunks'] as num).toInt(),
    max_congestion_outgoing_gas: json[r'max_congestion_outgoing_gas'] == null
        ? null
        : json[r'max_congestion_outgoing_gas'] as NearGas,
    max_outgoing_gas: json[r'max_outgoing_gas'] == null
        ? null
        : json[r'max_outgoing_gas'] as NearGas,
    max_tx_gas: json[r'max_tx_gas'] == null
        ? null
        : json[r'max_tx_gas'] as NearGas,
    min_outgoing_gas: json[r'min_outgoing_gas'] == null
        ? null
        : json[r'min_outgoing_gas'] as NearGas,
    min_tx_gas: json[r'min_tx_gas'] == null
        ? null
        : json[r'min_tx_gas'] as NearGas,
    outgoing_receipts_big_size_limit:
        json[r'outgoing_receipts_big_size_limit'] == null
        ? null
        : (json[r'outgoing_receipts_big_size_limit'] as num).toInt(),
    outgoing_receipts_usual_size_limit:
        json[r'outgoing_receipts_usual_size_limit'] == null
        ? null
        : (json[r'outgoing_receipts_usual_size_limit'] as num).toInt(),
    reject_tx_congestion_threshold:
        json[r'reject_tx_congestion_threshold'] == null
        ? null
        : (json[r'reject_tx_congestion_threshold'] as num).toDouble(),
  );

  final NearGas? allowed_shard_outgoing_gas;
  final NearGas? max_congestion_incoming_gas;
  final int? max_congestion_memory_consumption;
  final int? max_congestion_missed_chunks;
  final NearGas? max_congestion_outgoing_gas;
  final NearGas? max_outgoing_gas;
  final NearGas? max_tx_gas;
  final NearGas? min_outgoing_gas;
  final NearGas? min_tx_gas;
  final int? outgoing_receipts_big_size_limit;
  final int? outgoing_receipts_usual_size_limit;
  final double? reject_tx_congestion_threshold;

  Map<String, dynamic> toJson() => {
    if (allowed_shard_outgoing_gas != null)
      r'allowed_shard_outgoing_gas': allowed_shard_outgoing_gas,
    if (max_congestion_incoming_gas != null)
      r'max_congestion_incoming_gas': max_congestion_incoming_gas,
    if (max_congestion_memory_consumption != null)
      r'max_congestion_memory_consumption': max_congestion_memory_consumption,
    if (max_congestion_missed_chunks != null)
      r'max_congestion_missed_chunks': max_congestion_missed_chunks,
    if (max_congestion_outgoing_gas != null)
      r'max_congestion_outgoing_gas': max_congestion_outgoing_gas,
    if (max_outgoing_gas != null) r'max_outgoing_gas': max_outgoing_gas,
    if (max_tx_gas != null) r'max_tx_gas': max_tx_gas,
    if (min_outgoing_gas != null) r'min_outgoing_gas': min_outgoing_gas,
    if (min_tx_gas != null) r'min_tx_gas': min_tx_gas,
    if (outgoing_receipts_big_size_limit != null)
      r'outgoing_receipts_big_size_limit': outgoing_receipts_big_size_limit,
    if (outgoing_receipts_usual_size_limit != null)
      r'outgoing_receipts_usual_size_limit': outgoing_receipts_usual_size_limit,
    if (reject_tx_congestion_threshold != null)
      r'reject_tx_congestion_threshold': reject_tx_congestion_threshold,
  };
}

/// Generated from `CongestionInfoView`.
class CongestionInfoView {
  const CongestionInfoView({
    this.allowed_shard,
    this.buffered_receipts_gas,
    this.delayed_receipts_gas,
    this.receipt_bytes,
  });

  factory CongestionInfoView.fromJson(Map<String, dynamic> json) =>
      CongestionInfoView(
        allowed_shard: json[r'allowed_shard'] == null
            ? null
            : (json[r'allowed_shard'] as num).toInt(),
        buffered_receipts_gas: json[r'buffered_receipts_gas'] == null
            ? null
            : json[r'buffered_receipts_gas'] as String,
        delayed_receipts_gas: json[r'delayed_receipts_gas'] == null
            ? null
            : json[r'delayed_receipts_gas'] as String,
        receipt_bytes: json[r'receipt_bytes'] == null
            ? null
            : (json[r'receipt_bytes'] as num).toInt(),
      );

  final int? allowed_shard;
  final String? buffered_receipts_gas;
  final String? delayed_receipts_gas;
  final int? receipt_bytes;

  Map<String, dynamic> toJson() => {
    if (allowed_shard != null) r'allowed_shard': allowed_shard,
    if (buffered_receipts_gas != null)
      r'buffered_receipts_gas': buffered_receipts_gas,
    if (delayed_receipts_gas != null)
      r'delayed_receipts_gas': delayed_receipts_gas,
    if (receipt_bytes != null) r'receipt_bytes': receipt_bytes,
  };
}

/// Generated from `ContractCodeView`.
class ContractCodeView {
  const ContractCodeView({this.code_base64, this.hash});

  factory ContractCodeView.fromJson(Map<String, dynamic> json) =>
      ContractCodeView(
        code_base64: json[r'code_base64'] == null
            ? null
            : json[r'code_base64'] as String,
        hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
      );

  final String? code_base64;
  final CryptoHash? hash;

  Map<String, dynamic> toJson() => {
    if (code_base64 != null) r'code_base64': code_base64,
    if (hash != null) r'hash': hash,
  };
}

/// Generated from `CostGasUsed`.
class CostGasUsed {
  const CostGasUsed({this.cost, this.cost_category, this.gas_used});

  factory CostGasUsed.fromJson(Map<String, dynamic> json) => CostGasUsed(
    cost: json[r'cost'] == null ? null : json[r'cost'] as String,
    cost_category: json[r'cost_category'] == null
        ? null
        : json[r'cost_category'] as String,
    gas_used: json[r'gas_used'] == null ? null : json[r'gas_used'] as String,
  );

  final String? cost;
  final String? cost_category;
  final String? gas_used;

  Map<String, dynamic> toJson() => {
    if (cost != null) r'cost': cost,
    if (cost_category != null) r'cost_category': cost_category,
    if (gas_used != null) r'gas_used': gas_used,
  };
}

/// Generated from `CreateAccountAction`.
class CreateAccountAction {
  const CreateAccountAction();

  factory CreateAccountAction.fromJson(Map<String, dynamic> json) =>
      CreateAccountAction();

  Map<String, dynamic> toJson() => {};
}

/// Alias for `CryptoHash`.
typedef CryptoHash = String;

/// Generated from `CurrentEpochValidatorInfo`.
class CurrentEpochValidatorInfo {
  const CurrentEpochValidatorInfo({
    this.account_id,
    this.is_slashed,
    this.num_expected_blocks,
    this.num_expected_chunks,
    this.num_expected_chunks_per_shard,
    this.num_expected_endorsements,
    this.num_expected_endorsements_per_shard,
    this.num_produced_blocks,
    this.num_produced_chunks,
    this.num_produced_chunks_per_shard,
    this.num_produced_endorsements,
    this.num_produced_endorsements_per_shard,
    this.public_key,
    this.shards,
    this.shards_endorsed,
    this.stake,
  });

  factory CurrentEpochValidatorInfo.fromJson(Map<String, dynamic> json) =>
      CurrentEpochValidatorInfo(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        is_slashed: json[r'is_slashed'] == null
            ? null
            : json[r'is_slashed'] as bool,
        num_expected_blocks: json[r'num_expected_blocks'] == null
            ? null
            : (json[r'num_expected_blocks'] as num).toInt(),
        num_expected_chunks: json[r'num_expected_chunks'] == null
            ? null
            : (json[r'num_expected_chunks'] as num).toInt(),
        num_expected_chunks_per_shard:
            json[r'num_expected_chunks_per_shard'] == null
            ? null
            : (json[r'num_expected_chunks_per_shard'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
        num_expected_endorsements: json[r'num_expected_endorsements'] == null
            ? null
            : (json[r'num_expected_endorsements'] as num).toInt(),
        num_expected_endorsements_per_shard:
            json[r'num_expected_endorsements_per_shard'] == null
            ? null
            : (json[r'num_expected_endorsements_per_shard'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
        num_produced_blocks: json[r'num_produced_blocks'] == null
            ? null
            : (json[r'num_produced_blocks'] as num).toInt(),
        num_produced_chunks: json[r'num_produced_chunks'] == null
            ? null
            : (json[r'num_produced_chunks'] as num).toInt(),
        num_produced_chunks_per_shard:
            json[r'num_produced_chunks_per_shard'] == null
            ? null
            : (json[r'num_produced_chunks_per_shard'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
        num_produced_endorsements: json[r'num_produced_endorsements'] == null
            ? null
            : (json[r'num_produced_endorsements'] as num).toInt(),
        num_produced_endorsements_per_shard:
            json[r'num_produced_endorsements_per_shard'] == null
            ? null
            : (json[r'num_produced_endorsements_per_shard'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
        shards: json[r'shards'] == null
            ? null
            : (json[r'shards'] as List)
                  .map<ShardId>((e) => e as ShardId)
                  .toList(),
        shards_endorsed: json[r'shards_endorsed'] == null
            ? null
            : (json[r'shards_endorsed'] as List)
                  .map<ShardId>((e) => e as ShardId)
                  .toList(),
        stake: json[r'stake'] == null ? null : json[r'stake'] as NearToken,
      );

  final AccountId? account_id;
  final bool? is_slashed;
  final int? num_expected_blocks;
  final int? num_expected_chunks;
  final List<int>? num_expected_chunks_per_shard;
  final int? num_expected_endorsements;
  final List<int>? num_expected_endorsements_per_shard;
  final int? num_produced_blocks;
  final int? num_produced_chunks;
  final List<int>? num_produced_chunks_per_shard;
  final int? num_produced_endorsements;
  final List<int>? num_produced_endorsements_per_shard;
  final PublicKey? public_key;
  final List<ShardId>? shards;
  final List<ShardId>? shards_endorsed;
  final NearToken? stake;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (is_slashed != null) r'is_slashed': is_slashed,
    if (num_expected_blocks != null)
      r'num_expected_blocks': num_expected_blocks,
    if (num_expected_chunks != null)
      r'num_expected_chunks': num_expected_chunks,
    if (num_expected_chunks_per_shard != null)
      r'num_expected_chunks_per_shard': num_expected_chunks_per_shard,
    if (num_expected_endorsements != null)
      r'num_expected_endorsements': num_expected_endorsements,
    if (num_expected_endorsements_per_shard != null)
      r'num_expected_endorsements_per_shard':
          num_expected_endorsements_per_shard,
    if (num_produced_blocks != null)
      r'num_produced_blocks': num_produced_blocks,
    if (num_produced_chunks != null)
      r'num_produced_chunks': num_produced_chunks,
    if (num_produced_chunks_per_shard != null)
      r'num_produced_chunks_per_shard': num_produced_chunks_per_shard,
    if (num_produced_endorsements != null)
      r'num_produced_endorsements': num_produced_endorsements,
    if (num_produced_endorsements_per_shard != null)
      r'num_produced_endorsements_per_shard':
          num_produced_endorsements_per_shard,
    if (public_key != null) r'public_key': public_key,
    if (shards != null) r'shards': shards,
    if (shards_endorsed != null) r'shards_endorsed': shards_endorsed,
    if (stake != null) r'stake': stake,
  };
}

/// Generated from `DataReceiptCreationConfigView`.
class DataReceiptCreationConfigView {
  const DataReceiptCreationConfigView({this.base_cost, this.cost_per_byte});

  factory DataReceiptCreationConfigView.fromJson(Map<String, dynamic> json) =>
      DataReceiptCreationConfigView(
        base_cost: json[r'base_cost'] == null
            ? null
            : Fee.fromJson(json[r'base_cost']),
        cost_per_byte: json[r'cost_per_byte'] == null
            ? null
            : Fee.fromJson(json[r'cost_per_byte']),
      );

  final Fee? base_cost;
  final Fee? cost_per_byte;

  Map<String, dynamic> toJson() => {
    if (base_cost != null) r'base_cost': base_cost?.toJson(),
    if (cost_per_byte != null) r'cost_per_byte': cost_per_byte?.toJson(),
  };
}

/// Generated from `DataReceiverView`.
class DataReceiverView {
  const DataReceiverView({this.data_id, this.receiver_id});

  factory DataReceiverView.fromJson(Map<String, dynamic> json) =>
      DataReceiverView(
        data_id: json[r'data_id'] == null
            ? null
            : json[r'data_id'] as CryptoHash,
        receiver_id: json[r'receiver_id'] == null
            ? null
            : json[r'receiver_id'] as AccountId,
      );

  final CryptoHash? data_id;
  final AccountId? receiver_id;

  Map<String, dynamic> toJson() => {
    if (data_id != null) r'data_id': data_id,
    if (receiver_id != null) r'receiver_id': receiver_id,
  };
}

/// Generated from `DelegateAction`.
class DelegateAction {
  const DelegateAction({
    this.actions,
    this.max_block_height,
    this.nonce,
    this.public_key,
    this.receiver_id,
    this.sender_id,
  });

  factory DelegateAction.fromJson(Map<String, dynamic> json) => DelegateAction(
    actions: json[r'actions'] == null
        ? null
        : (json[r'actions'] as List)
              .map<NonDelegateAction>((e) => NonDelegateAction.fromJson(e))
              .toList(),
    max_block_height: json[r'max_block_height'] == null
        ? null
        : (json[r'max_block_height'] as num).toInt(),
    nonce: json[r'nonce'] == null ? null : (json[r'nonce'] as num).toInt(),
    public_key: json[r'public_key'] == null
        ? null
        : json[r'public_key'] as PublicKey,
    receiver_id: json[r'receiver_id'] == null
        ? null
        : json[r'receiver_id'] as AccountId,
    sender_id: json[r'sender_id'] == null
        ? null
        : json[r'sender_id'] as AccountId,
  );

  final List<NonDelegateAction>? actions;
  final int? max_block_height;
  final int? nonce;
  final PublicKey? public_key;
  final AccountId? receiver_id;
  final AccountId? sender_id;

  Map<String, dynamic> toJson() => {
    if (actions != null) r'actions': actions?.map((e) => e.toJson()).toList(),
    if (max_block_height != null) r'max_block_height': max_block_height,
    if (nonce != null) r'nonce': nonce,
    if (public_key != null) r'public_key': public_key,
    if (receiver_id != null) r'receiver_id': receiver_id,
    if (sender_id != null) r'sender_id': sender_id,
  };
}

/// Generated from `DelegateActionV2`.
class DelegateActionV2 {
  const DelegateActionV2({
    this.actions,
    this.max_block_height,
    this.nonce,
    this.public_key,
    this.receiver_id,
    this.sender_id,
  });

  factory DelegateActionV2.fromJson(Map<String, dynamic> json) =>
      DelegateActionV2(
        actions: json[r'actions'] == null
            ? null
            : (json[r'actions'] as List)
                  .map<NonDelegateAction>((e) => NonDelegateAction.fromJson(e))
                  .toList(),
        max_block_height: json[r'max_block_height'] == null
            ? null
            : (json[r'max_block_height'] as num).toInt(),
        nonce: json[r'nonce'] == null
            ? null
            : TransactionNonce.fromJson(json[r'nonce']),
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
        receiver_id: json[r'receiver_id'] == null
            ? null
            : json[r'receiver_id'] as AccountId,
        sender_id: json[r'sender_id'] == null
            ? null
            : json[r'sender_id'] as AccountId,
      );

  final List<NonDelegateAction>? actions;
  final int? max_block_height;
  final TransactionNonce? nonce;
  final PublicKey? public_key;
  final AccountId? receiver_id;
  final AccountId? sender_id;

  Map<String, dynamic> toJson() => {
    if (actions != null) r'actions': actions?.map((e) => e.toJson()).toList(),
    if (max_block_height != null) r'max_block_height': max_block_height,
    if (nonce != null) r'nonce': nonce?.toJson(),
    if (public_key != null) r'public_key': public_key,
    if (receiver_id != null) r'receiver_id': receiver_id,
    if (sender_id != null) r'sender_id': sender_id,
  };
}

/// Generated from `DeleteAccountAction`.
class DeleteAccountAction {
  const DeleteAccountAction({this.beneficiary_id});

  factory DeleteAccountAction.fromJson(Map<String, dynamic> json) =>
      DeleteAccountAction(
        beneficiary_id: json[r'beneficiary_id'] == null
            ? null
            : json[r'beneficiary_id'] as AccountId,
      );

  final AccountId? beneficiary_id;

  Map<String, dynamic> toJson() => {
    if (beneficiary_id != null) r'beneficiary_id': beneficiary_id,
  };
}

/// Generated from `DeleteKeyAction`.
class DeleteKeyAction {
  const DeleteKeyAction({this.public_key});

  factory DeleteKeyAction.fromJson(Map<String, dynamic> json) =>
      DeleteKeyAction(
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
      );

  final PublicKey? public_key;

  Map<String, dynamic> toJson() => {
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `DeployContractAction`.
class DeployContractAction {
  const DeployContractAction({this.code});

  factory DeployContractAction.fromJson(Map<String, dynamic> json) =>
      DeployContractAction(
        code: json[r'code'] == null ? null : json[r'code'] as String,
      );

  final String? code;

  Map<String, dynamic> toJson() => {if (code != null) r'code': code};
}

/// Generated from `DeployGlobalContractAction`.
class DeployGlobalContractAction {
  const DeployGlobalContractAction({this.code, this.deploy_mode});

  factory DeployGlobalContractAction.fromJson(Map<String, dynamic> json) =>
      DeployGlobalContractAction(
        code: json[r'code'] == null ? null : json[r'code'] as String,
        deploy_mode: json[r'deploy_mode'] == null
            ? null
            : GlobalContractDeployMode.fromJson(json[r'deploy_mode']),
      );

  final String? code;
  final GlobalContractDeployMode? deploy_mode;

  Map<String, dynamic> toJson() => {
    if (code != null) r'code': code,
    if (deploy_mode != null) r'deploy_mode': deploy_mode?.toJson(),
  };
}

/// Generated from `DepositCostFailureReason`.
enum DepositCostFailureReason {
  NotEnoughBalance(r'NotEnoughBalance'),
  LackBalanceForState(r'LackBalanceForState');

  const DepositCostFailureReason(this.wireValue);
  final String wireValue;

  static DepositCostFailureReason fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Generated from `DetailedDebugStatus`.
class DetailedDebugStatus {
  const DetailedDebugStatus({
    this.block_production_delay_millis,
    this.catchup_status,
    this.current_head_status,
    this.current_header_head_status,
    this.network_info,
    this.sync_status,
  });

  factory DetailedDebugStatus.fromJson(Map<String, dynamic> json) =>
      DetailedDebugStatus(
        block_production_delay_millis:
            json[r'block_production_delay_millis'] == null
            ? null
            : (json[r'block_production_delay_millis'] as num).toInt(),
        catchup_status: json[r'catchup_status'] == null
            ? null
            : (json[r'catchup_status'] as List)
                  .map<CatchupStatusView>((e) => CatchupStatusView.fromJson(e))
                  .toList(),
        current_head_status: json[r'current_head_status'] == null
            ? null
            : BlockStatusView.fromJson(json[r'current_head_status']),
        current_header_head_status: json[r'current_header_head_status'] == null
            ? null
            : BlockStatusView.fromJson(json[r'current_header_head_status']),
        network_info: json[r'network_info'] == null
            ? null
            : NetworkInfoView.fromJson(json[r'network_info']),
        sync_status: json[r'sync_status'] == null
            ? null
            : json[r'sync_status'] as String,
      );

  final int? block_production_delay_millis;
  final List<CatchupStatusView>? catchup_status;
  final BlockStatusView? current_head_status;
  final BlockStatusView? current_header_head_status;
  final NetworkInfoView? network_info;
  final String? sync_status;

  Map<String, dynamic> toJson() => {
    if (block_production_delay_millis != null)
      r'block_production_delay_millis': block_production_delay_millis,
    if (catchup_status != null)
      r'catchup_status': catchup_status?.map((e) => e.toJson()).toList(),
    if (current_head_status != null)
      r'current_head_status': current_head_status?.toJson(),
    if (current_header_head_status != null)
      r'current_header_head_status': current_header_head_status?.toJson(),
    if (network_info != null) r'network_info': network_info?.toJson(),
    if (sync_status != null) r'sync_status': sync_status,
  };
}

/// Union type generated from `DeterministicAccountStateInit`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class DeterministicAccountStateInit {
  const DeterministicAccountStateInit(this.json);
  factory DeterministicAccountStateInit.fromJson(dynamic json) =>
      DeterministicAccountStateInit(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `DeterministicAccountStateInitV1`.
class DeterministicAccountStateInitV1 {
  const DeterministicAccountStateInitV1({this.code, this.data});

  factory DeterministicAccountStateInitV1.fromJson(Map<String, dynamic> json) =>
      DeterministicAccountStateInitV1(
        code: json[r'code'] == null
            ? null
            : GlobalContractIdentifier.fromJson(json[r'code']),
        data: json[r'data'] == null
            ? null
            : (json[r'data'] as Map).map(
                (k, v) => MapEntry(k as String, v as String),
              ),
      );

  final GlobalContractIdentifier? code;
  final Map<String, String>? data;

  Map<String, dynamic> toJson() => {
    if (code != null) r'code': code?.toJson(),
    if (data != null) r'data': data,
  };
}

/// Generated from `DeterministicStateInitAction`.
class DeterministicStateInitAction {
  const DeterministicStateInitAction({this.deposit, this.state_init});

  factory DeterministicStateInitAction.fromJson(Map<String, dynamic> json) =>
      DeterministicStateInitAction(
        deposit: json[r'deposit'] == null
            ? null
            : json[r'deposit'] as NearToken,
        state_init: json[r'state_init'] == null
            ? null
            : DeterministicAccountStateInit.fromJson(json[r'state_init']),
      );

  final NearToken? deposit;
  final DeterministicAccountStateInit? state_init;

  Map<String, dynamic> toJson() => {
    if (deposit != null) r'deposit': deposit,
    if (state_init != null) r'state_init': state_init?.toJson(),
  };
}

/// Generated from `Direction`.
enum Direction {
  Left(r'Left'),
  Right(r'Right');

  const Direction(this.wireValue);
  final String wireValue;

  static Direction fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Generated from `DumpConfig`.
class DumpConfig {
  const DumpConfig({
    this.credentials_file,
    this.iteration_delay,
    this.location,
    this.restart_dump_for_shards,
  });

  factory DumpConfig.fromJson(Map<String, dynamic> json) => DumpConfig(
    credentials_file: json[r'credentials_file'] == null
        ? null
        : json[r'credentials_file'] as String,
    iteration_delay: json[r'iteration_delay'] == null
        ? null
        : json[r'iteration_delay'],
    location: json[r'location'] == null
        ? null
        : ExternalStorageLocation.fromJson(json[r'location']),
    restart_dump_for_shards: json[r'restart_dump_for_shards'] == null
        ? null
        : (json[r'restart_dump_for_shards'] as List)
              .map<ShardId>((e) => e as ShardId)
              .toList(),
  );

  final String? credentials_file;
  final dynamic? iteration_delay;
  final ExternalStorageLocation? location;
  final List<ShardId>? restart_dump_for_shards;

  Map<String, dynamic> toJson() => {
    if (credentials_file != null) r'credentials_file': credentials_file,
    if (iteration_delay != null) r'iteration_delay': iteration_delay,
    if (location != null) r'location': location?.toJson(),
    if (restart_dump_for_shards != null)
      r'restart_dump_for_shards': restart_dump_for_shards,
  };
}

/// Generated from `DurationAsStdSchemaProvider`.
class DurationAsStdSchemaProvider {
  const DurationAsStdSchemaProvider({this.nanos, this.secs});

  factory DurationAsStdSchemaProvider.fromJson(Map<String, dynamic> json) =>
      DurationAsStdSchemaProvider(
        nanos: json[r'nanos'] == null ? null : (json[r'nanos'] as num).toInt(),
        secs: json[r'secs'] == null ? null : (json[r'secs'] as num).toInt(),
      );

  final int? nanos;
  final int? secs;

  Map<String, dynamic> toJson() => {
    if (nanos != null) r'nanos': nanos,
    if (secs != null) r'secs': secs,
  };
}

/// Generated from `EpochId`.
class EpochId {
  const EpochId();

  factory EpochId.fromJson(Map<String, dynamic> json) => EpochId();

  Map<String, dynamic> toJson() => {};
}

/// Generated from `EpochSyncConfig`.
class EpochSyncConfig {
  const EpochSyncConfig({
    this.epoch_sync_horizon_num_epochs,
    this.timeout_for_epoch_sync,
  });

  factory EpochSyncConfig.fromJson(Map<String, dynamic> json) =>
      EpochSyncConfig(
        epoch_sync_horizon_num_epochs:
            json[r'epoch_sync_horizon_num_epochs'] == null
            ? null
            : (json[r'epoch_sync_horizon_num_epochs'] as num).toInt(),
        timeout_for_epoch_sync: json[r'timeout_for_epoch_sync'] == null
            ? null
            : DurationAsStdSchemaProvider.fromJson(
                json[r'timeout_for_epoch_sync'],
              ),
      );

  final int? epoch_sync_horizon_num_epochs;
  final DurationAsStdSchemaProvider? timeout_for_epoch_sync;

  Map<String, dynamic> toJson() => {
    if (epoch_sync_horizon_num_epochs != null)
      r'epoch_sync_horizon_num_epochs': epoch_sync_horizon_num_epochs,
    if (timeout_for_epoch_sync != null)
      r'timeout_for_epoch_sync': timeout_for_epoch_sync?.toJson(),
  };
}

/// Union type generated from `ErrorWrapper_for_GenesisConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_GenesisConfigError {
  const ErrorWrapper_for_GenesisConfigError(this.json);
  factory ErrorWrapper_for_GenesisConfigError.fromJson(dynamic json) =>
      ErrorWrapper_for_GenesisConfigError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcBlockError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcBlockError {
  const ErrorWrapper_for_RpcBlockError(this.json);
  factory ErrorWrapper_for_RpcBlockError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcBlockError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcCallFunctionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcCallFunctionError {
  const ErrorWrapper_for_RpcCallFunctionError(this.json);
  factory ErrorWrapper_for_RpcCallFunctionError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcCallFunctionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcChunkError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcChunkError {
  const ErrorWrapper_for_RpcChunkError(this.json);
  factory ErrorWrapper_for_RpcChunkError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcChunkError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcClientConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcClientConfigError {
  const ErrorWrapper_for_RpcClientConfigError(this.json);
  factory ErrorWrapper_for_RpcClientConfigError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcClientConfigError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcGasPriceError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcGasPriceError {
  const ErrorWrapper_for_RpcGasPriceError(this.json);
  factory ErrorWrapper_for_RpcGasPriceError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcGasPriceError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcLightClientNextBlockError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcLightClientNextBlockError {
  const ErrorWrapper_for_RpcLightClientNextBlockError(this.json);
  factory ErrorWrapper_for_RpcLightClientNextBlockError.fromJson(
    dynamic json,
  ) => ErrorWrapper_for_RpcLightClientNextBlockError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcLightClientProofError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcLightClientProofError {
  const ErrorWrapper_for_RpcLightClientProofError(this.json);
  factory ErrorWrapper_for_RpcLightClientProofError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcLightClientProofError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcMaintenanceWindowsError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcMaintenanceWindowsError {
  const ErrorWrapper_for_RpcMaintenanceWindowsError(this.json);
  factory ErrorWrapper_for_RpcMaintenanceWindowsError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcMaintenanceWindowsError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcNetworkInfoError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcNetworkInfoError {
  const ErrorWrapper_for_RpcNetworkInfoError(this.json);
  factory ErrorWrapper_for_RpcNetworkInfoError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcNetworkInfoError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcProtocolConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcProtocolConfigError {
  const ErrorWrapper_for_RpcProtocolConfigError(this.json);
  factory ErrorWrapper_for_RpcProtocolConfigError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcProtocolConfigError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcQueryError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcQueryError {
  const ErrorWrapper_for_RpcQueryError(this.json);
  factory ErrorWrapper_for_RpcQueryError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcQueryError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcReceiptError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcReceiptError {
  const ErrorWrapper_for_RpcReceiptError(this.json);
  factory ErrorWrapper_for_RpcReceiptError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcReceiptError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcReceiptToTxError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcReceiptToTxError {
  const ErrorWrapper_for_RpcReceiptToTxError(this.json);
  factory ErrorWrapper_for_RpcReceiptToTxError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcReceiptToTxError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcSplitStorageInfoError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcSplitStorageInfoError {
  const ErrorWrapper_for_RpcSplitStorageInfoError(this.json);
  factory ErrorWrapper_for_RpcSplitStorageInfoError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcSplitStorageInfoError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcStateChangesError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcStateChangesError {
  const ErrorWrapper_for_RpcStateChangesError(this.json);
  factory ErrorWrapper_for_RpcStateChangesError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcStateChangesError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcStatusError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcStatusError {
  const ErrorWrapper_for_RpcStatusError(this.json);
  factory ErrorWrapper_for_RpcStatusError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcStatusError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcTransactionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcTransactionError {
  const ErrorWrapper_for_RpcTransactionError(this.json);
  factory ErrorWrapper_for_RpcTransactionError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcTransactionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcValidatorError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcValidatorError {
  const ErrorWrapper_for_RpcValidatorError(this.json);
  factory ErrorWrapper_for_RpcValidatorError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcValidatorError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcViewAccessKeyError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcViewAccessKeyError {
  const ErrorWrapper_for_RpcViewAccessKeyError(this.json);
  factory ErrorWrapper_for_RpcViewAccessKeyError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcViewAccessKeyError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcViewAccessKeyListError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcViewAccessKeyListError {
  const ErrorWrapper_for_RpcViewAccessKeyListError(this.json);
  factory ErrorWrapper_for_RpcViewAccessKeyListError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcViewAccessKeyListError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcViewAccountError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcViewAccountError {
  const ErrorWrapper_for_RpcViewAccountError(this.json);
  factory ErrorWrapper_for_RpcViewAccountError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcViewAccountError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcViewCodeError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcViewCodeError {
  const ErrorWrapper_for_RpcViewCodeError(this.json);
  factory ErrorWrapper_for_RpcViewCodeError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcViewCodeError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ErrorWrapper_for_RpcViewStateError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ErrorWrapper_for_RpcViewStateError {
  const ErrorWrapper_for_RpcViewStateError(this.json);
  factory ErrorWrapper_for_RpcViewStateError.fromJson(dynamic json) =>
      ErrorWrapper_for_RpcViewStateError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ExecutionMetadataView`.
class ExecutionMetadataView {
  const ExecutionMetadataView({this.contracts, this.gas_profile, this.version});

  factory ExecutionMetadataView.fromJson(Map<String, dynamic> json) =>
      ExecutionMetadataView(
        contracts: json[r'contracts'] == null
            ? null
            : (json[r'contracts'] as List).map<dynamic>((e) => e).toList(),
        gas_profile: json[r'gas_profile'] == null
            ? null
            : (json[r'gas_profile'] as List)
                  .map<CostGasUsed>((e) => CostGasUsed.fromJson(e))
                  .toList(),
        version: json[r'version'] == null
            ? null
            : (json[r'version'] as num).toInt(),
      );

  final List<dynamic>? contracts;
  final List<CostGasUsed>? gas_profile;
  final int? version;

  Map<String, dynamic> toJson() => {
    if (contracts != null) r'contracts': contracts,
    if (gas_profile != null)
      r'gas_profile': gas_profile?.map((e) => e.toJson()).toList(),
    if (version != null) r'version': version,
  };
}

/// Generated from `ExecutionOutcomeView`.
class ExecutionOutcomeView {
  const ExecutionOutcomeView({
    this.executor_id,
    this.gas_burnt,
    this.logs,
    this.metadata,
    this.receipt_ids,
    this.status,
    this.tokens_burnt,
  });

  factory ExecutionOutcomeView.fromJson(Map<String, dynamic> json) =>
      ExecutionOutcomeView(
        executor_id: json[r'executor_id'] == null
            ? null
            : json[r'executor_id'] as AccountId,
        gas_burnt: json[r'gas_burnt'] == null
            ? null
            : json[r'gas_burnt'] as NearGas,
        logs: json[r'logs'] == null
            ? null
            : (json[r'logs'] as List).map<String>((e) => e as String).toList(),
        metadata: json[r'metadata'] == null
            ? null
            : ExecutionMetadataView.fromJson(json[r'metadata']),
        receipt_ids: json[r'receipt_ids'] == null
            ? null
            : (json[r'receipt_ids'] as List)
                  .map<CryptoHash>((e) => e as CryptoHash)
                  .toList(),
        status: json[r'status'] == null
            ? null
            : ExecutionStatusView.fromJson(json[r'status']),
        tokens_burnt: json[r'tokens_burnt'] == null
            ? null
            : json[r'tokens_burnt'] as NearToken,
      );

  final AccountId? executor_id;
  final NearGas? gas_burnt;
  final List<String>? logs;
  final ExecutionMetadataView? metadata;
  final List<CryptoHash>? receipt_ids;
  final ExecutionStatusView? status;
  final NearToken? tokens_burnt;

  Map<String, dynamic> toJson() => {
    if (executor_id != null) r'executor_id': executor_id,
    if (gas_burnt != null) r'gas_burnt': gas_burnt,
    if (logs != null) r'logs': logs,
    if (metadata != null) r'metadata': metadata?.toJson(),
    if (receipt_ids != null) r'receipt_ids': receipt_ids,
    if (status != null) r'status': status?.toJson(),
    if (tokens_burnt != null) r'tokens_burnt': tokens_burnt,
  };
}

/// Generated from `ExecutionOutcomeWithIdView`.
class ExecutionOutcomeWithIdView {
  const ExecutionOutcomeWithIdView({
    this.block_hash,
    this.id,
    this.outcome,
    this.proof,
  });

  factory ExecutionOutcomeWithIdView.fromJson(Map<String, dynamic> json) =>
      ExecutionOutcomeWithIdView(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        id: json[r'id'] == null ? null : json[r'id'] as CryptoHash,
        outcome: json[r'outcome'] == null
            ? null
            : ExecutionOutcomeView.fromJson(json[r'outcome']),
        proof: json[r'proof'] == null
            ? null
            : (json[r'proof'] as List)
                  .map<MerklePathItem>((e) => MerklePathItem.fromJson(e))
                  .toList(),
      );

  final CryptoHash? block_hash;
  final CryptoHash? id;
  final ExecutionOutcomeView? outcome;
  final List<MerklePathItem>? proof;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (id != null) r'id': id,
    if (outcome != null) r'outcome': outcome?.toJson(),
    if (proof != null) r'proof': proof?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `ExecutionStatusView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ExecutionStatusView {
  const ExecutionStatusView(this.json);
  factory ExecutionStatusView.fromJson(dynamic json) =>
      ExecutionStatusView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ExtCostsConfigView`.
class ExtCostsConfigView {
  const ExtCostsConfigView({
    this.alt_bn128_g1_multiexp_base,
    this.alt_bn128_g1_multiexp_element,
    this.alt_bn128_g1_sum_base,
    this.alt_bn128_g1_sum_element,
    this.alt_bn128_pairing_check_base,
    this.alt_bn128_pairing_check_element,
    this.base,
    this.bls12381_g1_multiexp_base,
    this.bls12381_g1_multiexp_element,
    this.bls12381_g2_multiexp_base,
    this.bls12381_g2_multiexp_element,
    this.bls12381_map_fp2_to_g2_base,
    this.bls12381_map_fp2_to_g2_element,
    this.bls12381_map_fp_to_g1_base,
    this.bls12381_map_fp_to_g1_element,
    this.bls12381_p1_decompress_base,
    this.bls12381_p1_decompress_element,
    this.bls12381_p1_sum_base,
    this.bls12381_p1_sum_element,
    this.bls12381_p2_decompress_base,
    this.bls12381_p2_decompress_element,
    this.bls12381_p2_sum_base,
    this.bls12381_p2_sum_element,
    this.bls12381_pairing_base,
    this.bls12381_pairing_element,
    this.contract_compile_base,
    this.contract_compile_bytes,
    this.contract_loading_base,
    this.contract_loading_bytes,
    this.ecrecover_base,
    this.ed25519_verify_base,
    this.ed25519_verify_byte,
    this.keccak256_base,
    this.keccak256_byte,
    this.keccak512_base,
    this.keccak512_byte,
    this.log_base,
    this.log_byte,
    this.p256_verify_base,
    this.p256_verify_byte,
    this.promise_and_base,
    this.promise_and_per_promise,
    this.promise_return,
    this.read_cached_trie_node,
    this.read_memory_base,
    this.read_memory_byte,
    this.read_register_base,
    this.read_register_byte,
    this.ripemd160_base,
    this.ripemd160_block,
    this.sha256_base,
    this.sha256_byte,
    this.storage_has_key_base,
    this.storage_has_key_byte,
    this.storage_iter_create_from_byte,
    this.storage_iter_create_prefix_base,
    this.storage_iter_create_prefix_byte,
    this.storage_iter_create_range_base,
    this.storage_iter_create_to_byte,
    this.storage_iter_next_base,
    this.storage_iter_next_key_byte,
    this.storage_iter_next_value_byte,
    this.storage_large_read_overhead_base,
    this.storage_large_read_overhead_byte,
    this.storage_read_base,
    this.storage_read_key_byte,
    this.storage_read_value_byte,
    this.storage_remove_base,
    this.storage_remove_key_byte,
    this.storage_remove_ret_value_byte,
    this.storage_write_base,
    this.storage_write_evicted_byte,
    this.storage_write_key_byte,
    this.storage_write_value_byte,
    this.touching_trie_node,
    this.utf16_decoding_base,
    this.utf16_decoding_byte,
    this.utf8_decoding_base,
    this.utf8_decoding_byte,
    this.validator_stake_base,
    this.validator_total_stake_base,
    this.write_memory_base,
    this.write_memory_byte,
    this.write_register_base,
    this.write_register_byte,
    this.yield_create_base,
    this.yield_create_byte,
    this.yield_create_with_id_base,
    this.yield_resume_base,
    this.yield_resume_byte,
  });

  factory ExtCostsConfigView.fromJson(
    Map<String, dynamic> json,
  ) => ExtCostsConfigView(
    alt_bn128_g1_multiexp_base: json[r'alt_bn128_g1_multiexp_base'] == null
        ? null
        : json[r'alt_bn128_g1_multiexp_base'] as NearGas,
    alt_bn128_g1_multiexp_element:
        json[r'alt_bn128_g1_multiexp_element'] == null
        ? null
        : json[r'alt_bn128_g1_multiexp_element'] as NearGas,
    alt_bn128_g1_sum_base: json[r'alt_bn128_g1_sum_base'] == null
        ? null
        : json[r'alt_bn128_g1_sum_base'] as NearGas,
    alt_bn128_g1_sum_element: json[r'alt_bn128_g1_sum_element'] == null
        ? null
        : json[r'alt_bn128_g1_sum_element'] as NearGas,
    alt_bn128_pairing_check_base: json[r'alt_bn128_pairing_check_base'] == null
        ? null
        : json[r'alt_bn128_pairing_check_base'] as NearGas,
    alt_bn128_pairing_check_element:
        json[r'alt_bn128_pairing_check_element'] == null
        ? null
        : json[r'alt_bn128_pairing_check_element'] as NearGas,
    base: json[r'base'] == null ? null : json[r'base'] as NearGas,
    bls12381_g1_multiexp_base: json[r'bls12381_g1_multiexp_base'] == null
        ? null
        : json[r'bls12381_g1_multiexp_base'] as NearGas,
    bls12381_g1_multiexp_element: json[r'bls12381_g1_multiexp_element'] == null
        ? null
        : json[r'bls12381_g1_multiexp_element'] as NearGas,
    bls12381_g2_multiexp_base: json[r'bls12381_g2_multiexp_base'] == null
        ? null
        : json[r'bls12381_g2_multiexp_base'] as NearGas,
    bls12381_g2_multiexp_element: json[r'bls12381_g2_multiexp_element'] == null
        ? null
        : json[r'bls12381_g2_multiexp_element'] as NearGas,
    bls12381_map_fp2_to_g2_base: json[r'bls12381_map_fp2_to_g2_base'] == null
        ? null
        : json[r'bls12381_map_fp2_to_g2_base'] as NearGas,
    bls12381_map_fp2_to_g2_element:
        json[r'bls12381_map_fp2_to_g2_element'] == null
        ? null
        : json[r'bls12381_map_fp2_to_g2_element'] as NearGas,
    bls12381_map_fp_to_g1_base: json[r'bls12381_map_fp_to_g1_base'] == null
        ? null
        : json[r'bls12381_map_fp_to_g1_base'] as NearGas,
    bls12381_map_fp_to_g1_element:
        json[r'bls12381_map_fp_to_g1_element'] == null
        ? null
        : json[r'bls12381_map_fp_to_g1_element'] as NearGas,
    bls12381_p1_decompress_base: json[r'bls12381_p1_decompress_base'] == null
        ? null
        : json[r'bls12381_p1_decompress_base'] as NearGas,
    bls12381_p1_decompress_element:
        json[r'bls12381_p1_decompress_element'] == null
        ? null
        : json[r'bls12381_p1_decompress_element'] as NearGas,
    bls12381_p1_sum_base: json[r'bls12381_p1_sum_base'] == null
        ? null
        : json[r'bls12381_p1_sum_base'] as NearGas,
    bls12381_p1_sum_element: json[r'bls12381_p1_sum_element'] == null
        ? null
        : json[r'bls12381_p1_sum_element'] as NearGas,
    bls12381_p2_decompress_base: json[r'bls12381_p2_decompress_base'] == null
        ? null
        : json[r'bls12381_p2_decompress_base'] as NearGas,
    bls12381_p2_decompress_element:
        json[r'bls12381_p2_decompress_element'] == null
        ? null
        : json[r'bls12381_p2_decompress_element'] as NearGas,
    bls12381_p2_sum_base: json[r'bls12381_p2_sum_base'] == null
        ? null
        : json[r'bls12381_p2_sum_base'] as NearGas,
    bls12381_p2_sum_element: json[r'bls12381_p2_sum_element'] == null
        ? null
        : json[r'bls12381_p2_sum_element'] as NearGas,
    bls12381_pairing_base: json[r'bls12381_pairing_base'] == null
        ? null
        : json[r'bls12381_pairing_base'] as NearGas,
    bls12381_pairing_element: json[r'bls12381_pairing_element'] == null
        ? null
        : json[r'bls12381_pairing_element'] as NearGas,
    contract_compile_base: json[r'contract_compile_base'] == null
        ? null
        : json[r'contract_compile_base'] as NearGas,
    contract_compile_bytes: json[r'contract_compile_bytes'] == null
        ? null
        : json[r'contract_compile_bytes'] as NearGas,
    contract_loading_base: json[r'contract_loading_base'] == null
        ? null
        : json[r'contract_loading_base'] as NearGas,
    contract_loading_bytes: json[r'contract_loading_bytes'] == null
        ? null
        : json[r'contract_loading_bytes'] as NearGas,
    ecrecover_base: json[r'ecrecover_base'] == null
        ? null
        : json[r'ecrecover_base'] as NearGas,
    ed25519_verify_base: json[r'ed25519_verify_base'] == null
        ? null
        : json[r'ed25519_verify_base'] as NearGas,
    ed25519_verify_byte: json[r'ed25519_verify_byte'] == null
        ? null
        : json[r'ed25519_verify_byte'] as NearGas,
    keccak256_base: json[r'keccak256_base'] == null
        ? null
        : json[r'keccak256_base'] as NearGas,
    keccak256_byte: json[r'keccak256_byte'] == null
        ? null
        : json[r'keccak256_byte'] as NearGas,
    keccak512_base: json[r'keccak512_base'] == null
        ? null
        : json[r'keccak512_base'] as NearGas,
    keccak512_byte: json[r'keccak512_byte'] == null
        ? null
        : json[r'keccak512_byte'] as NearGas,
    log_base: json[r'log_base'] == null ? null : json[r'log_base'] as NearGas,
    log_byte: json[r'log_byte'] == null ? null : json[r'log_byte'] as NearGas,
    p256_verify_base: json[r'p256_verify_base'] == null
        ? null
        : json[r'p256_verify_base'] as NearGas,
    p256_verify_byte: json[r'p256_verify_byte'] == null
        ? null
        : json[r'p256_verify_byte'] as NearGas,
    promise_and_base: json[r'promise_and_base'] == null
        ? null
        : json[r'promise_and_base'] as NearGas,
    promise_and_per_promise: json[r'promise_and_per_promise'] == null
        ? null
        : json[r'promise_and_per_promise'] as NearGas,
    promise_return: json[r'promise_return'] == null
        ? null
        : json[r'promise_return'] as NearGas,
    read_cached_trie_node: json[r'read_cached_trie_node'] == null
        ? null
        : json[r'read_cached_trie_node'] as NearGas,
    read_memory_base: json[r'read_memory_base'] == null
        ? null
        : json[r'read_memory_base'] as NearGas,
    read_memory_byte: json[r'read_memory_byte'] == null
        ? null
        : json[r'read_memory_byte'] as NearGas,
    read_register_base: json[r'read_register_base'] == null
        ? null
        : json[r'read_register_base'] as NearGas,
    read_register_byte: json[r'read_register_byte'] == null
        ? null
        : json[r'read_register_byte'] as NearGas,
    ripemd160_base: json[r'ripemd160_base'] == null
        ? null
        : json[r'ripemd160_base'] as NearGas,
    ripemd160_block: json[r'ripemd160_block'] == null
        ? null
        : json[r'ripemd160_block'] as NearGas,
    sha256_base: json[r'sha256_base'] == null
        ? null
        : json[r'sha256_base'] as NearGas,
    sha256_byte: json[r'sha256_byte'] == null
        ? null
        : json[r'sha256_byte'] as NearGas,
    storage_has_key_base: json[r'storage_has_key_base'] == null
        ? null
        : json[r'storage_has_key_base'] as NearGas,
    storage_has_key_byte: json[r'storage_has_key_byte'] == null
        ? null
        : json[r'storage_has_key_byte'] as NearGas,
    storage_iter_create_from_byte:
        json[r'storage_iter_create_from_byte'] == null
        ? null
        : json[r'storage_iter_create_from_byte'] as NearGas,
    storage_iter_create_prefix_base:
        json[r'storage_iter_create_prefix_base'] == null
        ? null
        : json[r'storage_iter_create_prefix_base'] as NearGas,
    storage_iter_create_prefix_byte:
        json[r'storage_iter_create_prefix_byte'] == null
        ? null
        : json[r'storage_iter_create_prefix_byte'] as NearGas,
    storage_iter_create_range_base:
        json[r'storage_iter_create_range_base'] == null
        ? null
        : json[r'storage_iter_create_range_base'] as NearGas,
    storage_iter_create_to_byte: json[r'storage_iter_create_to_byte'] == null
        ? null
        : json[r'storage_iter_create_to_byte'] as NearGas,
    storage_iter_next_base: json[r'storage_iter_next_base'] == null
        ? null
        : json[r'storage_iter_next_base'] as NearGas,
    storage_iter_next_key_byte: json[r'storage_iter_next_key_byte'] == null
        ? null
        : json[r'storage_iter_next_key_byte'] as NearGas,
    storage_iter_next_value_byte: json[r'storage_iter_next_value_byte'] == null
        ? null
        : json[r'storage_iter_next_value_byte'] as NearGas,
    storage_large_read_overhead_base:
        json[r'storage_large_read_overhead_base'] == null
        ? null
        : json[r'storage_large_read_overhead_base'] as NearGas,
    storage_large_read_overhead_byte:
        json[r'storage_large_read_overhead_byte'] == null
        ? null
        : json[r'storage_large_read_overhead_byte'] as NearGas,
    storage_read_base: json[r'storage_read_base'] == null
        ? null
        : json[r'storage_read_base'] as NearGas,
    storage_read_key_byte: json[r'storage_read_key_byte'] == null
        ? null
        : json[r'storage_read_key_byte'] as NearGas,
    storage_read_value_byte: json[r'storage_read_value_byte'] == null
        ? null
        : json[r'storage_read_value_byte'] as NearGas,
    storage_remove_base: json[r'storage_remove_base'] == null
        ? null
        : json[r'storage_remove_base'] as NearGas,
    storage_remove_key_byte: json[r'storage_remove_key_byte'] == null
        ? null
        : json[r'storage_remove_key_byte'] as NearGas,
    storage_remove_ret_value_byte:
        json[r'storage_remove_ret_value_byte'] == null
        ? null
        : json[r'storage_remove_ret_value_byte'] as NearGas,
    storage_write_base: json[r'storage_write_base'] == null
        ? null
        : json[r'storage_write_base'] as NearGas,
    storage_write_evicted_byte: json[r'storage_write_evicted_byte'] == null
        ? null
        : json[r'storage_write_evicted_byte'] as NearGas,
    storage_write_key_byte: json[r'storage_write_key_byte'] == null
        ? null
        : json[r'storage_write_key_byte'] as NearGas,
    storage_write_value_byte: json[r'storage_write_value_byte'] == null
        ? null
        : json[r'storage_write_value_byte'] as NearGas,
    touching_trie_node: json[r'touching_trie_node'] == null
        ? null
        : json[r'touching_trie_node'] as NearGas,
    utf16_decoding_base: json[r'utf16_decoding_base'] == null
        ? null
        : json[r'utf16_decoding_base'] as NearGas,
    utf16_decoding_byte: json[r'utf16_decoding_byte'] == null
        ? null
        : json[r'utf16_decoding_byte'] as NearGas,
    utf8_decoding_base: json[r'utf8_decoding_base'] == null
        ? null
        : json[r'utf8_decoding_base'] as NearGas,
    utf8_decoding_byte: json[r'utf8_decoding_byte'] == null
        ? null
        : json[r'utf8_decoding_byte'] as NearGas,
    validator_stake_base: json[r'validator_stake_base'] == null
        ? null
        : json[r'validator_stake_base'] as NearGas,
    validator_total_stake_base: json[r'validator_total_stake_base'] == null
        ? null
        : json[r'validator_total_stake_base'] as NearGas,
    write_memory_base: json[r'write_memory_base'] == null
        ? null
        : json[r'write_memory_base'] as NearGas,
    write_memory_byte: json[r'write_memory_byte'] == null
        ? null
        : json[r'write_memory_byte'] as NearGas,
    write_register_base: json[r'write_register_base'] == null
        ? null
        : json[r'write_register_base'] as NearGas,
    write_register_byte: json[r'write_register_byte'] == null
        ? null
        : json[r'write_register_byte'] as NearGas,
    yield_create_base: json[r'yield_create_base'] == null
        ? null
        : json[r'yield_create_base'] as NearGas,
    yield_create_byte: json[r'yield_create_byte'] == null
        ? null
        : json[r'yield_create_byte'] as NearGas,
    yield_create_with_id_base: json[r'yield_create_with_id_base'] == null
        ? null
        : json[r'yield_create_with_id_base'] as NearGas,
    yield_resume_base: json[r'yield_resume_base'] == null
        ? null
        : json[r'yield_resume_base'] as NearGas,
    yield_resume_byte: json[r'yield_resume_byte'] == null
        ? null
        : json[r'yield_resume_byte'] as NearGas,
  );

  final NearGas? alt_bn128_g1_multiexp_base;
  final NearGas? alt_bn128_g1_multiexp_element;
  final NearGas? alt_bn128_g1_sum_base;
  final NearGas? alt_bn128_g1_sum_element;
  final NearGas? alt_bn128_pairing_check_base;
  final NearGas? alt_bn128_pairing_check_element;
  final NearGas? base;
  final NearGas? bls12381_g1_multiexp_base;
  final NearGas? bls12381_g1_multiexp_element;
  final NearGas? bls12381_g2_multiexp_base;
  final NearGas? bls12381_g2_multiexp_element;
  final NearGas? bls12381_map_fp2_to_g2_base;
  final NearGas? bls12381_map_fp2_to_g2_element;
  final NearGas? bls12381_map_fp_to_g1_base;
  final NearGas? bls12381_map_fp_to_g1_element;
  final NearGas? bls12381_p1_decompress_base;
  final NearGas? bls12381_p1_decompress_element;
  final NearGas? bls12381_p1_sum_base;
  final NearGas? bls12381_p1_sum_element;
  final NearGas? bls12381_p2_decompress_base;
  final NearGas? bls12381_p2_decompress_element;
  final NearGas? bls12381_p2_sum_base;
  final NearGas? bls12381_p2_sum_element;
  final NearGas? bls12381_pairing_base;
  final NearGas? bls12381_pairing_element;
  final NearGas? contract_compile_base;
  final NearGas? contract_compile_bytes;
  final NearGas? contract_loading_base;
  final NearGas? contract_loading_bytes;
  final NearGas? ecrecover_base;
  final NearGas? ed25519_verify_base;
  final NearGas? ed25519_verify_byte;
  final NearGas? keccak256_base;
  final NearGas? keccak256_byte;
  final NearGas? keccak512_base;
  final NearGas? keccak512_byte;
  final NearGas? log_base;
  final NearGas? log_byte;
  final NearGas? p256_verify_base;
  final NearGas? p256_verify_byte;
  final NearGas? promise_and_base;
  final NearGas? promise_and_per_promise;
  final NearGas? promise_return;
  final NearGas? read_cached_trie_node;
  final NearGas? read_memory_base;
  final NearGas? read_memory_byte;
  final NearGas? read_register_base;
  final NearGas? read_register_byte;
  final NearGas? ripemd160_base;
  final NearGas? ripemd160_block;
  final NearGas? sha256_base;
  final NearGas? sha256_byte;
  final NearGas? storage_has_key_base;
  final NearGas? storage_has_key_byte;
  final NearGas? storage_iter_create_from_byte;
  final NearGas? storage_iter_create_prefix_base;
  final NearGas? storage_iter_create_prefix_byte;
  final NearGas? storage_iter_create_range_base;
  final NearGas? storage_iter_create_to_byte;
  final NearGas? storage_iter_next_base;
  final NearGas? storage_iter_next_key_byte;
  final NearGas? storage_iter_next_value_byte;
  final NearGas? storage_large_read_overhead_base;
  final NearGas? storage_large_read_overhead_byte;
  final NearGas? storage_read_base;
  final NearGas? storage_read_key_byte;
  final NearGas? storage_read_value_byte;
  final NearGas? storage_remove_base;
  final NearGas? storage_remove_key_byte;
  final NearGas? storage_remove_ret_value_byte;
  final NearGas? storage_write_base;
  final NearGas? storage_write_evicted_byte;
  final NearGas? storage_write_key_byte;
  final NearGas? storage_write_value_byte;
  final NearGas? touching_trie_node;
  final NearGas? utf16_decoding_base;
  final NearGas? utf16_decoding_byte;
  final NearGas? utf8_decoding_base;
  final NearGas? utf8_decoding_byte;
  final NearGas? validator_stake_base;
  final NearGas? validator_total_stake_base;
  final NearGas? write_memory_base;
  final NearGas? write_memory_byte;
  final NearGas? write_register_base;
  final NearGas? write_register_byte;
  final NearGas? yield_create_base;
  final NearGas? yield_create_byte;
  final NearGas? yield_create_with_id_base;
  final NearGas? yield_resume_base;
  final NearGas? yield_resume_byte;

  Map<String, dynamic> toJson() => {
    if (alt_bn128_g1_multiexp_base != null)
      r'alt_bn128_g1_multiexp_base': alt_bn128_g1_multiexp_base,
    if (alt_bn128_g1_multiexp_element != null)
      r'alt_bn128_g1_multiexp_element': alt_bn128_g1_multiexp_element,
    if (alt_bn128_g1_sum_base != null)
      r'alt_bn128_g1_sum_base': alt_bn128_g1_sum_base,
    if (alt_bn128_g1_sum_element != null)
      r'alt_bn128_g1_sum_element': alt_bn128_g1_sum_element,
    if (alt_bn128_pairing_check_base != null)
      r'alt_bn128_pairing_check_base': alt_bn128_pairing_check_base,
    if (alt_bn128_pairing_check_element != null)
      r'alt_bn128_pairing_check_element': alt_bn128_pairing_check_element,
    if (base != null) r'base': base,
    if (bls12381_g1_multiexp_base != null)
      r'bls12381_g1_multiexp_base': bls12381_g1_multiexp_base,
    if (bls12381_g1_multiexp_element != null)
      r'bls12381_g1_multiexp_element': bls12381_g1_multiexp_element,
    if (bls12381_g2_multiexp_base != null)
      r'bls12381_g2_multiexp_base': bls12381_g2_multiexp_base,
    if (bls12381_g2_multiexp_element != null)
      r'bls12381_g2_multiexp_element': bls12381_g2_multiexp_element,
    if (bls12381_map_fp2_to_g2_base != null)
      r'bls12381_map_fp2_to_g2_base': bls12381_map_fp2_to_g2_base,
    if (bls12381_map_fp2_to_g2_element != null)
      r'bls12381_map_fp2_to_g2_element': bls12381_map_fp2_to_g2_element,
    if (bls12381_map_fp_to_g1_base != null)
      r'bls12381_map_fp_to_g1_base': bls12381_map_fp_to_g1_base,
    if (bls12381_map_fp_to_g1_element != null)
      r'bls12381_map_fp_to_g1_element': bls12381_map_fp_to_g1_element,
    if (bls12381_p1_decompress_base != null)
      r'bls12381_p1_decompress_base': bls12381_p1_decompress_base,
    if (bls12381_p1_decompress_element != null)
      r'bls12381_p1_decompress_element': bls12381_p1_decompress_element,
    if (bls12381_p1_sum_base != null)
      r'bls12381_p1_sum_base': bls12381_p1_sum_base,
    if (bls12381_p1_sum_element != null)
      r'bls12381_p1_sum_element': bls12381_p1_sum_element,
    if (bls12381_p2_decompress_base != null)
      r'bls12381_p2_decompress_base': bls12381_p2_decompress_base,
    if (bls12381_p2_decompress_element != null)
      r'bls12381_p2_decompress_element': bls12381_p2_decompress_element,
    if (bls12381_p2_sum_base != null)
      r'bls12381_p2_sum_base': bls12381_p2_sum_base,
    if (bls12381_p2_sum_element != null)
      r'bls12381_p2_sum_element': bls12381_p2_sum_element,
    if (bls12381_pairing_base != null)
      r'bls12381_pairing_base': bls12381_pairing_base,
    if (bls12381_pairing_element != null)
      r'bls12381_pairing_element': bls12381_pairing_element,
    if (contract_compile_base != null)
      r'contract_compile_base': contract_compile_base,
    if (contract_compile_bytes != null)
      r'contract_compile_bytes': contract_compile_bytes,
    if (contract_loading_base != null)
      r'contract_loading_base': contract_loading_base,
    if (contract_loading_bytes != null)
      r'contract_loading_bytes': contract_loading_bytes,
    if (ecrecover_base != null) r'ecrecover_base': ecrecover_base,
    if (ed25519_verify_base != null)
      r'ed25519_verify_base': ed25519_verify_base,
    if (ed25519_verify_byte != null)
      r'ed25519_verify_byte': ed25519_verify_byte,
    if (keccak256_base != null) r'keccak256_base': keccak256_base,
    if (keccak256_byte != null) r'keccak256_byte': keccak256_byte,
    if (keccak512_base != null) r'keccak512_base': keccak512_base,
    if (keccak512_byte != null) r'keccak512_byte': keccak512_byte,
    if (log_base != null) r'log_base': log_base,
    if (log_byte != null) r'log_byte': log_byte,
    if (p256_verify_base != null) r'p256_verify_base': p256_verify_base,
    if (p256_verify_byte != null) r'p256_verify_byte': p256_verify_byte,
    if (promise_and_base != null) r'promise_and_base': promise_and_base,
    if (promise_and_per_promise != null)
      r'promise_and_per_promise': promise_and_per_promise,
    if (promise_return != null) r'promise_return': promise_return,
    if (read_cached_trie_node != null)
      r'read_cached_trie_node': read_cached_trie_node,
    if (read_memory_base != null) r'read_memory_base': read_memory_base,
    if (read_memory_byte != null) r'read_memory_byte': read_memory_byte,
    if (read_register_base != null) r'read_register_base': read_register_base,
    if (read_register_byte != null) r'read_register_byte': read_register_byte,
    if (ripemd160_base != null) r'ripemd160_base': ripemd160_base,
    if (ripemd160_block != null) r'ripemd160_block': ripemd160_block,
    if (sha256_base != null) r'sha256_base': sha256_base,
    if (sha256_byte != null) r'sha256_byte': sha256_byte,
    if (storage_has_key_base != null)
      r'storage_has_key_base': storage_has_key_base,
    if (storage_has_key_byte != null)
      r'storage_has_key_byte': storage_has_key_byte,
    if (storage_iter_create_from_byte != null)
      r'storage_iter_create_from_byte': storage_iter_create_from_byte,
    if (storage_iter_create_prefix_base != null)
      r'storage_iter_create_prefix_base': storage_iter_create_prefix_base,
    if (storage_iter_create_prefix_byte != null)
      r'storage_iter_create_prefix_byte': storage_iter_create_prefix_byte,
    if (storage_iter_create_range_base != null)
      r'storage_iter_create_range_base': storage_iter_create_range_base,
    if (storage_iter_create_to_byte != null)
      r'storage_iter_create_to_byte': storage_iter_create_to_byte,
    if (storage_iter_next_base != null)
      r'storage_iter_next_base': storage_iter_next_base,
    if (storage_iter_next_key_byte != null)
      r'storage_iter_next_key_byte': storage_iter_next_key_byte,
    if (storage_iter_next_value_byte != null)
      r'storage_iter_next_value_byte': storage_iter_next_value_byte,
    if (storage_large_read_overhead_base != null)
      r'storage_large_read_overhead_base': storage_large_read_overhead_base,
    if (storage_large_read_overhead_byte != null)
      r'storage_large_read_overhead_byte': storage_large_read_overhead_byte,
    if (storage_read_base != null) r'storage_read_base': storage_read_base,
    if (storage_read_key_byte != null)
      r'storage_read_key_byte': storage_read_key_byte,
    if (storage_read_value_byte != null)
      r'storage_read_value_byte': storage_read_value_byte,
    if (storage_remove_base != null)
      r'storage_remove_base': storage_remove_base,
    if (storage_remove_key_byte != null)
      r'storage_remove_key_byte': storage_remove_key_byte,
    if (storage_remove_ret_value_byte != null)
      r'storage_remove_ret_value_byte': storage_remove_ret_value_byte,
    if (storage_write_base != null) r'storage_write_base': storage_write_base,
    if (storage_write_evicted_byte != null)
      r'storage_write_evicted_byte': storage_write_evicted_byte,
    if (storage_write_key_byte != null)
      r'storage_write_key_byte': storage_write_key_byte,
    if (storage_write_value_byte != null)
      r'storage_write_value_byte': storage_write_value_byte,
    if (touching_trie_node != null) r'touching_trie_node': touching_trie_node,
    if (utf16_decoding_base != null)
      r'utf16_decoding_base': utf16_decoding_base,
    if (utf16_decoding_byte != null)
      r'utf16_decoding_byte': utf16_decoding_byte,
    if (utf8_decoding_base != null) r'utf8_decoding_base': utf8_decoding_base,
    if (utf8_decoding_byte != null) r'utf8_decoding_byte': utf8_decoding_byte,
    if (validator_stake_base != null)
      r'validator_stake_base': validator_stake_base,
    if (validator_total_stake_base != null)
      r'validator_total_stake_base': validator_total_stake_base,
    if (write_memory_base != null) r'write_memory_base': write_memory_base,
    if (write_memory_byte != null) r'write_memory_byte': write_memory_byte,
    if (write_register_base != null)
      r'write_register_base': write_register_base,
    if (write_register_byte != null)
      r'write_register_byte': write_register_byte,
    if (yield_create_base != null) r'yield_create_base': yield_create_base,
    if (yield_create_byte != null) r'yield_create_byte': yield_create_byte,
    if (yield_create_with_id_base != null)
      r'yield_create_with_id_base': yield_create_with_id_base,
    if (yield_resume_base != null) r'yield_resume_base': yield_resume_base,
    if (yield_resume_byte != null) r'yield_resume_byte': yield_resume_byte,
  };
}

/// Generated from `ExternalStorageConfig`.
class ExternalStorageConfig {
  const ExternalStorageConfig({
    this.external_storage_fallback_threshold,
    this.location,
    this.num_concurrent_requests,
    this.num_concurrent_requests_during_catchup,
  });

  factory ExternalStorageConfig.fromJson(Map<String, dynamic> json) =>
      ExternalStorageConfig(
        external_storage_fallback_threshold:
            json[r'external_storage_fallback_threshold'] == null
            ? null
            : (json[r'external_storage_fallback_threshold'] as num).toInt(),
        location: json[r'location'] == null
            ? null
            : ExternalStorageLocation.fromJson(json[r'location']),
        num_concurrent_requests: json[r'num_concurrent_requests'] == null
            ? null
            : (json[r'num_concurrent_requests'] as num).toInt(),
        num_concurrent_requests_during_catchup:
            json[r'num_concurrent_requests_during_catchup'] == null
            ? null
            : (json[r'num_concurrent_requests_during_catchup'] as num).toInt(),
      );

  final int? external_storage_fallback_threshold;
  final ExternalStorageLocation? location;
  final int? num_concurrent_requests;
  final int? num_concurrent_requests_during_catchup;

  Map<String, dynamic> toJson() => {
    if (external_storage_fallback_threshold != null)
      r'external_storage_fallback_threshold':
          external_storage_fallback_threshold,
    if (location != null) r'location': location?.toJson(),
    if (num_concurrent_requests != null)
      r'num_concurrent_requests': num_concurrent_requests,
    if (num_concurrent_requests_during_catchup != null)
      r'num_concurrent_requests_during_catchup':
          num_concurrent_requests_during_catchup,
  };
}

/// Union type generated from `ExternalStorageLocation`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ExternalStorageLocation {
  const ExternalStorageLocation(this.json);
  factory ExternalStorageLocation.fromJson(dynamic json) =>
      ExternalStorageLocation(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `Fee`.
class Fee {
  const Fee({this.execution, this.send_not_sir, this.send_sir});

  factory Fee.fromJson(Map<String, dynamic> json) => Fee(
    execution: json[r'execution'] == null
        ? null
        : json[r'execution'] as NearGas,
    send_not_sir: json[r'send_not_sir'] == null
        ? null
        : json[r'send_not_sir'] as NearGas,
    send_sir: json[r'send_sir'] == null ? null : json[r'send_sir'] as NearGas,
  );

  final NearGas? execution;
  final NearGas? send_not_sir;
  final NearGas? send_sir;

  Map<String, dynamic> toJson() => {
    if (execution != null) r'execution': execution,
    if (send_not_sir != null) r'send_not_sir': send_not_sir,
    if (send_sir != null) r'send_sir': send_sir,
  };
}

/// Generated from `FinalExecutionOutcomeView`.
class FinalExecutionOutcomeView {
  const FinalExecutionOutcomeView({
    this.receipts_outcome,
    this.status,
    this.transaction,
    this.transaction_outcome,
  });

  factory FinalExecutionOutcomeView.fromJson(Map<String, dynamic> json) =>
      FinalExecutionOutcomeView(
        receipts_outcome: json[r'receipts_outcome'] == null
            ? null
            : (json[r'receipts_outcome'] as List)
                  .map<ExecutionOutcomeWithIdView>(
                    (e) => ExecutionOutcomeWithIdView.fromJson(e),
                  )
                  .toList(),
        status: json[r'status'] == null
            ? null
            : FinalExecutionStatus.fromJson(json[r'status']),
        transaction: json[r'transaction'] == null
            ? null
            : SignedTransactionView.fromJson(json[r'transaction']),
        transaction_outcome: json[r'transaction_outcome'] == null
            ? null
            : ExecutionOutcomeWithIdView.fromJson(json[r'transaction_outcome']),
      );

  final List<ExecutionOutcomeWithIdView>? receipts_outcome;
  final FinalExecutionStatus? status;
  final SignedTransactionView? transaction;
  final ExecutionOutcomeWithIdView? transaction_outcome;

  Map<String, dynamic> toJson() => {
    if (receipts_outcome != null)
      r'receipts_outcome': receipts_outcome?.map((e) => e.toJson()).toList(),
    if (status != null) r'status': status?.toJson(),
    if (transaction != null) r'transaction': transaction?.toJson(),
    if (transaction_outcome != null)
      r'transaction_outcome': transaction_outcome?.toJson(),
  };
}

/// Generated from `FinalExecutionOutcomeWithReceiptView`.
class FinalExecutionOutcomeWithReceiptView {
  const FinalExecutionOutcomeWithReceiptView({
    this.receipts,
    this.receipts_outcome,
    this.status,
    this.transaction,
    this.transaction_outcome,
  });

  factory FinalExecutionOutcomeWithReceiptView.fromJson(
    Map<String, dynamic> json,
  ) => FinalExecutionOutcomeWithReceiptView(
    receipts: json[r'receipts'] == null
        ? null
        : (json[r'receipts'] as List)
              .map<ReceiptView>((e) => ReceiptView.fromJson(e))
              .toList(),
    receipts_outcome: json[r'receipts_outcome'] == null
        ? null
        : (json[r'receipts_outcome'] as List)
              .map<ExecutionOutcomeWithIdView>(
                (e) => ExecutionOutcomeWithIdView.fromJson(e),
              )
              .toList(),
    status: json[r'status'] == null
        ? null
        : FinalExecutionStatus.fromJson(json[r'status']),
    transaction: json[r'transaction'] == null
        ? null
        : SignedTransactionView.fromJson(json[r'transaction']),
    transaction_outcome: json[r'transaction_outcome'] == null
        ? null
        : ExecutionOutcomeWithIdView.fromJson(json[r'transaction_outcome']),
  );

  final List<ReceiptView>? receipts;
  final List<ExecutionOutcomeWithIdView>? receipts_outcome;
  final FinalExecutionStatus? status;
  final SignedTransactionView? transaction;
  final ExecutionOutcomeWithIdView? transaction_outcome;

  Map<String, dynamic> toJson() => {
    if (receipts != null)
      r'receipts': receipts?.map((e) => e.toJson()).toList(),
    if (receipts_outcome != null)
      r'receipts_outcome': receipts_outcome?.map((e) => e.toJson()).toList(),
    if (status != null) r'status': status?.toJson(),
    if (transaction != null) r'transaction': transaction?.toJson(),
    if (transaction_outcome != null)
      r'transaction_outcome': transaction_outcome?.toJson(),
  };
}

/// Union type generated from `FinalExecutionStatus`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class FinalExecutionStatus {
  const FinalExecutionStatus(this.json);
  factory FinalExecutionStatus.fromJson(dynamic json) =>
      FinalExecutionStatus(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `Finality`.
enum Finality {
  optimistic(r'optimistic'),
  near_final(r'near-final'),
  $final(r'final');

  const Finality(this.wireValue);
  final String wireValue;

  static Finality fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Alias for `FunctionArgs`.
typedef FunctionArgs = String;

/// Generated from `FunctionCallAction`.
class FunctionCallAction {
  const FunctionCallAction({
    this.args,
    this.deposit,
    this.gas,
    this.method_name,
  });

  factory FunctionCallAction.fromJson(Map<String, dynamic> json) =>
      FunctionCallAction(
        args: json[r'args'] == null ? null : json[r'args'] as String,
        deposit: json[r'deposit'] == null
            ? null
            : json[r'deposit'] as NearToken,
        gas: json[r'gas'] == null ? null : json[r'gas'] as NearGas,
        method_name: json[r'method_name'] == null
            ? null
            : json[r'method_name'] as String,
      );

  final String? args;
  final NearToken? deposit;
  final NearGas? gas;
  final String? method_name;

  Map<String, dynamic> toJson() => {
    if (args != null) r'args': args,
    if (deposit != null) r'deposit': deposit,
    if (gas != null) r'gas': gas,
    if (method_name != null) r'method_name': method_name,
  };
}

/// Union type generated from `FunctionCallError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class FunctionCallError {
  const FunctionCallError(this.json);
  factory FunctionCallError.fromJson(dynamic json) => FunctionCallError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `FunctionCallPermission`.
class FunctionCallPermission {
  const FunctionCallPermission({
    this.allowance,
    this.method_names,
    this.receiver_id,
  });

  factory FunctionCallPermission.fromJson(Map<String, dynamic> json) =>
      FunctionCallPermission(
        allowance: json[r'allowance'] == null ? null : json[r'allowance'],
        method_names: json[r'method_names'] == null
            ? null
            : (json[r'method_names'] as List)
                  .map<String>((e) => e as String)
                  .toList(),
        receiver_id: json[r'receiver_id'] == null
            ? null
            : json[r'receiver_id'] as String,
      );

  final dynamic? allowance;
  final List<String>? method_names;
  final String? receiver_id;

  Map<String, dynamic> toJson() => {
    if (allowance != null) r'allowance': allowance,
    if (method_names != null) r'method_names': method_names,
    if (receiver_id != null) r'receiver_id': receiver_id,
  };
}

/// Generated from `GCConfig`.
class GCConfig {
  const GCConfig({
    this.gc_blocks_limit,
    this.gc_fork_clean_step,
    this.gc_num_epochs_to_keep,
    this.gc_step_period,
  });

  factory GCConfig.fromJson(Map<String, dynamic> json) => GCConfig(
    gc_blocks_limit: json[r'gc_blocks_limit'] == null
        ? null
        : (json[r'gc_blocks_limit'] as num).toInt(),
    gc_fork_clean_step: json[r'gc_fork_clean_step'] == null
        ? null
        : (json[r'gc_fork_clean_step'] as num).toInt(),
    gc_num_epochs_to_keep: json[r'gc_num_epochs_to_keep'] == null
        ? null
        : (json[r'gc_num_epochs_to_keep'] as num).toInt(),
    gc_step_period: json[r'gc_step_period'] == null
        ? null
        : DurationAsStdSchemaProvider.fromJson(json[r'gc_step_period']),
  );

  final int? gc_blocks_limit;
  final int? gc_fork_clean_step;
  final int? gc_num_epochs_to_keep;
  final DurationAsStdSchemaProvider? gc_step_period;

  Map<String, dynamic> toJson() => {
    if (gc_blocks_limit != null) r'gc_blocks_limit': gc_blocks_limit,
    if (gc_fork_clean_step != null) r'gc_fork_clean_step': gc_fork_clean_step,
    if (gc_num_epochs_to_keep != null)
      r'gc_num_epochs_to_keep': gc_num_epochs_to_keep,
    if (gc_step_period != null) r'gc_step_period': gc_step_period?.toJson(),
  };
}

/// Generated from `GasKeyInfo`.
class GasKeyInfo {
  const GasKeyInfo({this.balance, this.num_nonces});

  factory GasKeyInfo.fromJson(Map<String, dynamic> json) => GasKeyInfo(
    balance: json[r'balance'] == null ? null : json[r'balance'] as NearToken,
    num_nonces: json[r'num_nonces'] == null
        ? null
        : (json[r'num_nonces'] as num).toInt(),
  );

  final NearToken? balance;
  final int? num_nonces;

  Map<String, dynamic> toJson() => {
    if (balance != null) r'balance': balance,
    if (num_nonces != null) r'num_nonces': num_nonces,
  };
}

/// Generated from `GasKeyNoncesView`.
class GasKeyNoncesView {
  const GasKeyNoncesView({this.nonces});

  factory GasKeyNoncesView.fromJson(Map<String, dynamic> json) =>
      GasKeyNoncesView(
        nonces: json[r'nonces'] == null
            ? null
            : (json[r'nonces'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
      );

  final List<int>? nonces;

  Map<String, dynamic> toJson() => {if (nonces != null) r'nonces': nonces};
}

/// Generated from `GenesisConfig`.
class GenesisConfig {
  const GenesisConfig({
    this.block_producer_kickout_threshold,
    this.chain_id,
    this.chunk_producer_assignment_changes_limit,
    this.chunk_producer_kickout_threshold,
    this.chunk_validator_only_kickout_threshold,
    this.dynamic_resharding,
    this.epoch_length,
    this.fishermen_threshold,
    this.gas_limit,
    this.gas_price_adjustment_rate,
    this.genesis_height,
    this.genesis_time,
    this.max_gas_price,
    this.max_inflation_rate,
    this.max_kickout_stake_perc,
    this.min_gas_price,
    this.minimum_stake_divisor,
    this.minimum_stake_ratio,
    this.minimum_validators_per_shard,
    this.num_block_producer_seats,
    this.num_blocks_per_year,
    this.num_chunk_producer_seats,
    this.num_chunk_validator_seats,
    this.online_max_threshold,
    this.online_min_threshold,
    this.protocol_reward_rate,
    this.protocol_treasury_account,
    this.protocol_upgrade_stake_threshold,
    this.protocol_version,
    this.shard_layout,
    this.shuffle_shard_assignment_for_chunk_producers,
    this.target_validator_mandates_per_shard,
    this.total_supply,
    this.transaction_validity_period,
    this.use_production_config,
    this.validators,
  });

  factory GenesisConfig.fromJson(Map<String, dynamic> json) => GenesisConfig(
    block_producer_kickout_threshold:
        json[r'block_producer_kickout_threshold'] == null
        ? null
        : (json[r'block_producer_kickout_threshold'] as num).toInt(),
    chain_id: json[r'chain_id'] == null ? null : json[r'chain_id'] as String,
    chunk_producer_assignment_changes_limit:
        json[r'chunk_producer_assignment_changes_limit'] == null
        ? null
        : (json[r'chunk_producer_assignment_changes_limit'] as num).toInt(),
    chunk_producer_kickout_threshold:
        json[r'chunk_producer_kickout_threshold'] == null
        ? null
        : (json[r'chunk_producer_kickout_threshold'] as num).toInt(),
    chunk_validator_only_kickout_threshold:
        json[r'chunk_validator_only_kickout_threshold'] == null
        ? null
        : (json[r'chunk_validator_only_kickout_threshold'] as num).toInt(),
    dynamic_resharding: json[r'dynamic_resharding'] == null
        ? null
        : json[r'dynamic_resharding'] as bool,
    epoch_length: json[r'epoch_length'] == null
        ? null
        : (json[r'epoch_length'] as num).toInt(),
    fishermen_threshold: json[r'fishermen_threshold'] == null
        ? null
        : json[r'fishermen_threshold'] as NearToken,
    gas_limit: json[r'gas_limit'] == null
        ? null
        : json[r'gas_limit'] as NearGas,
    gas_price_adjustment_rate: json[r'gas_price_adjustment_rate'] == null
        ? null
        : (json[r'gas_price_adjustment_rate'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    genesis_height: json[r'genesis_height'] == null
        ? null
        : (json[r'genesis_height'] as num).toInt(),
    genesis_time: json[r'genesis_time'] == null
        ? null
        : json[r'genesis_time'] as String,
    max_gas_price: json[r'max_gas_price'] == null
        ? null
        : json[r'max_gas_price'] as NearToken,
    max_inflation_rate: json[r'max_inflation_rate'] == null
        ? null
        : (json[r'max_inflation_rate'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    max_kickout_stake_perc: json[r'max_kickout_stake_perc'] == null
        ? null
        : (json[r'max_kickout_stake_perc'] as num).toInt(),
    min_gas_price: json[r'min_gas_price'] == null
        ? null
        : json[r'min_gas_price'] as NearToken,
    minimum_stake_divisor: json[r'minimum_stake_divisor'] == null
        ? null
        : (json[r'minimum_stake_divisor'] as num).toInt(),
    minimum_stake_ratio: json[r'minimum_stake_ratio'] == null
        ? null
        : (json[r'minimum_stake_ratio'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    minimum_validators_per_shard: json[r'minimum_validators_per_shard'] == null
        ? null
        : (json[r'minimum_validators_per_shard'] as num).toInt(),
    num_block_producer_seats: json[r'num_block_producer_seats'] == null
        ? null
        : (json[r'num_block_producer_seats'] as num).toInt(),
    num_blocks_per_year: json[r'num_blocks_per_year'] == null
        ? null
        : (json[r'num_blocks_per_year'] as num).toInt(),
    num_chunk_producer_seats: json[r'num_chunk_producer_seats'] == null
        ? null
        : (json[r'num_chunk_producer_seats'] as num).toInt(),
    num_chunk_validator_seats: json[r'num_chunk_validator_seats'] == null
        ? null
        : (json[r'num_chunk_validator_seats'] as num).toInt(),
    online_max_threshold: json[r'online_max_threshold'] == null
        ? null
        : (json[r'online_max_threshold'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    online_min_threshold: json[r'online_min_threshold'] == null
        ? null
        : (json[r'online_min_threshold'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    protocol_reward_rate: json[r'protocol_reward_rate'] == null
        ? null
        : (json[r'protocol_reward_rate'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    protocol_treasury_account: json[r'protocol_treasury_account'] == null
        ? null
        : json[r'protocol_treasury_account'] as AccountId,
    protocol_upgrade_stake_threshold:
        json[r'protocol_upgrade_stake_threshold'] == null
        ? null
        : (json[r'protocol_upgrade_stake_threshold'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    protocol_version: json[r'protocol_version'] == null
        ? null
        : (json[r'protocol_version'] as num).toInt(),
    shard_layout: json[r'shard_layout'] == null
        ? null
        : ShardLayout.fromJson(json[r'shard_layout']),
    shuffle_shard_assignment_for_chunk_producers:
        json[r'shuffle_shard_assignment_for_chunk_producers'] == null
        ? null
        : json[r'shuffle_shard_assignment_for_chunk_producers'] as bool,
    target_validator_mandates_per_shard:
        json[r'target_validator_mandates_per_shard'] == null
        ? null
        : (json[r'target_validator_mandates_per_shard'] as num).toInt(),
    total_supply: json[r'total_supply'] == null
        ? null
        : json[r'total_supply'] as NearToken,
    transaction_validity_period: json[r'transaction_validity_period'] == null
        ? null
        : (json[r'transaction_validity_period'] as num).toInt(),
    use_production_config: json[r'use_production_config'] == null
        ? null
        : json[r'use_production_config'] as bool,
    validators: json[r'validators'] == null
        ? null
        : (json[r'validators'] as List)
              .map<AccountInfo>((e) => AccountInfo.fromJson(e))
              .toList(),
  );

  final int? block_producer_kickout_threshold;
  final String? chain_id;
  final int? chunk_producer_assignment_changes_limit;
  final int? chunk_producer_kickout_threshold;
  final int? chunk_validator_only_kickout_threshold;
  final bool? dynamic_resharding;
  final int? epoch_length;
  final NearToken? fishermen_threshold;
  final NearGas? gas_limit;
  final List<int>? gas_price_adjustment_rate;
  final int? genesis_height;
  final String? genesis_time;
  final NearToken? max_gas_price;
  final List<int>? max_inflation_rate;
  final int? max_kickout_stake_perc;
  final NearToken? min_gas_price;
  final int? minimum_stake_divisor;
  final List<int>? minimum_stake_ratio;
  final int? minimum_validators_per_shard;
  final int? num_block_producer_seats;
  final int? num_blocks_per_year;
  final int? num_chunk_producer_seats;
  final int? num_chunk_validator_seats;
  final List<int>? online_max_threshold;
  final List<int>? online_min_threshold;
  final List<int>? protocol_reward_rate;
  final AccountId? protocol_treasury_account;
  final List<int>? protocol_upgrade_stake_threshold;
  final int? protocol_version;
  final ShardLayout? shard_layout;
  final bool? shuffle_shard_assignment_for_chunk_producers;
  final int? target_validator_mandates_per_shard;
  final NearToken? total_supply;
  final int? transaction_validity_period;
  final bool? use_production_config;
  final List<AccountInfo>? validators;

  Map<String, dynamic> toJson() => {
    if (block_producer_kickout_threshold != null)
      r'block_producer_kickout_threshold': block_producer_kickout_threshold,
    if (chain_id != null) r'chain_id': chain_id,
    if (chunk_producer_assignment_changes_limit != null)
      r'chunk_producer_assignment_changes_limit':
          chunk_producer_assignment_changes_limit,
    if (chunk_producer_kickout_threshold != null)
      r'chunk_producer_kickout_threshold': chunk_producer_kickout_threshold,
    if (chunk_validator_only_kickout_threshold != null)
      r'chunk_validator_only_kickout_threshold':
          chunk_validator_only_kickout_threshold,
    if (dynamic_resharding != null) r'dynamic_resharding': dynamic_resharding,
    if (epoch_length != null) r'epoch_length': epoch_length,
    if (fishermen_threshold != null)
      r'fishermen_threshold': fishermen_threshold,
    if (gas_limit != null) r'gas_limit': gas_limit,
    if (gas_price_adjustment_rate != null)
      r'gas_price_adjustment_rate': gas_price_adjustment_rate,
    if (genesis_height != null) r'genesis_height': genesis_height,
    if (genesis_time != null) r'genesis_time': genesis_time,
    if (max_gas_price != null) r'max_gas_price': max_gas_price,
    if (max_inflation_rate != null) r'max_inflation_rate': max_inflation_rate,
    if (max_kickout_stake_perc != null)
      r'max_kickout_stake_perc': max_kickout_stake_perc,
    if (min_gas_price != null) r'min_gas_price': min_gas_price,
    if (minimum_stake_divisor != null)
      r'minimum_stake_divisor': minimum_stake_divisor,
    if (minimum_stake_ratio != null)
      r'minimum_stake_ratio': minimum_stake_ratio,
    if (minimum_validators_per_shard != null)
      r'minimum_validators_per_shard': minimum_validators_per_shard,
    if (num_block_producer_seats != null)
      r'num_block_producer_seats': num_block_producer_seats,
    if (num_blocks_per_year != null)
      r'num_blocks_per_year': num_blocks_per_year,
    if (num_chunk_producer_seats != null)
      r'num_chunk_producer_seats': num_chunk_producer_seats,
    if (num_chunk_validator_seats != null)
      r'num_chunk_validator_seats': num_chunk_validator_seats,
    if (online_max_threshold != null)
      r'online_max_threshold': online_max_threshold,
    if (online_min_threshold != null)
      r'online_min_threshold': online_min_threshold,
    if (protocol_reward_rate != null)
      r'protocol_reward_rate': protocol_reward_rate,
    if (protocol_treasury_account != null)
      r'protocol_treasury_account': protocol_treasury_account,
    if (protocol_upgrade_stake_threshold != null)
      r'protocol_upgrade_stake_threshold': protocol_upgrade_stake_threshold,
    if (protocol_version != null) r'protocol_version': protocol_version,
    if (shard_layout != null) r'shard_layout': shard_layout?.toJson(),
    if (shuffle_shard_assignment_for_chunk_producers != null)
      r'shuffle_shard_assignment_for_chunk_producers':
          shuffle_shard_assignment_for_chunk_producers,
    if (target_validator_mandates_per_shard != null)
      r'target_validator_mandates_per_shard':
          target_validator_mandates_per_shard,
    if (total_supply != null) r'total_supply': total_supply,
    if (transaction_validity_period != null)
      r'transaction_validity_period': transaction_validity_period,
    if (use_production_config != null)
      r'use_production_config': use_production_config,
    if (validators != null)
      r'validators': validators?.map((e) => e.toJson()).toList(),
  };
}

/// Alias for `GenesisConfigError`.
typedef GenesisConfigError = dynamic;

/// Alias for `GenesisConfigRequest`.
typedef GenesisConfigRequest = dynamic;

/// Union type generated from `GlobalContractDeployMode`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class GlobalContractDeployMode {
  const GlobalContractDeployMode(this.json);
  factory GlobalContractDeployMode.fromJson(dynamic json) =>
      GlobalContractDeployMode(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `GlobalContractIdentifier`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class GlobalContractIdentifier {
  const GlobalContractIdentifier(this.json);
  factory GlobalContractIdentifier.fromJson(dynamic json) =>
      GlobalContractIdentifier(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `GlobalContractIdentifierView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class GlobalContractIdentifierView {
  const GlobalContractIdentifierView(this.json);
  factory GlobalContractIdentifierView.fromJson(dynamic json) =>
      GlobalContractIdentifierView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `HostError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class HostError {
  const HostError(this.json);
  factory HostError.fromJson(dynamic json) => HostError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `InternalError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class InternalError {
  const InternalError(this.json);
  factory InternalError.fromJson(dynamic json) => InternalError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `InvalidAccessKeyError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class InvalidAccessKeyError {
  const InvalidAccessKeyError(this.json);
  factory InvalidAccessKeyError.fromJson(dynamic json) =>
      InvalidAccessKeyError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `InvalidTxError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class InvalidTxError {
  const InvalidTxError(this.json);
  factory InvalidTxError.fromJson(dynamic json) => InvalidTxError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_call_function`.
class JsonRpcRequest_for_EXPERIMENTAL_call_function {
  const JsonRpcRequest_for_EXPERIMENTAL_call_function({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_call_function.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_call_function(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcCallFunctionRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcCallFunctionRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_changes`.
class JsonRpcRequest_for_EXPERIMENTAL_changes {
  const JsonRpcRequest_for_EXPERIMENTAL_changes({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_changes.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_changes(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcStateChangesInBlockByTypeRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcStateChangesInBlockByTypeRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_changes_in_block`.
class JsonRpcRequest_for_EXPERIMENTAL_changes_in_block {
  const JsonRpcRequest_for_EXPERIMENTAL_changes_in_block({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_changes_in_block.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_changes_in_block(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcStateChangesInBlockRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcStateChangesInBlockRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_congestion_level`.
class JsonRpcRequest_for_EXPERIMENTAL_congestion_level {
  const JsonRpcRequest_for_EXPERIMENTAL_congestion_level({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_congestion_level.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_congestion_level(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcCongestionLevelRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcCongestionLevelRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_genesis_config`.
class JsonRpcRequest_for_EXPERIMENTAL_genesis_config {
  const JsonRpcRequest_for_EXPERIMENTAL_genesis_config({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_genesis_config.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_genesis_config(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : json[r'params'] as GenesisConfigRequest,
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final GenesisConfigRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params,
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_light_client_block_proof`.
class JsonRpcRequest_for_EXPERIMENTAL_light_client_block_proof {
  const JsonRpcRequest_for_EXPERIMENTAL_light_client_block_proof({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_light_client_block_proof.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_light_client_block_proof(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcLightClientBlockProofRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcLightClientBlockProofRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_light_client_proof`.
class JsonRpcRequest_for_EXPERIMENTAL_light_client_proof {
  const JsonRpcRequest_for_EXPERIMENTAL_light_client_proof({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_light_client_proof.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_light_client_proof(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcLightClientExecutionProofRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcLightClientExecutionProofRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_maintenance_windows`.
class JsonRpcRequest_for_EXPERIMENTAL_maintenance_windows {
  const JsonRpcRequest_for_EXPERIMENTAL_maintenance_windows({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_maintenance_windows.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_maintenance_windows(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcMaintenanceWindowsRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcMaintenanceWindowsRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_protocol_config`.
class JsonRpcRequest_for_EXPERIMENTAL_protocol_config {
  const JsonRpcRequest_for_EXPERIMENTAL_protocol_config({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_protocol_config.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_protocol_config(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcProtocolConfigRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcProtocolConfigRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_receipt`.
class JsonRpcRequest_for_EXPERIMENTAL_receipt {
  const JsonRpcRequest_for_EXPERIMENTAL_receipt({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_receipt.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_receipt(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcReceiptRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcReceiptRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_receipt_to_tx`.
class JsonRpcRequest_for_EXPERIMENTAL_receipt_to_tx {
  const JsonRpcRequest_for_EXPERIMENTAL_receipt_to_tx({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_receipt_to_tx.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_receipt_to_tx(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcReceiptToTxRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcReceiptToTxRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_split_storage_info`.
class JsonRpcRequest_for_EXPERIMENTAL_split_storage_info {
  const JsonRpcRequest_for_EXPERIMENTAL_split_storage_info({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_split_storage_info.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_split_storage_info(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcSplitStorageInfoRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcSplitStorageInfoRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_tx_status`.
class JsonRpcRequest_for_EXPERIMENTAL_tx_status {
  const JsonRpcRequest_for_EXPERIMENTAL_tx_status({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_tx_status.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_tx_status(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcTransactionStatusRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcTransactionStatusRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_validators_ordered`.
class JsonRpcRequest_for_EXPERIMENTAL_validators_ordered {
  const JsonRpcRequest_for_EXPERIMENTAL_validators_ordered({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_validators_ordered.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_validators_ordered(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcValidatorsOrderedRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcValidatorsOrderedRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_view_access_key`.
class JsonRpcRequest_for_EXPERIMENTAL_view_access_key {
  const JsonRpcRequest_for_EXPERIMENTAL_view_access_key({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_view_access_key.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_view_access_key(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcViewAccessKeyRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcViewAccessKeyRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_view_access_key_list`.
class JsonRpcRequest_for_EXPERIMENTAL_view_access_key_list {
  const JsonRpcRequest_for_EXPERIMENTAL_view_access_key_list({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_view_access_key_list.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_view_access_key_list(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcViewAccessKeyListRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcViewAccessKeyListRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_view_account`.
class JsonRpcRequest_for_EXPERIMENTAL_view_account {
  const JsonRpcRequest_for_EXPERIMENTAL_view_account({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_view_account.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_view_account(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcViewAccountRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcViewAccountRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_view_code`.
class JsonRpcRequest_for_EXPERIMENTAL_view_code {
  const JsonRpcRequest_for_EXPERIMENTAL_view_code({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_view_code.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_view_code(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcViewCodeRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcViewCodeRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_EXPERIMENTAL_view_state`.
class JsonRpcRequest_for_EXPERIMENTAL_view_state {
  const JsonRpcRequest_for_EXPERIMENTAL_view_state({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_EXPERIMENTAL_view_state.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_EXPERIMENTAL_view_state(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcViewStateRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcViewStateRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_block`.
class JsonRpcRequest_for_block {
  const JsonRpcRequest_for_block({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_block.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_block(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcBlockRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcBlockRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_block_effects`.
class JsonRpcRequest_for_block_effects {
  const JsonRpcRequest_for_block_effects({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_block_effects.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_block_effects(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcStateChangesInBlockRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcStateChangesInBlockRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_broadcast_tx_async`.
class JsonRpcRequest_for_broadcast_tx_async {
  const JsonRpcRequest_for_broadcast_tx_async({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_broadcast_tx_async.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_broadcast_tx_async(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcSendTransactionRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcSendTransactionRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_broadcast_tx_commit`.
class JsonRpcRequest_for_broadcast_tx_commit {
  const JsonRpcRequest_for_broadcast_tx_commit({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_broadcast_tx_commit.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_broadcast_tx_commit(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcSendTransactionRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcSendTransactionRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_changes`.
class JsonRpcRequest_for_changes {
  const JsonRpcRequest_for_changes({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_changes.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_changes(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcStateChangesInBlockByTypeRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcStateChangesInBlockByTypeRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_chunk`.
class JsonRpcRequest_for_chunk {
  const JsonRpcRequest_for_chunk({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_chunk.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_chunk(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcChunkRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcChunkRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_client_config`.
class JsonRpcRequest_for_client_config {
  const JsonRpcRequest_for_client_config({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_client_config.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_client_config(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : json[r'params'] as RpcClientConfigRequest,
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcClientConfigRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params,
  };
}

/// Generated from `JsonRpcRequest_for_gas_price`.
class JsonRpcRequest_for_gas_price {
  const JsonRpcRequest_for_gas_price({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_gas_price.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_gas_price(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcGasPriceRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcGasPriceRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_genesis_config`.
class JsonRpcRequest_for_genesis_config {
  const JsonRpcRequest_for_genesis_config({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_genesis_config.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_genesis_config(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : json[r'params'] as GenesisConfigRequest,
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final GenesisConfigRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params,
  };
}

/// Generated from `JsonRpcRequest_for_health`.
class JsonRpcRequest_for_health {
  const JsonRpcRequest_for_health({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_health.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_health(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : json[r'params'] as RpcHealthRequest,
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcHealthRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params,
  };
}

/// Generated from `JsonRpcRequest_for_light_client_proof`.
class JsonRpcRequest_for_light_client_proof {
  const JsonRpcRequest_for_light_client_proof({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_light_client_proof.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_light_client_proof(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcLightClientExecutionProofRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcLightClientExecutionProofRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_maintenance_windows`.
class JsonRpcRequest_for_maintenance_windows {
  const JsonRpcRequest_for_maintenance_windows({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_maintenance_windows.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_maintenance_windows(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcMaintenanceWindowsRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcMaintenanceWindowsRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_network_info`.
class JsonRpcRequest_for_network_info {
  const JsonRpcRequest_for_network_info({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_network_info.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_network_info(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : json[r'params'] as RpcNetworkInfoRequest,
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcNetworkInfoRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params,
  };
}

/// Generated from `JsonRpcRequest_for_next_light_client_block`.
class JsonRpcRequest_for_next_light_client_block {
  const JsonRpcRequest_for_next_light_client_block({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_next_light_client_block.fromJson(
    Map<String, dynamic> json,
  ) => JsonRpcRequest_for_next_light_client_block(
    id: json[r'id'] == null ? null : json[r'id'] as String,
    jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
    method: json[r'method'] == null ? null : json[r'method'] as String,
    params: json[r'params'] == null
        ? null
        : RpcLightClientNextBlockRequest.fromJson(json[r'params']),
  );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcLightClientNextBlockRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_query`.
class JsonRpcRequest_for_query {
  const JsonRpcRequest_for_query({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_query.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_query(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcQueryRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcQueryRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_send_tx`.
class JsonRpcRequest_for_send_tx {
  const JsonRpcRequest_for_send_tx({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_send_tx.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_send_tx(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcSendTransactionRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcSendTransactionRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_status`.
class JsonRpcRequest_for_status {
  const JsonRpcRequest_for_status({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_status.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_status(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : json[r'params'] as RpcStatusRequest,
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcStatusRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params,
  };
}

/// Generated from `JsonRpcRequest_for_tx`.
class JsonRpcRequest_for_tx {
  const JsonRpcRequest_for_tx({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_tx.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_tx(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcTransactionStatusRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcTransactionStatusRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Generated from `JsonRpcRequest_for_validators`.
class JsonRpcRequest_for_validators {
  const JsonRpcRequest_for_validators({
    this.id,
    this.jsonrpc,
    this.method,
    this.params,
  });

  factory JsonRpcRequest_for_validators.fromJson(Map<String, dynamic> json) =>
      JsonRpcRequest_for_validators(
        id: json[r'id'] == null ? null : json[r'id'] as String,
        jsonrpc: json[r'jsonrpc'] == null ? null : json[r'jsonrpc'] as String,
        method: json[r'method'] == null ? null : json[r'method'] as String,
        params: json[r'params'] == null
            ? null
            : RpcValidatorRequest.fromJson(json[r'params']),
      );

  final String? id;
  final String? jsonrpc;
  final String? method;
  final RpcValidatorRequest? params;

  Map<String, dynamic> toJson() => {
    if (id != null) r'id': id,
    if (jsonrpc != null) r'jsonrpc': jsonrpc,
    if (method != null) r'method': method,
    if (params != null) r'params': params?.toJson(),
  };
}

/// Union type generated from `JsonRpcResponse_for_Array_of_Range_of_uint64_and_RpcMaintenanceWindowsError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_Array_of_Range_of_uint64_and_RpcMaintenanceWindowsError {
  const JsonRpcResponse_for_Array_of_Range_of_uint64_and_RpcMaintenanceWindowsError(
    this.json,
  );
  factory JsonRpcResponse_for_Array_of_Range_of_uint64_and_RpcMaintenanceWindowsError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_Array_of_Range_of_uint64_and_RpcMaintenanceWindowsError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_Array_of_ValidatorStakeView_and_RpcValidatorError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_Array_of_ValidatorStakeView_and_RpcValidatorError {
  const JsonRpcResponse_for_Array_of_ValidatorStakeView_and_RpcValidatorError(
    this.json,
  );
  factory JsonRpcResponse_for_Array_of_ValidatorStakeView_and_RpcValidatorError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_Array_of_ValidatorStakeView_and_RpcValidatorError(
    json,
  );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_CryptoHash_and_RpcTransactionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_CryptoHash_and_RpcTransactionError {
  const JsonRpcResponse_for_CryptoHash_and_RpcTransactionError(this.json);
  factory JsonRpcResponse_for_CryptoHash_and_RpcTransactionError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_CryptoHash_and_RpcTransactionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_GenesisConfig_and_GenesisConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_GenesisConfig_and_GenesisConfigError {
  const JsonRpcResponse_for_GenesisConfig_and_GenesisConfigError(this.json);
  factory JsonRpcResponse_for_GenesisConfig_and_GenesisConfigError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_GenesisConfig_and_GenesisConfigError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_Nullable_RpcHealthResponse_and_RpcStatusError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_Nullable_RpcHealthResponse_and_RpcStatusError {
  const JsonRpcResponse_for_Nullable_RpcHealthResponse_and_RpcStatusError(
    this.json,
  );
  factory JsonRpcResponse_for_Nullable_RpcHealthResponse_and_RpcStatusError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_Nullable_RpcHealthResponse_and_RpcStatusError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcBlockResponse_and_RpcBlockError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcBlockResponse_and_RpcBlockError {
  const JsonRpcResponse_for_RpcBlockResponse_and_RpcBlockError(this.json);
  factory JsonRpcResponse_for_RpcBlockResponse_and_RpcBlockError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcBlockResponse_and_RpcBlockError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcCallFunctionResponse_and_RpcCallFunctionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcCallFunctionResponse_and_RpcCallFunctionError {
  const JsonRpcResponse_for_RpcCallFunctionResponse_and_RpcCallFunctionError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcCallFunctionResponse_and_RpcCallFunctionError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcCallFunctionResponse_and_RpcCallFunctionError(
    json,
  );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcChunkResponse_and_RpcChunkError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcChunkResponse_and_RpcChunkError {
  const JsonRpcResponse_for_RpcChunkResponse_and_RpcChunkError(this.json);
  factory JsonRpcResponse_for_RpcChunkResponse_and_RpcChunkError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcChunkResponse_and_RpcChunkError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcClientConfigResponse_and_RpcClientConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcClientConfigResponse_and_RpcClientConfigError {
  const JsonRpcResponse_for_RpcClientConfigResponse_and_RpcClientConfigError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcClientConfigResponse_and_RpcClientConfigError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcClientConfigResponse_and_RpcClientConfigError(
    json,
  );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcCongestionLevelResponse_and_RpcChunkError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcCongestionLevelResponse_and_RpcChunkError {
  const JsonRpcResponse_for_RpcCongestionLevelResponse_and_RpcChunkError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcCongestionLevelResponse_and_RpcChunkError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcCongestionLevelResponse_and_RpcChunkError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcGasPriceResponse_and_RpcGasPriceError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcGasPriceResponse_and_RpcGasPriceError {
  const JsonRpcResponse_for_RpcGasPriceResponse_and_RpcGasPriceError(this.json);
  factory JsonRpcResponse_for_RpcGasPriceResponse_and_RpcGasPriceError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcGasPriceResponse_and_RpcGasPriceError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcLightClientBlockProofResponse_and_RpcLightClientProofError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcLightClientBlockProofResponse_and_RpcLightClientProofError {
  const JsonRpcResponse_for_RpcLightClientBlockProofResponse_and_RpcLightClientProofError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcLightClientBlockProofResponse_and_RpcLightClientProofError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcLightClientBlockProofResponse_and_RpcLightClientProofError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcLightClientExecutionProofResponse_and_RpcLightClientProofError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcLightClientExecutionProofResponse_and_RpcLightClientProofError {
  const JsonRpcResponse_for_RpcLightClientExecutionProofResponse_and_RpcLightClientProofError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcLightClientExecutionProofResponse_and_RpcLightClientProofError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcLightClientExecutionProofResponse_and_RpcLightClientProofError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcLightClientNextBlockResponse_and_RpcLightClientNextBlockError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcLightClientNextBlockResponse_and_RpcLightClientNextBlockError {
  const JsonRpcResponse_for_RpcLightClientNextBlockResponse_and_RpcLightClientNextBlockError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcLightClientNextBlockResponse_and_RpcLightClientNextBlockError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcLightClientNextBlockResponse_and_RpcLightClientNextBlockError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcNetworkInfoResponse_and_RpcNetworkInfoError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcNetworkInfoResponse_and_RpcNetworkInfoError {
  const JsonRpcResponse_for_RpcNetworkInfoResponse_and_RpcNetworkInfoError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcNetworkInfoResponse_and_RpcNetworkInfoError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcNetworkInfoResponse_and_RpcNetworkInfoError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcProtocolConfigResponse_and_RpcProtocolConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcProtocolConfigResponse_and_RpcProtocolConfigError {
  const JsonRpcResponse_for_RpcProtocolConfigResponse_and_RpcProtocolConfigError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcProtocolConfigResponse_and_RpcProtocolConfigError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcProtocolConfigResponse_and_RpcProtocolConfigError(
    json,
  );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcQueryResponse_and_RpcQueryError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcQueryResponse_and_RpcQueryError {
  const JsonRpcResponse_for_RpcQueryResponse_and_RpcQueryError(this.json);
  factory JsonRpcResponse_for_RpcQueryResponse_and_RpcQueryError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcQueryResponse_and_RpcQueryError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcReceiptResponse_and_RpcReceiptError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcReceiptResponse_and_RpcReceiptError {
  const JsonRpcResponse_for_RpcReceiptResponse_and_RpcReceiptError(this.json);
  factory JsonRpcResponse_for_RpcReceiptResponse_and_RpcReceiptError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcReceiptResponse_and_RpcReceiptError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcReceiptToTxResponse_and_RpcReceiptToTxError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcReceiptToTxResponse_and_RpcReceiptToTxError {
  const JsonRpcResponse_for_RpcReceiptToTxResponse_and_RpcReceiptToTxError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcReceiptToTxResponse_and_RpcReceiptToTxError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcReceiptToTxResponse_and_RpcReceiptToTxError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcSplitStorageInfoResponse_and_RpcSplitStorageInfoError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcSplitStorageInfoResponse_and_RpcSplitStorageInfoError {
  const JsonRpcResponse_for_RpcSplitStorageInfoResponse_and_RpcSplitStorageInfoError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcSplitStorageInfoResponse_and_RpcSplitStorageInfoError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcSplitStorageInfoResponse_and_RpcSplitStorageInfoError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcStateChangesInBlockByTypeResponse_and_RpcStateChangesError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcStateChangesInBlockByTypeResponse_and_RpcStateChangesError {
  const JsonRpcResponse_for_RpcStateChangesInBlockByTypeResponse_and_RpcStateChangesError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcStateChangesInBlockByTypeResponse_and_RpcStateChangesError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcStateChangesInBlockByTypeResponse_and_RpcStateChangesError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcStateChangesInBlockResponse_and_RpcStateChangesError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcStateChangesInBlockResponse_and_RpcStateChangesError {
  const JsonRpcResponse_for_RpcStateChangesInBlockResponse_and_RpcStateChangesError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcStateChangesInBlockResponse_and_RpcStateChangesError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcStateChangesInBlockResponse_and_RpcStateChangesError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcStatusResponse_and_RpcStatusError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcStatusResponse_and_RpcStatusError {
  const JsonRpcResponse_for_RpcStatusResponse_and_RpcStatusError(this.json);
  factory JsonRpcResponse_for_RpcStatusResponse_and_RpcStatusError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcStatusResponse_and_RpcStatusError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcTransactionResponse_and_RpcTransactionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcTransactionResponse_and_RpcTransactionError {
  const JsonRpcResponse_for_RpcTransactionResponse_and_RpcTransactionError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcTransactionResponse_and_RpcTransactionError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcTransactionResponse_and_RpcTransactionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcValidatorResponse_and_RpcValidatorError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcValidatorResponse_and_RpcValidatorError {
  const JsonRpcResponse_for_RpcValidatorResponse_and_RpcValidatorError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcValidatorResponse_and_RpcValidatorError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcValidatorResponse_and_RpcValidatorError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcViewAccessKeyListResponse_and_RpcViewAccessKeyListError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcViewAccessKeyListResponse_and_RpcViewAccessKeyListError {
  const JsonRpcResponse_for_RpcViewAccessKeyListResponse_and_RpcViewAccessKeyListError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcViewAccessKeyListResponse_and_RpcViewAccessKeyListError.fromJson(
    dynamic json,
  ) =>
      JsonRpcResponse_for_RpcViewAccessKeyListResponse_and_RpcViewAccessKeyListError(
        json,
      );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcViewAccessKeyResponse_and_RpcViewAccessKeyError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcViewAccessKeyResponse_and_RpcViewAccessKeyError {
  const JsonRpcResponse_for_RpcViewAccessKeyResponse_and_RpcViewAccessKeyError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcViewAccessKeyResponse_and_RpcViewAccessKeyError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcViewAccessKeyResponse_and_RpcViewAccessKeyError(
    json,
  );
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcViewAccountResponse_and_RpcViewAccountError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcViewAccountResponse_and_RpcViewAccountError {
  const JsonRpcResponse_for_RpcViewAccountResponse_and_RpcViewAccountError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcViewAccountResponse_and_RpcViewAccountError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcViewAccountResponse_and_RpcViewAccountError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcViewCodeResponse_and_RpcViewCodeError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcViewCodeResponse_and_RpcViewCodeError {
  const JsonRpcResponse_for_RpcViewCodeResponse_and_RpcViewCodeError(this.json);
  factory JsonRpcResponse_for_RpcViewCodeResponse_and_RpcViewCodeError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcViewCodeResponse_and_RpcViewCodeError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `JsonRpcResponse_for_RpcViewStateResponse_and_RpcViewStateError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class JsonRpcResponse_for_RpcViewStateResponse_and_RpcViewStateError {
  const JsonRpcResponse_for_RpcViewStateResponse_and_RpcViewStateError(
    this.json,
  );
  factory JsonRpcResponse_for_RpcViewStateResponse_and_RpcViewStateError.fromJson(
    dynamic json,
  ) => JsonRpcResponse_for_RpcViewStateResponse_and_RpcViewStateError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `KnownProducerView`.
class KnownProducerView {
  const KnownProducerView({this.account_id, this.next_hops, this.peer_id});

  factory KnownProducerView.fromJson(Map<String, dynamic> json) =>
      KnownProducerView(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        next_hops: json[r'next_hops'] == null
            ? null
            : (json[r'next_hops'] as List)
                  .map<PublicKey>((e) => e as PublicKey)
                  .toList(),
        peer_id: json[r'peer_id'] == null
            ? null
            : json[r'peer_id'] as PublicKey,
      );

  final AccountId? account_id;
  final List<PublicKey>? next_hops;
  final PublicKey? peer_id;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (next_hops != null) r'next_hops': next_hops,
    if (peer_id != null) r'peer_id': peer_id,
  };
}

/// Generated from `LightClientBlockLiteView`.
class LightClientBlockLiteView {
  const LightClientBlockLiteView({
    this.inner_lite,
    this.inner_rest_hash,
    this.prev_block_hash,
  });

  factory LightClientBlockLiteView.fromJson(Map<String, dynamic> json) =>
      LightClientBlockLiteView(
        inner_lite: json[r'inner_lite'] == null
            ? null
            : BlockHeaderInnerLiteView.fromJson(json[r'inner_lite']),
        inner_rest_hash: json[r'inner_rest_hash'] == null
            ? null
            : json[r'inner_rest_hash'] as CryptoHash,
        prev_block_hash: json[r'prev_block_hash'] == null
            ? null
            : json[r'prev_block_hash'] as CryptoHash,
      );

  final BlockHeaderInnerLiteView? inner_lite;
  final CryptoHash? inner_rest_hash;
  final CryptoHash? prev_block_hash;

  Map<String, dynamic> toJson() => {
    if (inner_lite != null) r'inner_lite': inner_lite?.toJson(),
    if (inner_rest_hash != null) r'inner_rest_hash': inner_rest_hash,
    if (prev_block_hash != null) r'prev_block_hash': prev_block_hash,
  };
}

/// Generated from `LimitConfig`.
class LimitConfig {
  const LimitConfig({
    this.account_id_validity_rules_version,
    this.initial_memory_pages,
    this.max_actions_per_receipt,
    this.max_arguments_length,
    this.max_blocks_per_contract,
    this.max_blocks_per_function,
    this.max_contract_size,
    this.max_deploy_actions_per_receipt,
    this.max_elements_per_contract_table,
    this.max_function_body_size,
    this.max_functions_number_per_contract,
    this.max_gas_burnt,
    this.max_instrumented_code_size,
    this.max_length_method_name,
    this.max_length_returned_data,
    this.max_length_storage_key,
    this.max_length_storage_value,
    this.max_locals_per_contract,
    this.max_memory_pages,
    this.max_number_bytes_method_names,
    this.max_number_input_data_dependencies,
    this.max_number_logs,
    this.max_number_registers,
    this.max_operand_stack_bytes_per_function,
    this.max_params_per_contract,
    this.max_params_per_function,
    this.max_promises_per_function_call_action,
    this.max_receipt_size,
    this.max_register_size,
    this.max_stack_height,
    this.max_tables_per_contract,
    this.max_total_log_length,
    this.max_total_prepaid_gas,
    this.max_transaction_size,
    this.max_types_per_contract,
    this.max_yield_payload_size,
    this.per_receipt_storage_proof_size_limit,
    this.registers_memory_limit,
    this.yield_timeout_length_in_blocks,
  });

  factory LimitConfig.fromJson(Map<String, dynamic> json) => LimitConfig(
    account_id_validity_rules_version:
        json[r'account_id_validity_rules_version'] == null
        ? null
        : json[r'account_id_validity_rules_version']
              as AccountIdValidityRulesVersion,
    initial_memory_pages: json[r'initial_memory_pages'] == null
        ? null
        : (json[r'initial_memory_pages'] as num).toInt(),
    max_actions_per_receipt: json[r'max_actions_per_receipt'] == null
        ? null
        : (json[r'max_actions_per_receipt'] as num).toInt(),
    max_arguments_length: json[r'max_arguments_length'] == null
        ? null
        : (json[r'max_arguments_length'] as num).toInt(),
    max_blocks_per_contract: json[r'max_blocks_per_contract'] == null
        ? null
        : (json[r'max_blocks_per_contract'] as num).toInt(),
    max_blocks_per_function: json[r'max_blocks_per_function'] == null
        ? null
        : (json[r'max_blocks_per_function'] as num).toInt(),
    max_contract_size: json[r'max_contract_size'] == null
        ? null
        : (json[r'max_contract_size'] as num).toInt(),
    max_deploy_actions_per_receipt:
        json[r'max_deploy_actions_per_receipt'] == null
        ? null
        : (json[r'max_deploy_actions_per_receipt'] as num).toInt(),
    max_elements_per_contract_table:
        json[r'max_elements_per_contract_table'] == null
        ? null
        : (json[r'max_elements_per_contract_table'] as num).toInt(),
    max_function_body_size: json[r'max_function_body_size'] == null
        ? null
        : (json[r'max_function_body_size'] as num).toInt(),
    max_functions_number_per_contract:
        json[r'max_functions_number_per_contract'] == null
        ? null
        : (json[r'max_functions_number_per_contract'] as num).toInt(),
    max_gas_burnt: json[r'max_gas_burnt'] == null
        ? null
        : json[r'max_gas_burnt'] as NearGas,
    max_instrumented_code_size: json[r'max_instrumented_code_size'] == null
        ? null
        : (json[r'max_instrumented_code_size'] as num).toInt(),
    max_length_method_name: json[r'max_length_method_name'] == null
        ? null
        : (json[r'max_length_method_name'] as num).toInt(),
    max_length_returned_data: json[r'max_length_returned_data'] == null
        ? null
        : (json[r'max_length_returned_data'] as num).toInt(),
    max_length_storage_key: json[r'max_length_storage_key'] == null
        ? null
        : (json[r'max_length_storage_key'] as num).toInt(),
    max_length_storage_value: json[r'max_length_storage_value'] == null
        ? null
        : (json[r'max_length_storage_value'] as num).toInt(),
    max_locals_per_contract: json[r'max_locals_per_contract'] == null
        ? null
        : (json[r'max_locals_per_contract'] as num).toInt(),
    max_memory_pages: json[r'max_memory_pages'] == null
        ? null
        : (json[r'max_memory_pages'] as num).toInt(),
    max_number_bytes_method_names:
        json[r'max_number_bytes_method_names'] == null
        ? null
        : (json[r'max_number_bytes_method_names'] as num).toInt(),
    max_number_input_data_dependencies:
        json[r'max_number_input_data_dependencies'] == null
        ? null
        : (json[r'max_number_input_data_dependencies'] as num).toInt(),
    max_number_logs: json[r'max_number_logs'] == null
        ? null
        : (json[r'max_number_logs'] as num).toInt(),
    max_number_registers: json[r'max_number_registers'] == null
        ? null
        : (json[r'max_number_registers'] as num).toInt(),
    max_operand_stack_bytes_per_function:
        json[r'max_operand_stack_bytes_per_function'] == null
        ? null
        : (json[r'max_operand_stack_bytes_per_function'] as num).toInt(),
    max_params_per_contract: json[r'max_params_per_contract'] == null
        ? null
        : (json[r'max_params_per_contract'] as num).toInt(),
    max_params_per_function: json[r'max_params_per_function'] == null
        ? null
        : (json[r'max_params_per_function'] as num).toInt(),
    max_promises_per_function_call_action:
        json[r'max_promises_per_function_call_action'] == null
        ? null
        : (json[r'max_promises_per_function_call_action'] as num).toInt(),
    max_receipt_size: json[r'max_receipt_size'] == null
        ? null
        : (json[r'max_receipt_size'] as num).toInt(),
    max_register_size: json[r'max_register_size'] == null
        ? null
        : (json[r'max_register_size'] as num).toInt(),
    max_stack_height: json[r'max_stack_height'] == null
        ? null
        : (json[r'max_stack_height'] as num).toInt(),
    max_tables_per_contract: json[r'max_tables_per_contract'] == null
        ? null
        : (json[r'max_tables_per_contract'] as num).toInt(),
    max_total_log_length: json[r'max_total_log_length'] == null
        ? null
        : (json[r'max_total_log_length'] as num).toInt(),
    max_total_prepaid_gas: json[r'max_total_prepaid_gas'] == null
        ? null
        : json[r'max_total_prepaid_gas'] as NearGas,
    max_transaction_size: json[r'max_transaction_size'] == null
        ? null
        : (json[r'max_transaction_size'] as num).toInt(),
    max_types_per_contract: json[r'max_types_per_contract'] == null
        ? null
        : (json[r'max_types_per_contract'] as num).toInt(),
    max_yield_payload_size: json[r'max_yield_payload_size'] == null
        ? null
        : (json[r'max_yield_payload_size'] as num).toInt(),
    per_receipt_storage_proof_size_limit:
        json[r'per_receipt_storage_proof_size_limit'] == null
        ? null
        : (json[r'per_receipt_storage_proof_size_limit'] as num).toInt(),
    registers_memory_limit: json[r'registers_memory_limit'] == null
        ? null
        : (json[r'registers_memory_limit'] as num).toInt(),
    yield_timeout_length_in_blocks:
        json[r'yield_timeout_length_in_blocks'] == null
        ? null
        : (json[r'yield_timeout_length_in_blocks'] as num).toInt(),
  );

  final AccountIdValidityRulesVersion? account_id_validity_rules_version;
  final int? initial_memory_pages;
  final int? max_actions_per_receipt;
  final int? max_arguments_length;
  final int? max_blocks_per_contract;
  final int? max_blocks_per_function;
  final int? max_contract_size;
  final int? max_deploy_actions_per_receipt;
  final int? max_elements_per_contract_table;
  final int? max_function_body_size;
  final int? max_functions_number_per_contract;
  final NearGas? max_gas_burnt;
  final int? max_instrumented_code_size;
  final int? max_length_method_name;
  final int? max_length_returned_data;
  final int? max_length_storage_key;
  final int? max_length_storage_value;
  final int? max_locals_per_contract;
  final int? max_memory_pages;
  final int? max_number_bytes_method_names;
  final int? max_number_input_data_dependencies;
  final int? max_number_logs;
  final int? max_number_registers;
  final int? max_operand_stack_bytes_per_function;
  final int? max_params_per_contract;
  final int? max_params_per_function;
  final int? max_promises_per_function_call_action;
  final int? max_receipt_size;
  final int? max_register_size;
  final int? max_stack_height;
  final int? max_tables_per_contract;
  final int? max_total_log_length;
  final NearGas? max_total_prepaid_gas;
  final int? max_transaction_size;
  final int? max_types_per_contract;
  final int? max_yield_payload_size;
  final int? per_receipt_storage_proof_size_limit;
  final int? registers_memory_limit;
  final int? yield_timeout_length_in_blocks;

  Map<String, dynamic> toJson() => {
    if (account_id_validity_rules_version != null)
      r'account_id_validity_rules_version': account_id_validity_rules_version,
    if (initial_memory_pages != null)
      r'initial_memory_pages': initial_memory_pages,
    if (max_actions_per_receipt != null)
      r'max_actions_per_receipt': max_actions_per_receipt,
    if (max_arguments_length != null)
      r'max_arguments_length': max_arguments_length,
    if (max_blocks_per_contract != null)
      r'max_blocks_per_contract': max_blocks_per_contract,
    if (max_blocks_per_function != null)
      r'max_blocks_per_function': max_blocks_per_function,
    if (max_contract_size != null) r'max_contract_size': max_contract_size,
    if (max_deploy_actions_per_receipt != null)
      r'max_deploy_actions_per_receipt': max_deploy_actions_per_receipt,
    if (max_elements_per_contract_table != null)
      r'max_elements_per_contract_table': max_elements_per_contract_table,
    if (max_function_body_size != null)
      r'max_function_body_size': max_function_body_size,
    if (max_functions_number_per_contract != null)
      r'max_functions_number_per_contract': max_functions_number_per_contract,
    if (max_gas_burnt != null) r'max_gas_burnt': max_gas_burnt,
    if (max_instrumented_code_size != null)
      r'max_instrumented_code_size': max_instrumented_code_size,
    if (max_length_method_name != null)
      r'max_length_method_name': max_length_method_name,
    if (max_length_returned_data != null)
      r'max_length_returned_data': max_length_returned_data,
    if (max_length_storage_key != null)
      r'max_length_storage_key': max_length_storage_key,
    if (max_length_storage_value != null)
      r'max_length_storage_value': max_length_storage_value,
    if (max_locals_per_contract != null)
      r'max_locals_per_contract': max_locals_per_contract,
    if (max_memory_pages != null) r'max_memory_pages': max_memory_pages,
    if (max_number_bytes_method_names != null)
      r'max_number_bytes_method_names': max_number_bytes_method_names,
    if (max_number_input_data_dependencies != null)
      r'max_number_input_data_dependencies': max_number_input_data_dependencies,
    if (max_number_logs != null) r'max_number_logs': max_number_logs,
    if (max_number_registers != null)
      r'max_number_registers': max_number_registers,
    if (max_operand_stack_bytes_per_function != null)
      r'max_operand_stack_bytes_per_function':
          max_operand_stack_bytes_per_function,
    if (max_params_per_contract != null)
      r'max_params_per_contract': max_params_per_contract,
    if (max_params_per_function != null)
      r'max_params_per_function': max_params_per_function,
    if (max_promises_per_function_call_action != null)
      r'max_promises_per_function_call_action':
          max_promises_per_function_call_action,
    if (max_receipt_size != null) r'max_receipt_size': max_receipt_size,
    if (max_register_size != null) r'max_register_size': max_register_size,
    if (max_stack_height != null) r'max_stack_height': max_stack_height,
    if (max_tables_per_contract != null)
      r'max_tables_per_contract': max_tables_per_contract,
    if (max_total_log_length != null)
      r'max_total_log_length': max_total_log_length,
    if (max_total_prepaid_gas != null)
      r'max_total_prepaid_gas': max_total_prepaid_gas,
    if (max_transaction_size != null)
      r'max_transaction_size': max_transaction_size,
    if (max_types_per_contract != null)
      r'max_types_per_contract': max_types_per_contract,
    if (max_yield_payload_size != null)
      r'max_yield_payload_size': max_yield_payload_size,
    if (per_receipt_storage_proof_size_limit != null)
      r'per_receipt_storage_proof_size_limit':
          per_receipt_storage_proof_size_limit,
    if (registers_memory_limit != null)
      r'registers_memory_limit': registers_memory_limit,
    if (yield_timeout_length_in_blocks != null)
      r'yield_timeout_length_in_blocks': yield_timeout_length_in_blocks,
  };
}

/// Generated from `LogSummaryStyle`.
enum LogSummaryStyle {
  plain(r'plain'),
  colored(r'colored');

  const LogSummaryStyle(this.wireValue);
  final String wireValue;

  static LogSummaryStyle fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Generated from `MerklePathItem`.
class MerklePathItem {
  const MerklePathItem({this.direction, this.hash});

  factory MerklePathItem.fromJson(Map<String, dynamic> json) => MerklePathItem(
    direction: json[r'direction'] == null
        ? null
        : Direction.fromJson(json[r'direction']),
    hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
  );

  final Direction? direction;
  final CryptoHash? hash;

  Map<String, dynamic> toJson() => {
    if (direction != null) r'direction': direction?.toJson(),
    if (hash != null) r'hash': hash,
  };
}

/// Generated from `MethodResolveError`.
enum MethodResolveError {
  MethodEmptyName(r'MethodEmptyName'),
  MethodNotFound(r'MethodNotFound'),
  MethodInvalidSignature(r'MethodInvalidSignature');

  const MethodResolveError(this.wireValue);
  final String wireValue;

  static MethodResolveError fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Generated from `MissingTrieValue`.
class MissingTrieValue {
  const MissingTrieValue({this.context, this.hash});

  factory MissingTrieValue.fromJson(Map<String, dynamic> json) =>
      MissingTrieValue(
        context: json[r'context'] == null
            ? null
            : MissingTrieValueContext.fromJson(json[r'context']),
        hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
      );

  final MissingTrieValueContext? context;
  final CryptoHash? hash;

  Map<String, dynamic> toJson() => {
    if (context != null) r'context': context?.toJson(),
    if (hash != null) r'hash': hash,
  };
}

/// Union type generated from `MissingTrieValueContext`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class MissingTrieValueContext {
  const MissingTrieValueContext(this.json);
  factory MissingTrieValueContext.fromJson(dynamic json) =>
      MissingTrieValueContext(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Alias for `MutableConfigValue`.
typedef MutableConfigValue = String;

/// Alias for `NearGas`.
typedef NearGas = int;

/// Alias for `NearToken`.
typedef NearToken = String;

/// Generated from `NetworkInfoView`.
class NetworkInfoView {
  const NetworkInfoView({
    this.connected_peers,
    this.known_producers,
    this.num_connected_peers,
    this.peer_max_count,
    this.tier1_accounts_data,
    this.tier1_accounts_keys,
    this.tier1_connections,
  });

  factory NetworkInfoView.fromJson(Map<String, dynamic> json) =>
      NetworkInfoView(
        connected_peers: json[r'connected_peers'] == null
            ? null
            : (json[r'connected_peers'] as List)
                  .map<PeerInfoView>((e) => PeerInfoView.fromJson(e))
                  .toList(),
        known_producers: json[r'known_producers'] == null
            ? null
            : (json[r'known_producers'] as List)
                  .map<KnownProducerView>((e) => KnownProducerView.fromJson(e))
                  .toList(),
        num_connected_peers: json[r'num_connected_peers'] == null
            ? null
            : (json[r'num_connected_peers'] as num).toInt(),
        peer_max_count: json[r'peer_max_count'] == null
            ? null
            : (json[r'peer_max_count'] as num).toInt(),
        tier1_accounts_data: json[r'tier1_accounts_data'] == null
            ? null
            : (json[r'tier1_accounts_data'] as List)
                  .map<AccountDataView>((e) => AccountDataView.fromJson(e))
                  .toList(),
        tier1_accounts_keys: json[r'tier1_accounts_keys'] == null
            ? null
            : (json[r'tier1_accounts_keys'] as List)
                  .map<PublicKey>((e) => e as PublicKey)
                  .toList(),
        tier1_connections: json[r'tier1_connections'] == null
            ? null
            : (json[r'tier1_connections'] as List)
                  .map<PeerInfoView>((e) => PeerInfoView.fromJson(e))
                  .toList(),
      );

  final List<PeerInfoView>? connected_peers;
  final List<KnownProducerView>? known_producers;
  final int? num_connected_peers;
  final int? peer_max_count;
  final List<AccountDataView>? tier1_accounts_data;
  final List<PublicKey>? tier1_accounts_keys;
  final List<PeerInfoView>? tier1_connections;

  Map<String, dynamic> toJson() => {
    if (connected_peers != null)
      r'connected_peers': connected_peers?.map((e) => e.toJson()).toList(),
    if (known_producers != null)
      r'known_producers': known_producers?.map((e) => e.toJson()).toList(),
    if (num_connected_peers != null)
      r'num_connected_peers': num_connected_peers,
    if (peer_max_count != null) r'peer_max_count': peer_max_count,
    if (tier1_accounts_data != null)
      r'tier1_accounts_data': tier1_accounts_data
          ?.map((e) => e.toJson())
          .toList(),
    if (tier1_accounts_keys != null)
      r'tier1_accounts_keys': tier1_accounts_keys,
    if (tier1_connections != null)
      r'tier1_connections': tier1_connections?.map((e) => e.toJson()).toList(),
  };
}

/// Generated from `NextEpochValidatorInfo`.
class NextEpochValidatorInfo {
  const NextEpochValidatorInfo({
    this.account_id,
    this.public_key,
    this.shards,
    this.stake,
  });

  factory NextEpochValidatorInfo.fromJson(Map<String, dynamic> json) =>
      NextEpochValidatorInfo(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
        shards: json[r'shards'] == null
            ? null
            : (json[r'shards'] as List)
                  .map<ShardId>((e) => e as ShardId)
                  .toList(),
        stake: json[r'stake'] == null ? null : json[r'stake'] as NearToken,
      );

  final AccountId? account_id;
  final PublicKey? public_key;
  final List<ShardId>? shards;
  final NearToken? stake;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (public_key != null) r'public_key': public_key,
    if (shards != null) r'shards': shards,
    if (stake != null) r'stake': stake,
  };
}

/// Union type generated from `NonDelegateAction`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class NonDelegateAction {
  const NonDelegateAction(this.json);
  factory NonDelegateAction.fromJson(dynamic json) => NonDelegateAction(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `NonceMode`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class NonceMode {
  const NonceMode(this.json);
  factory NonceMode.fromJson(dynamic json) => NonceMode(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `PeerId`.
class PeerId {
  const PeerId();

  factory PeerId.fromJson(Map<String, dynamic> json) => PeerId();

  Map<String, dynamic> toJson() => {};
}

/// Generated from `PeerInfoView`.
class PeerInfoView {
  const PeerInfoView({
    this.account_id,
    this.addr,
    this.archival,
    this.block_hash,
    this.connection_established_time_millis,
    this.height,
    this.is_highest_block_invalid,
    this.is_outbound_peer,
    this.last_time_peer_requested_millis,
    this.last_time_received_message_millis,
    this.nonce,
    this.peer_id,
    this.received_bytes_per_sec,
    this.sent_bytes_per_sec,
    this.tracked_shards,
  });

  factory PeerInfoView.fromJson(Map<String, dynamic> json) => PeerInfoView(
    account_id: json[r'account_id'] == null ? null : json[r'account_id'],
    addr: json[r'addr'] == null ? null : json[r'addr'] as String,
    archival: json[r'archival'] == null ? null : json[r'archival'] as bool,
    block_hash: json[r'block_hash'] == null ? null : json[r'block_hash'],
    connection_established_time_millis:
        json[r'connection_established_time_millis'] == null
        ? null
        : (json[r'connection_established_time_millis'] as num).toInt(),
    height: json[r'height'] == null ? null : (json[r'height'] as num).toInt(),
    is_highest_block_invalid: json[r'is_highest_block_invalid'] == null
        ? null
        : json[r'is_highest_block_invalid'] as bool,
    is_outbound_peer: json[r'is_outbound_peer'] == null
        ? null
        : json[r'is_outbound_peer'] as bool,
    last_time_peer_requested_millis:
        json[r'last_time_peer_requested_millis'] == null
        ? null
        : (json[r'last_time_peer_requested_millis'] as num).toInt(),
    last_time_received_message_millis:
        json[r'last_time_received_message_millis'] == null
        ? null
        : (json[r'last_time_received_message_millis'] as num).toInt(),
    nonce: json[r'nonce'] == null ? null : (json[r'nonce'] as num).toInt(),
    peer_id: json[r'peer_id'] == null ? null : json[r'peer_id'] as PublicKey,
    received_bytes_per_sec: json[r'received_bytes_per_sec'] == null
        ? null
        : (json[r'received_bytes_per_sec'] as num).toInt(),
    sent_bytes_per_sec: json[r'sent_bytes_per_sec'] == null
        ? null
        : (json[r'sent_bytes_per_sec'] as num).toInt(),
    tracked_shards: json[r'tracked_shards'] == null
        ? null
        : (json[r'tracked_shards'] as List)
              .map<ShardId>((e) => e as ShardId)
              .toList(),
  );

  final dynamic? account_id;
  final String? addr;
  final bool? archival;
  final dynamic? block_hash;
  final int? connection_established_time_millis;
  final int? height;
  final bool? is_highest_block_invalid;
  final bool? is_outbound_peer;
  final int? last_time_peer_requested_millis;
  final int? last_time_received_message_millis;
  final int? nonce;
  final PublicKey? peer_id;
  final int? received_bytes_per_sec;
  final int? sent_bytes_per_sec;
  final List<ShardId>? tracked_shards;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (addr != null) r'addr': addr,
    if (archival != null) r'archival': archival,
    if (block_hash != null) r'block_hash': block_hash,
    if (connection_established_time_millis != null)
      r'connection_established_time_millis': connection_established_time_millis,
    if (height != null) r'height': height,
    if (is_highest_block_invalid != null)
      r'is_highest_block_invalid': is_highest_block_invalid,
    if (is_outbound_peer != null) r'is_outbound_peer': is_outbound_peer,
    if (last_time_peer_requested_millis != null)
      r'last_time_peer_requested_millis': last_time_peer_requested_millis,
    if (last_time_received_message_millis != null)
      r'last_time_received_message_millis': last_time_received_message_millis,
    if (nonce != null) r'nonce': nonce,
    if (peer_id != null) r'peer_id': peer_id,
    if (received_bytes_per_sec != null)
      r'received_bytes_per_sec': received_bytes_per_sec,
    if (sent_bytes_per_sec != null) r'sent_bytes_per_sec': sent_bytes_per_sec,
    if (tracked_shards != null) r'tracked_shards': tracked_shards,
  };
}

/// Union type generated from `PrepareError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class PrepareError {
  const PrepareError(this.json);
  factory PrepareError.fromJson(dynamic json) => PrepareError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ProtocolVersionCheckConfig`.
enum ProtocolVersionCheckConfig {
  Next(r'Next'),
  NextNext(r'NextNext');

  const ProtocolVersionCheckConfig(this.wireValue);
  final String wireValue;

  static ProtocolVersionCheckConfig fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Alias for `PublicKey`.
typedef PublicKey = String;

/// Alias for `PublicKeyHandle`.
typedef PublicKeyHandle = String;

/// Generated from `Range_of_uint64`.
class Range_of_uint64 {
  const Range_of_uint64({this.end, this.start});

  factory Range_of_uint64.fromJson(Map<String, dynamic> json) =>
      Range_of_uint64(
        end: json[r'end'] == null ? null : (json[r'end'] as num).toInt(),
        start: json[r'start'] == null ? null : (json[r'start'] as num).toInt(),
      );

  final int? end;
  final int? start;

  Map<String, dynamic> toJson() => {
    if (end != null) r'end': end,
    if (start != null) r'start': start,
  };
}

/// Union type generated from `ReceiptEnumView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ReceiptEnumView {
  const ReceiptEnumView(this.json);
  factory ReceiptEnumView.fromJson(dynamic json) => ReceiptEnumView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `ReceiptValidationError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ReceiptValidationError {
  const ReceiptValidationError(this.json);
  factory ReceiptValidationError.fromJson(dynamic json) =>
      ReceiptValidationError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ReceiptView`.
class ReceiptView {
  const ReceiptView({
    this.predecessor_id,
    this.priority,
    this.receipt,
    this.receipt_id,
    this.receiver_id,
  });

  factory ReceiptView.fromJson(Map<String, dynamic> json) => ReceiptView(
    predecessor_id: json[r'predecessor_id'] == null
        ? null
        : json[r'predecessor_id'] as AccountId,
    priority: json[r'priority'] == null
        ? null
        : (json[r'priority'] as num).toInt(),
    receipt: json[r'receipt'] == null
        ? null
        : ReceiptEnumView.fromJson(json[r'receipt']),
    receipt_id: json[r'receipt_id'] == null
        ? null
        : json[r'receipt_id'] as CryptoHash,
    receiver_id: json[r'receiver_id'] == null
        ? null
        : json[r'receiver_id'] as AccountId,
  );

  final AccountId? predecessor_id;
  final int? priority;
  final ReceiptEnumView? receipt;
  final CryptoHash? receipt_id;
  final AccountId? receiver_id;

  Map<String, dynamic> toJson() => {
    if (predecessor_id != null) r'predecessor_id': predecessor_id,
    if (priority != null) r'priority': priority,
    if (receipt != null) r'receipt': receipt?.toJson(),
    if (receipt_id != null) r'receipt_id': receipt_id,
    if (receiver_id != null) r'receiver_id': receiver_id,
  };
}

/// Union type generated from `RpcBlockError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcBlockError {
  const RpcBlockError(this.json);
  factory RpcBlockError.fromJson(dynamic json) => RpcBlockError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcBlockRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcBlockRequest {
  const RpcBlockRequest(this.json);
  factory RpcBlockRequest.fromJson(dynamic json) => RpcBlockRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcBlockResponse`.
class RpcBlockResponse {
  const RpcBlockResponse({this.author, this.chunks, this.header});

  factory RpcBlockResponse.fromJson(Map<String, dynamic> json) =>
      RpcBlockResponse(
        author: json[r'author'] == null ? null : json[r'author'] as AccountId,
        chunks: json[r'chunks'] == null
            ? null
            : (json[r'chunks'] as List)
                  .map<ChunkHeaderView>((e) => ChunkHeaderView.fromJson(e))
                  .toList(),
        header: json[r'header'] == null
            ? null
            : BlockHeaderView.fromJson(json[r'header']),
      );

  final AccountId? author;
  final List<ChunkHeaderView>? chunks;
  final BlockHeaderView? header;

  Map<String, dynamic> toJson() => {
    if (author != null) r'author': author,
    if (chunks != null) r'chunks': chunks?.map((e) => e.toJson()).toList(),
    if (header != null) r'header': header?.toJson(),
  };
}

/// Union type generated from `RpcCallFunctionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcCallFunctionError {
  const RpcCallFunctionError(this.json);
  factory RpcCallFunctionError.fromJson(dynamic json) =>
      RpcCallFunctionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcCallFunctionRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcCallFunctionRequest {
  const RpcCallFunctionRequest(this.json);
  factory RpcCallFunctionRequest.fromJson(dynamic json) =>
      RpcCallFunctionRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcCallFunctionResponse`.
class RpcCallFunctionResponse {
  const RpcCallFunctionResponse({
    this.block_hash,
    this.block_height,
    this.logs,
    this.result,
  });

  factory RpcCallFunctionResponse.fromJson(Map<String, dynamic> json) =>
      RpcCallFunctionResponse(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        logs: json[r'logs'] == null
            ? null
            : (json[r'logs'] as List).map<String>((e) => e as String).toList(),
        result: json[r'result'] == null
            ? null
            : (json[r'result'] as List)
                  .map<int>((e) => (e as num).toInt())
                  .toList(),
      );

  final CryptoHash? block_hash;
  final int? block_height;
  final List<String>? logs;
  final List<int>? result;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (block_height != null) r'block_height': block_height,
    if (logs != null) r'logs': logs,
    if (result != null) r'result': result,
  };
}

/// Union type generated from `RpcChunkError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcChunkError {
  const RpcChunkError(this.json);
  factory RpcChunkError.fromJson(dynamic json) => RpcChunkError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcChunkRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcChunkRequest {
  const RpcChunkRequest(this.json);
  factory RpcChunkRequest.fromJson(dynamic json) => RpcChunkRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcChunkResponse`.
class RpcChunkResponse {
  const RpcChunkResponse({
    this.author,
    this.header,
    this.receipts,
    this.transactions,
  });

  factory RpcChunkResponse.fromJson(Map<String, dynamic> json) =>
      RpcChunkResponse(
        author: json[r'author'] == null ? null : json[r'author'] as AccountId,
        header: json[r'header'] == null
            ? null
            : ChunkHeaderView.fromJson(json[r'header']),
        receipts: json[r'receipts'] == null
            ? null
            : (json[r'receipts'] as List)
                  .map<ReceiptView>((e) => ReceiptView.fromJson(e))
                  .toList(),
        transactions: json[r'transactions'] == null
            ? null
            : (json[r'transactions'] as List)
                  .map<SignedTransactionView>(
                    (e) => SignedTransactionView.fromJson(e),
                  )
                  .toList(),
      );

  final AccountId? author;
  final ChunkHeaderView? header;
  final List<ReceiptView>? receipts;
  final List<SignedTransactionView>? transactions;

  Map<String, dynamic> toJson() => {
    if (author != null) r'author': author,
    if (header != null) r'header': header?.toJson(),
    if (receipts != null)
      r'receipts': receipts?.map((e) => e.toJson()).toList(),
    if (transactions != null)
      r'transactions': transactions?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `RpcClientConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcClientConfigError {
  const RpcClientConfigError(this.json);
  factory RpcClientConfigError.fromJson(dynamic json) =>
      RpcClientConfigError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Alias for `RpcClientConfigRequest`.
typedef RpcClientConfigRequest = dynamic;

/// Generated from `RpcClientConfigResponse`.
class RpcClientConfigResponse {
  const RpcClientConfigResponse({
    this.archive,
    this.block_header_fetch_horizon,
    this.block_production_tracking_delay,
    this.catchup_step_period,
    this.chain_id,
    this.chunk_distribution_network,
    this.chunk_request_retry_period,
    this.chunk_validation_threads,
    this.chunk_wait_mult,
    this.chunks_cache_height_horizon,
    this.client_background_migration_threads,
    this.cloud_archival_writer,
    this.disable_tx_routing,
    this.doomslug_step_period,
    this.enable_early_prepare_transactions,
    this.enable_multiline_logging,
    this.enable_statistics_export,
    this.epoch_length,
    this.epoch_sync,
    this.expected_shutdown,
    this.gc,
    this.header_sync_expected_height_per_second,
    this.header_sync_initial_timeout,
    this.header_sync_progress_timeout,
    this.header_sync_stall_ban_timeout,
    this.log_summary_period,
    this.log_summary_style,
    this.max_block_production_delay,
    this.max_block_wait_delay,
    this.max_gas_burnt_view,
    this.min_block_production_delay,
    this.min_num_peers,
    this.num_block_producer_seats,
    this.orphan_state_witness_max_size,
    this.orphan_state_witness_pool_size,
    this.produce_chunk_add_transactions_time_limit,
    this.produce_empty_blocks,
    this.protocol_version_check,
    this.receipt_to_tx_max_hint_window,
    this.receipt_to_tx_max_hop_distance,
    this.receipt_to_tx_max_outcomes_per_request,
    this.resharding_config,
    this.rpc_addr,
    this.save_invalid_witnesses,
    this.save_latest_witnesses,
    this.save_receipt_to_tx,
    this.save_state_changes,
    this.save_trie_changes,
    this.save_tx_outcomes,
    this.save_untracked_partial_chunks_parts,
    this.skip_sync_wait,
    this.state_request_server_threads,
    this.state_request_throttle_period,
    this.state_requests_per_throttle_period,
    this.state_sync,
    this.state_sync_external_backoff,
    this.state_sync_external_timeout,
    this.state_sync_p2p_timeout,
    this.state_sync_retry_backoff,
    this.sync_check_period,
    this.sync_height_threshold,
    this.sync_max_block_requests,
    this.sync_step_period,
    this.tracked_shards_config,
    this.transaction_pool_size_limit,
    this.transaction_pool_strict_nonce_ttl_blocks,
    this.transaction_request_handler_threads,
    this.trie_viewer_state_size_limit,
    this.ttl_account_id_router,
    this.tx_routing_height_horizon,
    this.version,
    this.view_client_threads,
  });

  factory RpcClientConfigResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcClientConfigResponse(
    archive: json[r'archive'] == null ? null : json[r'archive'] as bool,
    block_header_fetch_horizon: json[r'block_header_fetch_horizon'] == null
        ? null
        : (json[r'block_header_fetch_horizon'] as num).toInt(),
    block_production_tracking_delay:
        json[r'block_production_tracking_delay'] == null
        ? null
        : json[r'block_production_tracking_delay'] as MutableConfigValue,
    catchup_step_period: json[r'catchup_step_period'] == null
        ? null
        : (json[r'catchup_step_period'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    chain_id: json[r'chain_id'] == null ? null : json[r'chain_id'] as String,
    chunk_distribution_network: json[r'chunk_distribution_network'] == null
        ? null
        : json[r'chunk_distribution_network'],
    chunk_request_retry_period: json[r'chunk_request_retry_period'] == null
        ? null
        : (json[r'chunk_request_retry_period'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    chunk_validation_threads: json[r'chunk_validation_threads'] == null
        ? null
        : (json[r'chunk_validation_threads'] as num).toInt(),
    chunk_wait_mult: json[r'chunk_wait_mult'] == null
        ? null
        : json[r'chunk_wait_mult'] as MutableConfigValue,
    chunks_cache_height_horizon: json[r'chunks_cache_height_horizon'] == null
        ? null
        : (json[r'chunks_cache_height_horizon'] as num).toInt(),
    client_background_migration_threads:
        json[r'client_background_migration_threads'] == null
        ? null
        : (json[r'client_background_migration_threads'] as num).toInt(),
    cloud_archival_writer: json[r'cloud_archival_writer'] == null
        ? null
        : json[r'cloud_archival_writer'],
    disable_tx_routing: json[r'disable_tx_routing'] == null
        ? null
        : json[r'disable_tx_routing'] as bool,
    doomslug_step_period: json[r'doomslug_step_period'] == null
        ? null
        : json[r'doomslug_step_period'] as MutableConfigValue,
    enable_early_prepare_transactions:
        json[r'enable_early_prepare_transactions'] == null
        ? null
        : json[r'enable_early_prepare_transactions'] as bool,
    enable_multiline_logging: json[r'enable_multiline_logging'] == null
        ? null
        : json[r'enable_multiline_logging'] as bool,
    enable_statistics_export: json[r'enable_statistics_export'] == null
        ? null
        : json[r'enable_statistics_export'] as bool,
    epoch_length: json[r'epoch_length'] == null
        ? null
        : (json[r'epoch_length'] as num).toInt(),
    epoch_sync: json[r'epoch_sync'] == null
        ? null
        : EpochSyncConfig.fromJson(json[r'epoch_sync']),
    expected_shutdown: json[r'expected_shutdown'] == null
        ? null
        : json[r'expected_shutdown'] as MutableConfigValue,
    gc: json[r'gc'] == null ? null : GCConfig.fromJson(json[r'gc']),
    header_sync_expected_height_per_second:
        json[r'header_sync_expected_height_per_second'] == null
        ? null
        : (json[r'header_sync_expected_height_per_second'] as num).toInt(),
    header_sync_initial_timeout: json[r'header_sync_initial_timeout'] == null
        ? null
        : (json[r'header_sync_initial_timeout'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    header_sync_progress_timeout: json[r'header_sync_progress_timeout'] == null
        ? null
        : (json[r'header_sync_progress_timeout'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    header_sync_stall_ban_timeout:
        json[r'header_sync_stall_ban_timeout'] == null
        ? null
        : (json[r'header_sync_stall_ban_timeout'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    log_summary_period: json[r'log_summary_period'] == null
        ? null
        : (json[r'log_summary_period'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    log_summary_style: json[r'log_summary_style'] == null
        ? null
        : LogSummaryStyle.fromJson(json[r'log_summary_style']),
    max_block_production_delay: json[r'max_block_production_delay'] == null
        ? null
        : json[r'max_block_production_delay'] as MutableConfigValue,
    max_block_wait_delay: json[r'max_block_wait_delay'] == null
        ? null
        : json[r'max_block_wait_delay'] as MutableConfigValue,
    max_gas_burnt_view: json[r'max_gas_burnt_view'] == null
        ? null
        : json[r'max_gas_burnt_view'],
    min_block_production_delay: json[r'min_block_production_delay'] == null
        ? null
        : json[r'min_block_production_delay'] as MutableConfigValue,
    min_num_peers: json[r'min_num_peers'] == null
        ? null
        : (json[r'min_num_peers'] as num).toInt(),
    num_block_producer_seats: json[r'num_block_producer_seats'] == null
        ? null
        : (json[r'num_block_producer_seats'] as num).toInt(),
    orphan_state_witness_max_size:
        json[r'orphan_state_witness_max_size'] == null
        ? null
        : (json[r'orphan_state_witness_max_size'] as num).toInt(),
    orphan_state_witness_pool_size:
        json[r'orphan_state_witness_pool_size'] == null
        ? null
        : (json[r'orphan_state_witness_pool_size'] as num).toInt(),
    produce_chunk_add_transactions_time_limit:
        json[r'produce_chunk_add_transactions_time_limit'] == null
        ? null
        : json[r'produce_chunk_add_transactions_time_limit'] as String,
    produce_empty_blocks: json[r'produce_empty_blocks'] == null
        ? null
        : json[r'produce_empty_blocks'] as bool,
    protocol_version_check: json[r'protocol_version_check'] == null
        ? null
        : ProtocolVersionCheckConfig.fromJson(json[r'protocol_version_check']),
    receipt_to_tx_max_hint_window:
        json[r'receipt_to_tx_max_hint_window'] == null
        ? null
        : (json[r'receipt_to_tx_max_hint_window'] as num).toInt(),
    receipt_to_tx_max_hop_distance:
        json[r'receipt_to_tx_max_hop_distance'] == null
        ? null
        : (json[r'receipt_to_tx_max_hop_distance'] as num).toInt(),
    receipt_to_tx_max_outcomes_per_request:
        json[r'receipt_to_tx_max_outcomes_per_request'] == null
        ? null
        : (json[r'receipt_to_tx_max_outcomes_per_request'] as num).toInt(),
    resharding_config: json[r'resharding_config'] == null
        ? null
        : json[r'resharding_config'] as MutableConfigValue,
    rpc_addr: json[r'rpc_addr'] == null ? null : json[r'rpc_addr'] as String,
    save_invalid_witnesses: json[r'save_invalid_witnesses'] == null
        ? null
        : json[r'save_invalid_witnesses'] as bool,
    save_latest_witnesses: json[r'save_latest_witnesses'] == null
        ? null
        : json[r'save_latest_witnesses'] as bool,
    save_receipt_to_tx: json[r'save_receipt_to_tx'] == null
        ? null
        : json[r'save_receipt_to_tx'] as bool,
    save_state_changes: json[r'save_state_changes'] == null
        ? null
        : json[r'save_state_changes'] as bool,
    save_trie_changes: json[r'save_trie_changes'] == null
        ? null
        : json[r'save_trie_changes'] as bool,
    save_tx_outcomes: json[r'save_tx_outcomes'] == null
        ? null
        : json[r'save_tx_outcomes'] as bool,
    save_untracked_partial_chunks_parts:
        json[r'save_untracked_partial_chunks_parts'] == null
        ? null
        : json[r'save_untracked_partial_chunks_parts'] as bool,
    skip_sync_wait: json[r'skip_sync_wait'] == null
        ? null
        : json[r'skip_sync_wait'] as bool,
    state_request_server_threads: json[r'state_request_server_threads'] == null
        ? null
        : (json[r'state_request_server_threads'] as num).toInt(),
    state_request_throttle_period:
        json[r'state_request_throttle_period'] == null
        ? null
        : (json[r'state_request_throttle_period'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    state_requests_per_throttle_period:
        json[r'state_requests_per_throttle_period'] == null
        ? null
        : (json[r'state_requests_per_throttle_period'] as num).toInt(),
    state_sync: json[r'state_sync'] == null
        ? null
        : StateSyncConfig.fromJson(json[r'state_sync']),
    state_sync_external_backoff: json[r'state_sync_external_backoff'] == null
        ? null
        : (json[r'state_sync_external_backoff'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    state_sync_external_timeout: json[r'state_sync_external_timeout'] == null
        ? null
        : (json[r'state_sync_external_timeout'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    state_sync_p2p_timeout: json[r'state_sync_p2p_timeout'] == null
        ? null
        : (json[r'state_sync_p2p_timeout'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    state_sync_retry_backoff: json[r'state_sync_retry_backoff'] == null
        ? null
        : (json[r'state_sync_retry_backoff'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    sync_check_period: json[r'sync_check_period'] == null
        ? null
        : (json[r'sync_check_period'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    sync_height_threshold: json[r'sync_height_threshold'] == null
        ? null
        : (json[r'sync_height_threshold'] as num).toInt(),
    sync_max_block_requests: json[r'sync_max_block_requests'] == null
        ? null
        : (json[r'sync_max_block_requests'] as num).toInt(),
    sync_step_period: json[r'sync_step_period'] == null
        ? null
        : (json[r'sync_step_period'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    tracked_shards_config: json[r'tracked_shards_config'] == null
        ? null
        : TrackedShardsConfig.fromJson(json[r'tracked_shards_config']),
    transaction_pool_size_limit: json[r'transaction_pool_size_limit'] == null
        ? null
        : (json[r'transaction_pool_size_limit'] as num).toInt(),
    transaction_pool_strict_nonce_ttl_blocks:
        json[r'transaction_pool_strict_nonce_ttl_blocks'] == null
        ? null
        : (json[r'transaction_pool_strict_nonce_ttl_blocks'] as num).toInt(),
    transaction_request_handler_threads:
        json[r'transaction_request_handler_threads'] == null
        ? null
        : (json[r'transaction_request_handler_threads'] as num).toInt(),
    trie_viewer_state_size_limit: json[r'trie_viewer_state_size_limit'] == null
        ? null
        : (json[r'trie_viewer_state_size_limit'] as num).toInt(),
    ttl_account_id_router: json[r'ttl_account_id_router'] == null
        ? null
        : (json[r'ttl_account_id_router'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    tx_routing_height_horizon: json[r'tx_routing_height_horizon'] == null
        ? null
        : (json[r'tx_routing_height_horizon'] as num).toInt(),
    version: json[r'version'] == null
        ? null
        : Version.fromJson(json[r'version']),
    view_client_threads: json[r'view_client_threads'] == null
        ? null
        : (json[r'view_client_threads'] as num).toInt(),
  );

  final bool? archive;
  final int? block_header_fetch_horizon;
  final MutableConfigValue? block_production_tracking_delay;
  final List<int>? catchup_step_period;
  final String? chain_id;
  final dynamic? chunk_distribution_network;
  final List<int>? chunk_request_retry_period;
  final int? chunk_validation_threads;
  final MutableConfigValue? chunk_wait_mult;
  final int? chunks_cache_height_horizon;
  final int? client_background_migration_threads;
  final dynamic? cloud_archival_writer;
  final bool? disable_tx_routing;
  final MutableConfigValue? doomslug_step_period;
  final bool? enable_early_prepare_transactions;
  final bool? enable_multiline_logging;
  final bool? enable_statistics_export;
  final int? epoch_length;
  final EpochSyncConfig? epoch_sync;
  final MutableConfigValue? expected_shutdown;
  final GCConfig? gc;
  final int? header_sync_expected_height_per_second;
  final List<int>? header_sync_initial_timeout;
  final List<int>? header_sync_progress_timeout;
  final List<int>? header_sync_stall_ban_timeout;
  final List<int>? log_summary_period;
  final LogSummaryStyle? log_summary_style;
  final MutableConfigValue? max_block_production_delay;
  final MutableConfigValue? max_block_wait_delay;
  final dynamic? max_gas_burnt_view;
  final MutableConfigValue? min_block_production_delay;
  final int? min_num_peers;
  final int? num_block_producer_seats;
  final int? orphan_state_witness_max_size;
  final int? orphan_state_witness_pool_size;
  final String? produce_chunk_add_transactions_time_limit;
  final bool? produce_empty_blocks;
  final ProtocolVersionCheckConfig? protocol_version_check;
  final int? receipt_to_tx_max_hint_window;
  final int? receipt_to_tx_max_hop_distance;
  final int? receipt_to_tx_max_outcomes_per_request;
  final MutableConfigValue? resharding_config;
  final String? rpc_addr;
  final bool? save_invalid_witnesses;
  final bool? save_latest_witnesses;
  final bool? save_receipt_to_tx;
  final bool? save_state_changes;
  final bool? save_trie_changes;
  final bool? save_tx_outcomes;
  final bool? save_untracked_partial_chunks_parts;
  final bool? skip_sync_wait;
  final int? state_request_server_threads;
  final List<int>? state_request_throttle_period;
  final int? state_requests_per_throttle_period;
  final StateSyncConfig? state_sync;
  final List<int>? state_sync_external_backoff;
  final List<int>? state_sync_external_timeout;
  final List<int>? state_sync_p2p_timeout;
  final List<int>? state_sync_retry_backoff;
  final List<int>? sync_check_period;
  final int? sync_height_threshold;
  final int? sync_max_block_requests;
  final List<int>? sync_step_period;
  final TrackedShardsConfig? tracked_shards_config;
  final int? transaction_pool_size_limit;
  final int? transaction_pool_strict_nonce_ttl_blocks;
  final int? transaction_request_handler_threads;
  final int? trie_viewer_state_size_limit;
  final List<int>? ttl_account_id_router;
  final int? tx_routing_height_horizon;
  final Version? version;
  final int? view_client_threads;

  Map<String, dynamic> toJson() => {
    if (archive != null) r'archive': archive,
    if (block_header_fetch_horizon != null)
      r'block_header_fetch_horizon': block_header_fetch_horizon,
    if (block_production_tracking_delay != null)
      r'block_production_tracking_delay': block_production_tracking_delay,
    if (catchup_step_period != null)
      r'catchup_step_period': catchup_step_period,
    if (chain_id != null) r'chain_id': chain_id,
    if (chunk_distribution_network != null)
      r'chunk_distribution_network': chunk_distribution_network,
    if (chunk_request_retry_period != null)
      r'chunk_request_retry_period': chunk_request_retry_period,
    if (chunk_validation_threads != null)
      r'chunk_validation_threads': chunk_validation_threads,
    if (chunk_wait_mult != null) r'chunk_wait_mult': chunk_wait_mult,
    if (chunks_cache_height_horizon != null)
      r'chunks_cache_height_horizon': chunks_cache_height_horizon,
    if (client_background_migration_threads != null)
      r'client_background_migration_threads':
          client_background_migration_threads,
    if (cloud_archival_writer != null)
      r'cloud_archival_writer': cloud_archival_writer,
    if (disable_tx_routing != null) r'disable_tx_routing': disable_tx_routing,
    if (doomslug_step_period != null)
      r'doomslug_step_period': doomslug_step_period,
    if (enable_early_prepare_transactions != null)
      r'enable_early_prepare_transactions': enable_early_prepare_transactions,
    if (enable_multiline_logging != null)
      r'enable_multiline_logging': enable_multiline_logging,
    if (enable_statistics_export != null)
      r'enable_statistics_export': enable_statistics_export,
    if (epoch_length != null) r'epoch_length': epoch_length,
    if (epoch_sync != null) r'epoch_sync': epoch_sync?.toJson(),
    if (expected_shutdown != null) r'expected_shutdown': expected_shutdown,
    if (gc != null) r'gc': gc?.toJson(),
    if (header_sync_expected_height_per_second != null)
      r'header_sync_expected_height_per_second':
          header_sync_expected_height_per_second,
    if (header_sync_initial_timeout != null)
      r'header_sync_initial_timeout': header_sync_initial_timeout,
    if (header_sync_progress_timeout != null)
      r'header_sync_progress_timeout': header_sync_progress_timeout,
    if (header_sync_stall_ban_timeout != null)
      r'header_sync_stall_ban_timeout': header_sync_stall_ban_timeout,
    if (log_summary_period != null) r'log_summary_period': log_summary_period,
    if (log_summary_style != null)
      r'log_summary_style': log_summary_style?.toJson(),
    if (max_block_production_delay != null)
      r'max_block_production_delay': max_block_production_delay,
    if (max_block_wait_delay != null)
      r'max_block_wait_delay': max_block_wait_delay,
    if (max_gas_burnt_view != null) r'max_gas_burnt_view': max_gas_burnt_view,
    if (min_block_production_delay != null)
      r'min_block_production_delay': min_block_production_delay,
    if (min_num_peers != null) r'min_num_peers': min_num_peers,
    if (num_block_producer_seats != null)
      r'num_block_producer_seats': num_block_producer_seats,
    if (orphan_state_witness_max_size != null)
      r'orphan_state_witness_max_size': orphan_state_witness_max_size,
    if (orphan_state_witness_pool_size != null)
      r'orphan_state_witness_pool_size': orphan_state_witness_pool_size,
    if (produce_chunk_add_transactions_time_limit != null)
      r'produce_chunk_add_transactions_time_limit':
          produce_chunk_add_transactions_time_limit,
    if (produce_empty_blocks != null)
      r'produce_empty_blocks': produce_empty_blocks,
    if (protocol_version_check != null)
      r'protocol_version_check': protocol_version_check?.toJson(),
    if (receipt_to_tx_max_hint_window != null)
      r'receipt_to_tx_max_hint_window': receipt_to_tx_max_hint_window,
    if (receipt_to_tx_max_hop_distance != null)
      r'receipt_to_tx_max_hop_distance': receipt_to_tx_max_hop_distance,
    if (receipt_to_tx_max_outcomes_per_request != null)
      r'receipt_to_tx_max_outcomes_per_request':
          receipt_to_tx_max_outcomes_per_request,
    if (resharding_config != null) r'resharding_config': resharding_config,
    if (rpc_addr != null) r'rpc_addr': rpc_addr,
    if (save_invalid_witnesses != null)
      r'save_invalid_witnesses': save_invalid_witnesses,
    if (save_latest_witnesses != null)
      r'save_latest_witnesses': save_latest_witnesses,
    if (save_receipt_to_tx != null) r'save_receipt_to_tx': save_receipt_to_tx,
    if (save_state_changes != null) r'save_state_changes': save_state_changes,
    if (save_trie_changes != null) r'save_trie_changes': save_trie_changes,
    if (save_tx_outcomes != null) r'save_tx_outcomes': save_tx_outcomes,
    if (save_untracked_partial_chunks_parts != null)
      r'save_untracked_partial_chunks_parts':
          save_untracked_partial_chunks_parts,
    if (skip_sync_wait != null) r'skip_sync_wait': skip_sync_wait,
    if (state_request_server_threads != null)
      r'state_request_server_threads': state_request_server_threads,
    if (state_request_throttle_period != null)
      r'state_request_throttle_period': state_request_throttle_period,
    if (state_requests_per_throttle_period != null)
      r'state_requests_per_throttle_period': state_requests_per_throttle_period,
    if (state_sync != null) r'state_sync': state_sync?.toJson(),
    if (state_sync_external_backoff != null)
      r'state_sync_external_backoff': state_sync_external_backoff,
    if (state_sync_external_timeout != null)
      r'state_sync_external_timeout': state_sync_external_timeout,
    if (state_sync_p2p_timeout != null)
      r'state_sync_p2p_timeout': state_sync_p2p_timeout,
    if (state_sync_retry_backoff != null)
      r'state_sync_retry_backoff': state_sync_retry_backoff,
    if (sync_check_period != null) r'sync_check_period': sync_check_period,
    if (sync_height_threshold != null)
      r'sync_height_threshold': sync_height_threshold,
    if (sync_max_block_requests != null)
      r'sync_max_block_requests': sync_max_block_requests,
    if (sync_step_period != null) r'sync_step_period': sync_step_period,
    if (tracked_shards_config != null)
      r'tracked_shards_config': tracked_shards_config?.toJson(),
    if (transaction_pool_size_limit != null)
      r'transaction_pool_size_limit': transaction_pool_size_limit,
    if (transaction_pool_strict_nonce_ttl_blocks != null)
      r'transaction_pool_strict_nonce_ttl_blocks':
          transaction_pool_strict_nonce_ttl_blocks,
    if (transaction_request_handler_threads != null)
      r'transaction_request_handler_threads':
          transaction_request_handler_threads,
    if (trie_viewer_state_size_limit != null)
      r'trie_viewer_state_size_limit': trie_viewer_state_size_limit,
    if (ttl_account_id_router != null)
      r'ttl_account_id_router': ttl_account_id_router,
    if (tx_routing_height_horizon != null)
      r'tx_routing_height_horizon': tx_routing_height_horizon,
    if (version != null) r'version': version?.toJson(),
    if (view_client_threads != null)
      r'view_client_threads': view_client_threads,
  };
}

/// Union type generated from `RpcCongestionLevelRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcCongestionLevelRequest {
  const RpcCongestionLevelRequest(this.json);
  factory RpcCongestionLevelRequest.fromJson(dynamic json) =>
      RpcCongestionLevelRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcCongestionLevelResponse`.
class RpcCongestionLevelResponse {
  const RpcCongestionLevelResponse({this.congestion_level});

  factory RpcCongestionLevelResponse.fromJson(Map<String, dynamic> json) =>
      RpcCongestionLevelResponse(
        congestion_level: json[r'congestion_level'] == null
            ? null
            : (json[r'congestion_level'] as num).toDouble(),
      );

  final double? congestion_level;

  Map<String, dynamic> toJson() => {
    if (congestion_level != null) r'congestion_level': congestion_level,
  };
}

/// Union type generated from `RpcGasPriceError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcGasPriceError {
  const RpcGasPriceError(this.json);
  factory RpcGasPriceError.fromJson(dynamic json) => RpcGasPriceError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcGasPriceRequest`.
class RpcGasPriceRequest {
  const RpcGasPriceRequest({this.block_id});

  factory RpcGasPriceRequest.fromJson(Map<String, dynamic> json) =>
      RpcGasPriceRequest(
        block_id: json[r'block_id'] == null ? null : json[r'block_id'],
      );

  final dynamic? block_id;

  Map<String, dynamic> toJson() => {
    if (block_id != null) r'block_id': block_id,
  };
}

/// Generated from `RpcGasPriceResponse`.
class RpcGasPriceResponse {
  const RpcGasPriceResponse({this.gas_price});

  factory RpcGasPriceResponse.fromJson(Map<String, dynamic> json) =>
      RpcGasPriceResponse(
        gas_price: json[r'gas_price'] == null
            ? null
            : json[r'gas_price'] as NearToken,
      );

  final NearToken? gas_price;

  Map<String, dynamic> toJson() => {
    if (gas_price != null) r'gas_price': gas_price,
  };
}

/// Alias for `RpcHealthRequest`.
typedef RpcHealthRequest = dynamic;

/// Alias for `RpcHealthResponse`.
typedef RpcHealthResponse = dynamic;

/// Generated from `RpcKnownProducer`.
class RpcKnownProducer {
  const RpcKnownProducer({this.account_id, this.addr, this.peer_id});

  factory RpcKnownProducer.fromJson(Map<String, dynamic> json) =>
      RpcKnownProducer(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        addr: json[r'addr'] == null ? null : json[r'addr'] as String,
        peer_id: json[r'peer_id'] == null
            ? null
            : PeerId.fromJson(json[r'peer_id']),
      );

  final AccountId? account_id;
  final String? addr;
  final PeerId? peer_id;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (addr != null) r'addr': addr,
    if (peer_id != null) r'peer_id': peer_id?.toJson(),
  };
}

/// Generated from `RpcLightClientBlockProofRequest`.
class RpcLightClientBlockProofRequest {
  const RpcLightClientBlockProofRequest({
    this.block_hash,
    this.light_client_head,
  });

  factory RpcLightClientBlockProofRequest.fromJson(Map<String, dynamic> json) =>
      RpcLightClientBlockProofRequest(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        light_client_head: json[r'light_client_head'] == null
            ? null
            : json[r'light_client_head'] as CryptoHash,
      );

  final CryptoHash? block_hash;
  final CryptoHash? light_client_head;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (light_client_head != null) r'light_client_head': light_client_head,
  };
}

/// Generated from `RpcLightClientBlockProofResponse`.
class RpcLightClientBlockProofResponse {
  const RpcLightClientBlockProofResponse({
    this.block_header_lite,
    this.block_proof,
  });

  factory RpcLightClientBlockProofResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcLightClientBlockProofResponse(
    block_header_lite: json[r'block_header_lite'] == null
        ? null
        : LightClientBlockLiteView.fromJson(json[r'block_header_lite']),
    block_proof: json[r'block_proof'] == null
        ? null
        : (json[r'block_proof'] as List)
              .map<MerklePathItem>((e) => MerklePathItem.fromJson(e))
              .toList(),
  );

  final LightClientBlockLiteView? block_header_lite;
  final List<MerklePathItem>? block_proof;

  Map<String, dynamic> toJson() => {
    if (block_header_lite != null)
      r'block_header_lite': block_header_lite?.toJson(),
    if (block_proof != null)
      r'block_proof': block_proof?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `RpcLightClientExecutionProofRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcLightClientExecutionProofRequest {
  const RpcLightClientExecutionProofRequest(this.json);
  factory RpcLightClientExecutionProofRequest.fromJson(dynamic json) =>
      RpcLightClientExecutionProofRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcLightClientExecutionProofResponse`.
class RpcLightClientExecutionProofResponse {
  const RpcLightClientExecutionProofResponse({
    this.block_header_lite,
    this.block_proof,
    this.outcome_proof,
    this.outcome_root_proof,
  });

  factory RpcLightClientExecutionProofResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcLightClientExecutionProofResponse(
    block_header_lite: json[r'block_header_lite'] == null
        ? null
        : LightClientBlockLiteView.fromJson(json[r'block_header_lite']),
    block_proof: json[r'block_proof'] == null
        ? null
        : (json[r'block_proof'] as List)
              .map<MerklePathItem>((e) => MerklePathItem.fromJson(e))
              .toList(),
    outcome_proof: json[r'outcome_proof'] == null
        ? null
        : ExecutionOutcomeWithIdView.fromJson(json[r'outcome_proof']),
    outcome_root_proof: json[r'outcome_root_proof'] == null
        ? null
        : (json[r'outcome_root_proof'] as List)
              .map<MerklePathItem>((e) => MerklePathItem.fromJson(e))
              .toList(),
  );

  final LightClientBlockLiteView? block_header_lite;
  final List<MerklePathItem>? block_proof;
  final ExecutionOutcomeWithIdView? outcome_proof;
  final List<MerklePathItem>? outcome_root_proof;

  Map<String, dynamic> toJson() => {
    if (block_header_lite != null)
      r'block_header_lite': block_header_lite?.toJson(),
    if (block_proof != null)
      r'block_proof': block_proof?.map((e) => e.toJson()).toList(),
    if (outcome_proof != null) r'outcome_proof': outcome_proof?.toJson(),
    if (outcome_root_proof != null)
      r'outcome_root_proof': outcome_root_proof
          ?.map((e) => e.toJson())
          .toList(),
  };
}

/// Union type generated from `RpcLightClientNextBlockError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcLightClientNextBlockError {
  const RpcLightClientNextBlockError(this.json);
  factory RpcLightClientNextBlockError.fromJson(dynamic json) =>
      RpcLightClientNextBlockError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcLightClientNextBlockRequest`.
class RpcLightClientNextBlockRequest {
  const RpcLightClientNextBlockRequest({this.last_block_hash});

  factory RpcLightClientNextBlockRequest.fromJson(Map<String, dynamic> json) =>
      RpcLightClientNextBlockRequest(
        last_block_hash: json[r'last_block_hash'] == null
            ? null
            : json[r'last_block_hash'] as CryptoHash,
      );

  final CryptoHash? last_block_hash;

  Map<String, dynamic> toJson() => {
    if (last_block_hash != null) r'last_block_hash': last_block_hash,
  };
}

/// Generated from `RpcLightClientNextBlockResponse`.
class RpcLightClientNextBlockResponse {
  const RpcLightClientNextBlockResponse({
    this.approvals_after_next,
    this.inner_lite,
    this.inner_rest_hash,
    this.next_block_inner_hash,
    this.next_bps,
    this.prev_block_hash,
  });

  factory RpcLightClientNextBlockResponse.fromJson(Map<String, dynamic> json) =>
      RpcLightClientNextBlockResponse(
        approvals_after_next: json[r'approvals_after_next'] == null
            ? null
            : (json[r'approvals_after_next'] as List)
                  .map<dynamic>((e) => e)
                  .toList(),
        inner_lite: json[r'inner_lite'] == null
            ? null
            : BlockHeaderInnerLiteView.fromJson(json[r'inner_lite']),
        inner_rest_hash: json[r'inner_rest_hash'] == null
            ? null
            : json[r'inner_rest_hash'] as CryptoHash,
        next_block_inner_hash: json[r'next_block_inner_hash'] == null
            ? null
            : json[r'next_block_inner_hash'] as CryptoHash,
        next_bps: json[r'next_bps'] == null
            ? null
            : (json[r'next_bps'] as List)
                  .map<ValidatorStakeView>(
                    (e) => ValidatorStakeView.fromJson(e),
                  )
                  .toList(),
        prev_block_hash: json[r'prev_block_hash'] == null
            ? null
            : json[r'prev_block_hash'] as CryptoHash,
      );

  final List<dynamic>? approvals_after_next;
  final BlockHeaderInnerLiteView? inner_lite;
  final CryptoHash? inner_rest_hash;
  final CryptoHash? next_block_inner_hash;
  final List<ValidatorStakeView>? next_bps;
  final CryptoHash? prev_block_hash;

  Map<String, dynamic> toJson() => {
    if (approvals_after_next != null)
      r'approvals_after_next': approvals_after_next,
    if (inner_lite != null) r'inner_lite': inner_lite?.toJson(),
    if (inner_rest_hash != null) r'inner_rest_hash': inner_rest_hash,
    if (next_block_inner_hash != null)
      r'next_block_inner_hash': next_block_inner_hash,
    if (next_bps != null)
      r'next_bps': next_bps?.map((e) => e.toJson()).toList(),
    if (prev_block_hash != null) r'prev_block_hash': prev_block_hash,
  };
}

/// Union type generated from `RpcLightClientProofError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcLightClientProofError {
  const RpcLightClientProofError(this.json);
  factory RpcLightClientProofError.fromJson(dynamic json) =>
      RpcLightClientProofError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcMaintenanceWindowsError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcMaintenanceWindowsError {
  const RpcMaintenanceWindowsError(this.json);
  factory RpcMaintenanceWindowsError.fromJson(dynamic json) =>
      RpcMaintenanceWindowsError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcMaintenanceWindowsRequest`.
class RpcMaintenanceWindowsRequest {
  const RpcMaintenanceWindowsRequest({this.account_id});

  factory RpcMaintenanceWindowsRequest.fromJson(Map<String, dynamic> json) =>
      RpcMaintenanceWindowsRequest(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
      );

  final AccountId? account_id;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
  };
}

/// Union type generated from `RpcNetworkInfoError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcNetworkInfoError {
  const RpcNetworkInfoError(this.json);
  factory RpcNetworkInfoError.fromJson(dynamic json) =>
      RpcNetworkInfoError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Alias for `RpcNetworkInfoRequest`.
typedef RpcNetworkInfoRequest = dynamic;

/// Generated from `RpcNetworkInfoResponse`.
class RpcNetworkInfoResponse {
  const RpcNetworkInfoResponse({
    this.active_peers,
    this.known_producers,
    this.num_active_peers,
    this.peer_max_count,
    this.received_bytes_per_sec,
    this.sent_bytes_per_sec,
  });

  factory RpcNetworkInfoResponse.fromJson(Map<String, dynamic> json) =>
      RpcNetworkInfoResponse(
        active_peers: json[r'active_peers'] == null
            ? null
            : (json[r'active_peers'] as List)
                  .map<RpcPeerInfo>((e) => RpcPeerInfo.fromJson(e))
                  .toList(),
        known_producers: json[r'known_producers'] == null
            ? null
            : (json[r'known_producers'] as List)
                  .map<RpcKnownProducer>((e) => RpcKnownProducer.fromJson(e))
                  .toList(),
        num_active_peers: json[r'num_active_peers'] == null
            ? null
            : (json[r'num_active_peers'] as num).toInt(),
        peer_max_count: json[r'peer_max_count'] == null
            ? null
            : (json[r'peer_max_count'] as num).toInt(),
        received_bytes_per_sec: json[r'received_bytes_per_sec'] == null
            ? null
            : (json[r'received_bytes_per_sec'] as num).toInt(),
        sent_bytes_per_sec: json[r'sent_bytes_per_sec'] == null
            ? null
            : (json[r'sent_bytes_per_sec'] as num).toInt(),
      );

  final List<RpcPeerInfo>? active_peers;
  final List<RpcKnownProducer>? known_producers;
  final int? num_active_peers;
  final int? peer_max_count;
  final int? received_bytes_per_sec;
  final int? sent_bytes_per_sec;

  Map<String, dynamic> toJson() => {
    if (active_peers != null)
      r'active_peers': active_peers?.map((e) => e.toJson()).toList(),
    if (known_producers != null)
      r'known_producers': known_producers?.map((e) => e.toJson()).toList(),
    if (num_active_peers != null) r'num_active_peers': num_active_peers,
    if (peer_max_count != null) r'peer_max_count': peer_max_count,
    if (received_bytes_per_sec != null)
      r'received_bytes_per_sec': received_bytes_per_sec,
    if (sent_bytes_per_sec != null) r'sent_bytes_per_sec': sent_bytes_per_sec,
  };
}

/// Generated from `RpcPeerInfo`.
class RpcPeerInfo {
  const RpcPeerInfo({this.account_id, this.addr, this.id});

  factory RpcPeerInfo.fromJson(Map<String, dynamic> json) => RpcPeerInfo(
    account_id: json[r'account_id'] == null ? null : json[r'account_id'],
    addr: json[r'addr'] == null ? null : json[r'addr'] as String,
    id: json[r'id'] == null ? null : PeerId.fromJson(json[r'id']),
  );

  final dynamic? account_id;
  final String? addr;
  final PeerId? id;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (addr != null) r'addr': addr,
    if (id != null) r'id': id?.toJson(),
  };
}

/// Union type generated from `RpcProtocolConfigError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcProtocolConfigError {
  const RpcProtocolConfigError(this.json);
  factory RpcProtocolConfigError.fromJson(dynamic json) =>
      RpcProtocolConfigError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcProtocolConfigRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcProtocolConfigRequest {
  const RpcProtocolConfigRequest(this.json);
  factory RpcProtocolConfigRequest.fromJson(dynamic json) =>
      RpcProtocolConfigRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcProtocolConfigResponse`.
class RpcProtocolConfigResponse {
  const RpcProtocolConfigResponse({
    this.block_producer_kickout_threshold,
    this.chain_id,
    this.chunk_producer_kickout_threshold,
    this.chunk_validator_only_kickout_threshold,
    this.dynamic_resharding,
    this.epoch_length,
    this.fishermen_threshold,
    this.gas_limit,
    this.gas_price_adjustment_rate,
    this.genesis_height,
    this.genesis_time,
    this.max_gas_price,
    this.max_inflation_rate,
    this.max_kickout_stake_perc,
    this.min_gas_price,
    this.minimum_stake_divisor,
    this.minimum_stake_ratio,
    this.minimum_validators_per_shard,
    this.num_block_producer_seats,
    this.num_blocks_per_year,
    this.online_max_threshold,
    this.online_min_threshold,
    this.protocol_reward_rate,
    this.protocol_treasury_account,
    this.protocol_upgrade_stake_threshold,
    this.protocol_version,
    this.runtime_config,
    this.shard_layout,
    this.shuffle_shard_assignment_for_chunk_producers,
    this.target_validator_mandates_per_shard,
    this.transaction_validity_period,
  });

  factory RpcProtocolConfigResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcProtocolConfigResponse(
    block_producer_kickout_threshold:
        json[r'block_producer_kickout_threshold'] == null
        ? null
        : (json[r'block_producer_kickout_threshold'] as num).toInt(),
    chain_id: json[r'chain_id'] == null ? null : json[r'chain_id'] as String,
    chunk_producer_kickout_threshold:
        json[r'chunk_producer_kickout_threshold'] == null
        ? null
        : (json[r'chunk_producer_kickout_threshold'] as num).toInt(),
    chunk_validator_only_kickout_threshold:
        json[r'chunk_validator_only_kickout_threshold'] == null
        ? null
        : (json[r'chunk_validator_only_kickout_threshold'] as num).toInt(),
    dynamic_resharding: json[r'dynamic_resharding'] == null
        ? null
        : json[r'dynamic_resharding'] as bool,
    epoch_length: json[r'epoch_length'] == null
        ? null
        : (json[r'epoch_length'] as num).toInt(),
    fishermen_threshold: json[r'fishermen_threshold'] == null
        ? null
        : json[r'fishermen_threshold'] as NearToken,
    gas_limit: json[r'gas_limit'] == null
        ? null
        : json[r'gas_limit'] as NearGas,
    gas_price_adjustment_rate: json[r'gas_price_adjustment_rate'] == null
        ? null
        : (json[r'gas_price_adjustment_rate'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    genesis_height: json[r'genesis_height'] == null
        ? null
        : (json[r'genesis_height'] as num).toInt(),
    genesis_time: json[r'genesis_time'] == null
        ? null
        : json[r'genesis_time'] as String,
    max_gas_price: json[r'max_gas_price'] == null
        ? null
        : json[r'max_gas_price'] as NearToken,
    max_inflation_rate: json[r'max_inflation_rate'] == null
        ? null
        : (json[r'max_inflation_rate'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    max_kickout_stake_perc: json[r'max_kickout_stake_perc'] == null
        ? null
        : (json[r'max_kickout_stake_perc'] as num).toInt(),
    min_gas_price: json[r'min_gas_price'] == null
        ? null
        : json[r'min_gas_price'] as NearToken,
    minimum_stake_divisor: json[r'minimum_stake_divisor'] == null
        ? null
        : (json[r'minimum_stake_divisor'] as num).toInt(),
    minimum_stake_ratio: json[r'minimum_stake_ratio'] == null
        ? null
        : (json[r'minimum_stake_ratio'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    minimum_validators_per_shard: json[r'minimum_validators_per_shard'] == null
        ? null
        : (json[r'minimum_validators_per_shard'] as num).toInt(),
    num_block_producer_seats: json[r'num_block_producer_seats'] == null
        ? null
        : (json[r'num_block_producer_seats'] as num).toInt(),
    num_blocks_per_year: json[r'num_blocks_per_year'] == null
        ? null
        : (json[r'num_blocks_per_year'] as num).toInt(),
    online_max_threshold: json[r'online_max_threshold'] == null
        ? null
        : (json[r'online_max_threshold'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    online_min_threshold: json[r'online_min_threshold'] == null
        ? null
        : (json[r'online_min_threshold'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    protocol_reward_rate: json[r'protocol_reward_rate'] == null
        ? null
        : (json[r'protocol_reward_rate'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    protocol_treasury_account: json[r'protocol_treasury_account'] == null
        ? null
        : json[r'protocol_treasury_account'] as AccountId,
    protocol_upgrade_stake_threshold:
        json[r'protocol_upgrade_stake_threshold'] == null
        ? null
        : (json[r'protocol_upgrade_stake_threshold'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    protocol_version: json[r'protocol_version'] == null
        ? null
        : (json[r'protocol_version'] as num).toInt(),
    runtime_config: json[r'runtime_config'] == null
        ? null
        : RuntimeConfigView.fromJson(json[r'runtime_config']),
    shard_layout: json[r'shard_layout'] == null
        ? null
        : ShardLayout.fromJson(json[r'shard_layout']),
    shuffle_shard_assignment_for_chunk_producers:
        json[r'shuffle_shard_assignment_for_chunk_producers'] == null
        ? null
        : json[r'shuffle_shard_assignment_for_chunk_producers'] as bool,
    target_validator_mandates_per_shard:
        json[r'target_validator_mandates_per_shard'] == null
        ? null
        : (json[r'target_validator_mandates_per_shard'] as num).toInt(),
    transaction_validity_period: json[r'transaction_validity_period'] == null
        ? null
        : (json[r'transaction_validity_period'] as num).toInt(),
  );

  final int? block_producer_kickout_threshold;
  final String? chain_id;
  final int? chunk_producer_kickout_threshold;
  final int? chunk_validator_only_kickout_threshold;
  final bool? dynamic_resharding;
  final int? epoch_length;
  final NearToken? fishermen_threshold;
  final NearGas? gas_limit;
  final List<int>? gas_price_adjustment_rate;
  final int? genesis_height;
  final String? genesis_time;
  final NearToken? max_gas_price;
  final List<int>? max_inflation_rate;
  final int? max_kickout_stake_perc;
  final NearToken? min_gas_price;
  final int? minimum_stake_divisor;
  final List<int>? minimum_stake_ratio;
  final int? minimum_validators_per_shard;
  final int? num_block_producer_seats;
  final int? num_blocks_per_year;
  final List<int>? online_max_threshold;
  final List<int>? online_min_threshold;
  final List<int>? protocol_reward_rate;
  final AccountId? protocol_treasury_account;
  final List<int>? protocol_upgrade_stake_threshold;
  final int? protocol_version;
  final RuntimeConfigView? runtime_config;
  final ShardLayout? shard_layout;
  final bool? shuffle_shard_assignment_for_chunk_producers;
  final int? target_validator_mandates_per_shard;
  final int? transaction_validity_period;

  Map<String, dynamic> toJson() => {
    if (block_producer_kickout_threshold != null)
      r'block_producer_kickout_threshold': block_producer_kickout_threshold,
    if (chain_id != null) r'chain_id': chain_id,
    if (chunk_producer_kickout_threshold != null)
      r'chunk_producer_kickout_threshold': chunk_producer_kickout_threshold,
    if (chunk_validator_only_kickout_threshold != null)
      r'chunk_validator_only_kickout_threshold':
          chunk_validator_only_kickout_threshold,
    if (dynamic_resharding != null) r'dynamic_resharding': dynamic_resharding,
    if (epoch_length != null) r'epoch_length': epoch_length,
    if (fishermen_threshold != null)
      r'fishermen_threshold': fishermen_threshold,
    if (gas_limit != null) r'gas_limit': gas_limit,
    if (gas_price_adjustment_rate != null)
      r'gas_price_adjustment_rate': gas_price_adjustment_rate,
    if (genesis_height != null) r'genesis_height': genesis_height,
    if (genesis_time != null) r'genesis_time': genesis_time,
    if (max_gas_price != null) r'max_gas_price': max_gas_price,
    if (max_inflation_rate != null) r'max_inflation_rate': max_inflation_rate,
    if (max_kickout_stake_perc != null)
      r'max_kickout_stake_perc': max_kickout_stake_perc,
    if (min_gas_price != null) r'min_gas_price': min_gas_price,
    if (minimum_stake_divisor != null)
      r'minimum_stake_divisor': minimum_stake_divisor,
    if (minimum_stake_ratio != null)
      r'minimum_stake_ratio': minimum_stake_ratio,
    if (minimum_validators_per_shard != null)
      r'minimum_validators_per_shard': minimum_validators_per_shard,
    if (num_block_producer_seats != null)
      r'num_block_producer_seats': num_block_producer_seats,
    if (num_blocks_per_year != null)
      r'num_blocks_per_year': num_blocks_per_year,
    if (online_max_threshold != null)
      r'online_max_threshold': online_max_threshold,
    if (online_min_threshold != null)
      r'online_min_threshold': online_min_threshold,
    if (protocol_reward_rate != null)
      r'protocol_reward_rate': protocol_reward_rate,
    if (protocol_treasury_account != null)
      r'protocol_treasury_account': protocol_treasury_account,
    if (protocol_upgrade_stake_threshold != null)
      r'protocol_upgrade_stake_threshold': protocol_upgrade_stake_threshold,
    if (protocol_version != null) r'protocol_version': protocol_version,
    if (runtime_config != null) r'runtime_config': runtime_config?.toJson(),
    if (shard_layout != null) r'shard_layout': shard_layout?.toJson(),
    if (shuffle_shard_assignment_for_chunk_producers != null)
      r'shuffle_shard_assignment_for_chunk_producers':
          shuffle_shard_assignment_for_chunk_producers,
    if (target_validator_mandates_per_shard != null)
      r'target_validator_mandates_per_shard':
          target_validator_mandates_per_shard,
    if (transaction_validity_period != null)
      r'transaction_validity_period': transaction_validity_period,
  };
}

/// Union type generated from `RpcQueryError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcQueryError {
  const RpcQueryError(this.json);
  factory RpcQueryError.fromJson(dynamic json) => RpcQueryError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcQueryRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcQueryRequest {
  const RpcQueryRequest(this.json);
  factory RpcQueryRequest.fromJson(dynamic json) => RpcQueryRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcQueryResponse`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcQueryResponse {
  const RpcQueryResponse(this.json);
  factory RpcQueryResponse.fromJson(dynamic json) => RpcQueryResponse(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcReceiptError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcReceiptError {
  const RpcReceiptError(this.json);
  factory RpcReceiptError.fromJson(dynamic json) => RpcReceiptError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcReceiptRequest`.
class RpcReceiptRequest {
  const RpcReceiptRequest({this.receipt_id});

  factory RpcReceiptRequest.fromJson(Map<String, dynamic> json) =>
      RpcReceiptRequest(
        receipt_id: json[r'receipt_id'] == null
            ? null
            : json[r'receipt_id'] as CryptoHash,
      );

  final CryptoHash? receipt_id;

  Map<String, dynamic> toJson() => {
    if (receipt_id != null) r'receipt_id': receipt_id,
  };
}

/// Generated from `RpcReceiptResponse`.
class RpcReceiptResponse {
  const RpcReceiptResponse({
    this.predecessor_id,
    this.priority,
    this.receipt,
    this.receipt_id,
    this.receiver_id,
  });

  factory RpcReceiptResponse.fromJson(Map<String, dynamic> json) =>
      RpcReceiptResponse(
        predecessor_id: json[r'predecessor_id'] == null
            ? null
            : json[r'predecessor_id'] as AccountId,
        priority: json[r'priority'] == null
            ? null
            : (json[r'priority'] as num).toInt(),
        receipt: json[r'receipt'] == null
            ? null
            : ReceiptEnumView.fromJson(json[r'receipt']),
        receipt_id: json[r'receipt_id'] == null
            ? null
            : json[r'receipt_id'] as CryptoHash,
        receiver_id: json[r'receiver_id'] == null
            ? null
            : json[r'receiver_id'] as AccountId,
      );

  final AccountId? predecessor_id;
  final int? priority;
  final ReceiptEnumView? receipt;
  final CryptoHash? receipt_id;
  final AccountId? receiver_id;

  Map<String, dynamic> toJson() => {
    if (predecessor_id != null) r'predecessor_id': predecessor_id,
    if (priority != null) r'priority': priority,
    if (receipt != null) r'receipt': receipt?.toJson(),
    if (receipt_id != null) r'receipt_id': receipt_id,
    if (receiver_id != null) r'receiver_id': receiver_id,
  };
}

/// Union type generated from `RpcReceiptToTxError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcReceiptToTxError {
  const RpcReceiptToTxError(this.json);
  factory RpcReceiptToTxError.fromJson(dynamic json) =>
      RpcReceiptToTxError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcReceiptToTxRequest`.
class RpcReceiptToTxRequest {
  const RpcReceiptToTxRequest({
    this.block_height,
    this.receipt_id,
    this.shard_id,
    this.window,
  });

  factory RpcReceiptToTxRequest.fromJson(Map<String, dynamic> json) =>
      RpcReceiptToTxRequest(
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        receipt_id: json[r'receipt_id'] == null
            ? null
            : json[r'receipt_id'] as CryptoHash,
        shard_id: json[r'shard_id'] == null ? null : json[r'shard_id'],
        window: json[r'window'] == null
            ? null
            : (json[r'window'] as num).toInt(),
      );

  final int? block_height;
  final CryptoHash? receipt_id;
  final dynamic? shard_id;
  final int? window;

  Map<String, dynamic> toJson() => {
    if (block_height != null) r'block_height': block_height,
    if (receipt_id != null) r'receipt_id': receipt_id,
    if (shard_id != null) r'shard_id': shard_id,
    if (window != null) r'window': window,
  };
}

/// Generated from `RpcReceiptToTxResponse`.
class RpcReceiptToTxResponse {
  const RpcReceiptToTxResponse({this.sender_account_id, this.transaction_hash});

  factory RpcReceiptToTxResponse.fromJson(Map<String, dynamic> json) =>
      RpcReceiptToTxResponse(
        sender_account_id: json[r'sender_account_id'] == null
            ? null
            : json[r'sender_account_id'] as AccountId,
        transaction_hash: json[r'transaction_hash'] == null
            ? null
            : json[r'transaction_hash'] as CryptoHash,
      );

  final AccountId? sender_account_id;
  final CryptoHash? transaction_hash;

  Map<String, dynamic> toJson() => {
    if (sender_account_id != null) r'sender_account_id': sender_account_id,
    if (transaction_hash != null) r'transaction_hash': transaction_hash,
  };
}

/// Union type generated from `RpcRequestValidationErrorKind`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcRequestValidationErrorKind {
  const RpcRequestValidationErrorKind(this.json);
  factory RpcRequestValidationErrorKind.fromJson(dynamic json) =>
      RpcRequestValidationErrorKind(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcSendTransactionRequest`.
class RpcSendTransactionRequest {
  const RpcSendTransactionRequest({this.signed_tx_base64, this.wait_until});

  factory RpcSendTransactionRequest.fromJson(Map<String, dynamic> json) =>
      RpcSendTransactionRequest(
        signed_tx_base64: json[r'signed_tx_base64'] == null
            ? null
            : json[r'signed_tx_base64'] as SignedTransaction,
        wait_until: json[r'wait_until'] == null
            ? null
            : TxExecutionStatus.fromJson(json[r'wait_until']),
      );

  final SignedTransaction? signed_tx_base64;
  final TxExecutionStatus? wait_until;

  Map<String, dynamic> toJson() => {
    if (signed_tx_base64 != null) r'signed_tx_base64': signed_tx_base64,
    if (wait_until != null) r'wait_until': wait_until?.toJson(),
  };
}

/// Union type generated from `RpcSplitStorageInfoError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcSplitStorageInfoError {
  const RpcSplitStorageInfoError(this.json);
  factory RpcSplitStorageInfoError.fromJson(dynamic json) =>
      RpcSplitStorageInfoError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcSplitStorageInfoRequest`.
class RpcSplitStorageInfoRequest {
  const RpcSplitStorageInfoRequest();

  factory RpcSplitStorageInfoRequest.fromJson(Map<String, dynamic> json) =>
      RpcSplitStorageInfoRequest();

  Map<String, dynamic> toJson() => {};
}

/// Generated from `RpcSplitStorageInfoResponse`.
class RpcSplitStorageInfoResponse {
  const RpcSplitStorageInfoResponse({
    this.cold_head_height,
    this.final_head_height,
    this.head_height,
    this.hot_db_kind,
  });

  factory RpcSplitStorageInfoResponse.fromJson(Map<String, dynamic> json) =>
      RpcSplitStorageInfoResponse(
        cold_head_height: json[r'cold_head_height'] == null
            ? null
            : (json[r'cold_head_height'] as num).toInt(),
        final_head_height: json[r'final_head_height'] == null
            ? null
            : (json[r'final_head_height'] as num).toInt(),
        head_height: json[r'head_height'] == null
            ? null
            : (json[r'head_height'] as num).toInt(),
        hot_db_kind: json[r'hot_db_kind'] == null
            ? null
            : json[r'hot_db_kind'] as String,
      );

  final int? cold_head_height;
  final int? final_head_height;
  final int? head_height;
  final String? hot_db_kind;

  Map<String, dynamic> toJson() => {
    if (cold_head_height != null) r'cold_head_height': cold_head_height,
    if (final_head_height != null) r'final_head_height': final_head_height,
    if (head_height != null) r'head_height': head_height,
    if (hot_db_kind != null) r'hot_db_kind': hot_db_kind,
  };
}

/// Union type generated from `RpcStateChangesError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcStateChangesError {
  const RpcStateChangesError(this.json);
  factory RpcStateChangesError.fromJson(dynamic json) =>
      RpcStateChangesError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcStateChangesInBlockByTypeRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcStateChangesInBlockByTypeRequest {
  const RpcStateChangesInBlockByTypeRequest(this.json);
  factory RpcStateChangesInBlockByTypeRequest.fromJson(dynamic json) =>
      RpcStateChangesInBlockByTypeRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcStateChangesInBlockByTypeResponse`.
class RpcStateChangesInBlockByTypeResponse {
  const RpcStateChangesInBlockByTypeResponse({this.block_hash, this.changes});

  factory RpcStateChangesInBlockByTypeResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcStateChangesInBlockByTypeResponse(
    block_hash: json[r'block_hash'] == null
        ? null
        : json[r'block_hash'] as CryptoHash,
    changes: json[r'changes'] == null
        ? null
        : (json[r'changes'] as List)
              .map<StateChangeKindView>((e) => StateChangeKindView.fromJson(e))
              .toList(),
  );

  final CryptoHash? block_hash;
  final List<StateChangeKindView>? changes;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (changes != null) r'changes': changes?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `RpcStateChangesInBlockRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcStateChangesInBlockRequest {
  const RpcStateChangesInBlockRequest(this.json);
  factory RpcStateChangesInBlockRequest.fromJson(dynamic json) =>
      RpcStateChangesInBlockRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcStateChangesInBlockResponse`.
class RpcStateChangesInBlockResponse {
  const RpcStateChangesInBlockResponse({this.block_hash, this.changes});

  factory RpcStateChangesInBlockResponse.fromJson(Map<String, dynamic> json) =>
      RpcStateChangesInBlockResponse(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        changes: json[r'changes'] == null
            ? null
            : (json[r'changes'] as List)
                  .map<StateChangeWithCauseView>(
                    (e) => StateChangeWithCauseView.fromJson(e),
                  )
                  .toList(),
      );

  final CryptoHash? block_hash;
  final List<StateChangeWithCauseView>? changes;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (changes != null) r'changes': changes?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `RpcStatusError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcStatusError {
  const RpcStatusError(this.json);
  factory RpcStatusError.fromJson(dynamic json) => RpcStatusError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Alias for `RpcStatusRequest`.
typedef RpcStatusRequest = dynamic;

/// Generated from `RpcStatusResponse`.
class RpcStatusResponse {
  const RpcStatusResponse({
    this.chain_id,
    this.detailed_debug_status,
    this.genesis_hash,
    this.latest_protocol_version,
    this.node_key,
    this.node_public_key,
    this.protocol_version,
    this.rpc_addr,
    this.sync_info,
    this.uptime_sec,
    this.validator_account_id,
    this.validator_public_key,
    this.validators,
    this.version,
  });

  factory RpcStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcStatusResponse(
    chain_id: json[r'chain_id'] == null ? null : json[r'chain_id'] as String,
    detailed_debug_status: json[r'detailed_debug_status'] == null
        ? null
        : json[r'detailed_debug_status'],
    genesis_hash: json[r'genesis_hash'] == null
        ? null
        : json[r'genesis_hash'] as CryptoHash,
    latest_protocol_version: json[r'latest_protocol_version'] == null
        ? null
        : (json[r'latest_protocol_version'] as num).toInt(),
    node_key: json[r'node_key'] == null ? null : json[r'node_key'],
    node_public_key: json[r'node_public_key'] == null
        ? null
        : json[r'node_public_key'] as PublicKey,
    protocol_version: json[r'protocol_version'] == null
        ? null
        : (json[r'protocol_version'] as num).toInt(),
    rpc_addr: json[r'rpc_addr'] == null ? null : json[r'rpc_addr'] as String,
    sync_info: json[r'sync_info'] == null
        ? null
        : StatusSyncInfo.fromJson(json[r'sync_info']),
    uptime_sec: json[r'uptime_sec'] == null
        ? null
        : (json[r'uptime_sec'] as num).toInt(),
    validator_account_id: json[r'validator_account_id'] == null
        ? null
        : json[r'validator_account_id'],
    validator_public_key: json[r'validator_public_key'] == null
        ? null
        : json[r'validator_public_key'],
    validators: json[r'validators'] == null
        ? null
        : (json[r'validators'] as List)
              .map<ValidatorInfo>((e) => ValidatorInfo.fromJson(e))
              .toList(),
    version: json[r'version'] == null
        ? null
        : Version.fromJson(json[r'version']),
  );

  final String? chain_id;
  final dynamic? detailed_debug_status;
  final CryptoHash? genesis_hash;
  final int? latest_protocol_version;
  final dynamic? node_key;
  final PublicKey? node_public_key;
  final int? protocol_version;
  final String? rpc_addr;
  final StatusSyncInfo? sync_info;
  final int? uptime_sec;
  final dynamic? validator_account_id;
  final dynamic? validator_public_key;
  final List<ValidatorInfo>? validators;
  final Version? version;

  Map<String, dynamic> toJson() => {
    if (chain_id != null) r'chain_id': chain_id,
    if (detailed_debug_status != null)
      r'detailed_debug_status': detailed_debug_status,
    if (genesis_hash != null) r'genesis_hash': genesis_hash,
    if (latest_protocol_version != null)
      r'latest_protocol_version': latest_protocol_version,
    if (node_key != null) r'node_key': node_key,
    if (node_public_key != null) r'node_public_key': node_public_key,
    if (protocol_version != null) r'protocol_version': protocol_version,
    if (rpc_addr != null) r'rpc_addr': rpc_addr,
    if (sync_info != null) r'sync_info': sync_info?.toJson(),
    if (uptime_sec != null) r'uptime_sec': uptime_sec,
    if (validator_account_id != null)
      r'validator_account_id': validator_account_id,
    if (validator_public_key != null)
      r'validator_public_key': validator_public_key,
    if (validators != null)
      r'validators': validators?.map((e) => e.toJson()).toList(),
    if (version != null) r'version': version?.toJson(),
  };
}

/// Union type generated from `RpcTransactionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcTransactionError {
  const RpcTransactionError(this.json);
  factory RpcTransactionError.fromJson(dynamic json) =>
      RpcTransactionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcTransactionResponse`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcTransactionResponse {
  const RpcTransactionResponse(this.json);
  factory RpcTransactionResponse.fromJson(dynamic json) =>
      RpcTransactionResponse(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcTransactionStatusRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcTransactionStatusRequest {
  const RpcTransactionStatusRequest(this.json);
  factory RpcTransactionStatusRequest.fromJson(dynamic json) =>
      RpcTransactionStatusRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcValidatorError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcValidatorError {
  const RpcValidatorError(this.json);
  factory RpcValidatorError.fromJson(dynamic json) => RpcValidatorError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcValidatorRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcValidatorRequest {
  const RpcValidatorRequest(this.json);
  factory RpcValidatorRequest.fromJson(dynamic json) =>
      RpcValidatorRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcValidatorResponse`.
class RpcValidatorResponse {
  const RpcValidatorResponse({
    this.current_fishermen,
    this.current_proposals,
    this.current_validators,
    this.epoch_height,
    this.epoch_start_height,
    this.next_fishermen,
    this.next_validators,
    this.prev_epoch_kickout,
    this.validator_reward_paid_prev_epoch,
  });

  factory RpcValidatorResponse.fromJson(
    Map<String, dynamic> json,
  ) => RpcValidatorResponse(
    current_fishermen: json[r'current_fishermen'] == null
        ? null
        : (json[r'current_fishermen'] as List)
              .map<ValidatorStakeView>((e) => ValidatorStakeView.fromJson(e))
              .toList(),
    current_proposals: json[r'current_proposals'] == null
        ? null
        : (json[r'current_proposals'] as List)
              .map<ValidatorStakeView>((e) => ValidatorStakeView.fromJson(e))
              .toList(),
    current_validators: json[r'current_validators'] == null
        ? null
        : (json[r'current_validators'] as List)
              .map<CurrentEpochValidatorInfo>(
                (e) => CurrentEpochValidatorInfo.fromJson(e),
              )
              .toList(),
    epoch_height: json[r'epoch_height'] == null
        ? null
        : (json[r'epoch_height'] as num).toInt(),
    epoch_start_height: json[r'epoch_start_height'] == null
        ? null
        : (json[r'epoch_start_height'] as num).toInt(),
    next_fishermen: json[r'next_fishermen'] == null
        ? null
        : (json[r'next_fishermen'] as List)
              .map<ValidatorStakeView>((e) => ValidatorStakeView.fromJson(e))
              .toList(),
    next_validators: json[r'next_validators'] == null
        ? null
        : (json[r'next_validators'] as List)
              .map<NextEpochValidatorInfo>(
                (e) => NextEpochValidatorInfo.fromJson(e),
              )
              .toList(),
    prev_epoch_kickout: json[r'prev_epoch_kickout'] == null
        ? null
        : (json[r'prev_epoch_kickout'] as List)
              .map<ValidatorKickoutView>(
                (e) => ValidatorKickoutView.fromJson(e),
              )
              .toList(),
    validator_reward_paid_prev_epoch:
        json[r'validator_reward_paid_prev_epoch'] == null
        ? null
        : (json[r'validator_reward_paid_prev_epoch'] as Map).map(
            (k, v) => MapEntry(k as String, v as NearToken),
          ),
  );

  final List<ValidatorStakeView>? current_fishermen;
  final List<ValidatorStakeView>? current_proposals;
  final List<CurrentEpochValidatorInfo>? current_validators;
  final int? epoch_height;
  final int? epoch_start_height;
  final List<ValidatorStakeView>? next_fishermen;
  final List<NextEpochValidatorInfo>? next_validators;
  final List<ValidatorKickoutView>? prev_epoch_kickout;
  final Map<String, NearToken>? validator_reward_paid_prev_epoch;

  Map<String, dynamic> toJson() => {
    if (current_fishermen != null)
      r'current_fishermen': current_fishermen?.map((e) => e.toJson()).toList(),
    if (current_proposals != null)
      r'current_proposals': current_proposals?.map((e) => e.toJson()).toList(),
    if (current_validators != null)
      r'current_validators': current_validators
          ?.map((e) => e.toJson())
          .toList(),
    if (epoch_height != null) r'epoch_height': epoch_height,
    if (epoch_start_height != null) r'epoch_start_height': epoch_start_height,
    if (next_fishermen != null)
      r'next_fishermen': next_fishermen?.map((e) => e.toJson()).toList(),
    if (next_validators != null)
      r'next_validators': next_validators?.map((e) => e.toJson()).toList(),
    if (prev_epoch_kickout != null)
      r'prev_epoch_kickout': prev_epoch_kickout
          ?.map((e) => e.toJson())
          .toList(),
    if (validator_reward_paid_prev_epoch != null)
      r'validator_reward_paid_prev_epoch': validator_reward_paid_prev_epoch
          ?.map((k, v) => MapEntry(k, v)),
  };
}

/// Generated from `RpcValidatorsOrderedRequest`.
class RpcValidatorsOrderedRequest {
  const RpcValidatorsOrderedRequest({this.block_id});

  factory RpcValidatorsOrderedRequest.fromJson(Map<String, dynamic> json) =>
      RpcValidatorsOrderedRequest(
        block_id: json[r'block_id'] == null ? null : json[r'block_id'],
      );

  final dynamic? block_id;

  Map<String, dynamic> toJson() => {
    if (block_id != null) r'block_id': block_id,
  };
}

/// Union type generated from `RpcViewAccessKeyError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewAccessKeyError {
  const RpcViewAccessKeyError(this.json);
  factory RpcViewAccessKeyError.fromJson(dynamic json) =>
      RpcViewAccessKeyError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcViewAccessKeyListError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewAccessKeyListError {
  const RpcViewAccessKeyListError(this.json);
  factory RpcViewAccessKeyListError.fromJson(dynamic json) =>
      RpcViewAccessKeyListError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcViewAccessKeyListRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewAccessKeyListRequest {
  const RpcViewAccessKeyListRequest(this.json);
  factory RpcViewAccessKeyListRequest.fromJson(dynamic json) =>
      RpcViewAccessKeyListRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcViewAccessKeyListResponse`.
class RpcViewAccessKeyListResponse {
  const RpcViewAccessKeyListResponse({
    this.block_hash,
    this.block_height,
    this.keys,
  });

  factory RpcViewAccessKeyListResponse.fromJson(Map<String, dynamic> json) =>
      RpcViewAccessKeyListResponse(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        keys: json[r'keys'] == null
            ? null
            : (json[r'keys'] as List)
                  .map<AccessKeyInfoView>((e) => AccessKeyInfoView.fromJson(e))
                  .toList(),
      );

  final CryptoHash? block_hash;
  final int? block_height;
  final List<AccessKeyInfoView>? keys;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (block_height != null) r'block_height': block_height,
    if (keys != null) r'keys': keys?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `RpcViewAccessKeyRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewAccessKeyRequest {
  const RpcViewAccessKeyRequest(this.json);
  factory RpcViewAccessKeyRequest.fromJson(dynamic json) =>
      RpcViewAccessKeyRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcViewAccessKeyResponse`.
class RpcViewAccessKeyResponse {
  const RpcViewAccessKeyResponse({
    this.block_hash,
    this.block_height,
    this.nonce,
    this.permission,
  });

  factory RpcViewAccessKeyResponse.fromJson(Map<String, dynamic> json) =>
      RpcViewAccessKeyResponse(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        nonce: json[r'nonce'] == null ? null : (json[r'nonce'] as num).toInt(),
        permission: json[r'permission'] == null
            ? null
            : AccessKeyPermissionView.fromJson(json[r'permission']),
      );

  final CryptoHash? block_hash;
  final int? block_height;
  final int? nonce;
  final AccessKeyPermissionView? permission;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (block_height != null) r'block_height': block_height,
    if (nonce != null) r'nonce': nonce,
    if (permission != null) r'permission': permission?.toJson(),
  };
}

/// Union type generated from `RpcViewAccountError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewAccountError {
  const RpcViewAccountError(this.json);
  factory RpcViewAccountError.fromJson(dynamic json) =>
      RpcViewAccountError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcViewAccountRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewAccountRequest {
  const RpcViewAccountRequest(this.json);
  factory RpcViewAccountRequest.fromJson(dynamic json) =>
      RpcViewAccountRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcViewAccountResponse`.
class RpcViewAccountResponse {
  const RpcViewAccountResponse({
    this.amount,
    this.block_hash,
    this.block_height,
    this.code_hash,
    this.global_contract_account_id,
    this.global_contract_hash,
    this.locked,
    this.storage_paid_at,
    this.storage_usage,
  });

  factory RpcViewAccountResponse.fromJson(Map<String, dynamic> json) =>
      RpcViewAccountResponse(
        amount: json[r'amount'] == null ? null : json[r'amount'] as NearToken,
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        code_hash: json[r'code_hash'] == null
            ? null
            : json[r'code_hash'] as CryptoHash,
        global_contract_account_id: json[r'global_contract_account_id'] == null
            ? null
            : json[r'global_contract_account_id'],
        global_contract_hash: json[r'global_contract_hash'] == null
            ? null
            : json[r'global_contract_hash'],
        locked: json[r'locked'] == null ? null : json[r'locked'] as NearToken,
        storage_paid_at: json[r'storage_paid_at'] == null
            ? null
            : (json[r'storage_paid_at'] as num).toInt(),
        storage_usage: json[r'storage_usage'] == null
            ? null
            : (json[r'storage_usage'] as num).toInt(),
      );

  final NearToken? amount;
  final CryptoHash? block_hash;
  final int? block_height;
  final CryptoHash? code_hash;
  final dynamic? global_contract_account_id;
  final dynamic? global_contract_hash;
  final NearToken? locked;
  final int? storage_paid_at;
  final int? storage_usage;

  Map<String, dynamic> toJson() => {
    if (amount != null) r'amount': amount,
    if (block_hash != null) r'block_hash': block_hash,
    if (block_height != null) r'block_height': block_height,
    if (code_hash != null) r'code_hash': code_hash,
    if (global_contract_account_id != null)
      r'global_contract_account_id': global_contract_account_id,
    if (global_contract_hash != null)
      r'global_contract_hash': global_contract_hash,
    if (locked != null) r'locked': locked,
    if (storage_paid_at != null) r'storage_paid_at': storage_paid_at,
    if (storage_usage != null) r'storage_usage': storage_usage,
  };
}

/// Union type generated from `RpcViewCodeError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewCodeError {
  const RpcViewCodeError(this.json);
  factory RpcViewCodeError.fromJson(dynamic json) => RpcViewCodeError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcViewCodeRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewCodeRequest {
  const RpcViewCodeRequest(this.json);
  factory RpcViewCodeRequest.fromJson(dynamic json) => RpcViewCodeRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcViewCodeResponse`.
class RpcViewCodeResponse {
  const RpcViewCodeResponse({
    this.block_hash,
    this.block_height,
    this.code_base64,
    this.hash,
  });

  factory RpcViewCodeResponse.fromJson(Map<String, dynamic> json) =>
      RpcViewCodeResponse(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        code_base64: json[r'code_base64'] == null
            ? null
            : json[r'code_base64'] as String,
        hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
      );

  final CryptoHash? block_hash;
  final int? block_height;
  final String? code_base64;
  final CryptoHash? hash;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (block_height != null) r'block_height': block_height,
    if (code_base64 != null) r'code_base64': code_base64,
    if (hash != null) r'hash': hash,
  };
}

/// Union type generated from `RpcViewStateError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewStateError {
  const RpcViewStateError(this.json);
  factory RpcViewStateError.fromJson(dynamic json) => RpcViewStateError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `RpcViewStateRequest`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class RpcViewStateRequest {
  const RpcViewStateRequest(this.json);
  factory RpcViewStateRequest.fromJson(dynamic json) =>
      RpcViewStateRequest(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `RpcViewStateResponse`.
class RpcViewStateResponse {
  const RpcViewStateResponse({
    this.block_hash,
    this.block_height,
    this.last_key,
    this.proof,
    this.values,
  });

  factory RpcViewStateResponse.fromJson(Map<String, dynamic> json) =>
      RpcViewStateResponse(
        block_hash: json[r'block_hash'] == null
            ? null
            : json[r'block_hash'] as CryptoHash,
        block_height: json[r'block_height'] == null
            ? null
            : (json[r'block_height'] as num).toInt(),
        last_key: json[r'last_key'] == null ? null : json[r'last_key'],
        proof: json[r'proof'] == null
            ? null
            : (json[r'proof'] as List).map<String>((e) => e as String).toList(),
        values: json[r'values'] == null
            ? null
            : (json[r'values'] as List)
                  .map<StateItem>((e) => StateItem.fromJson(e))
                  .toList(),
      );

  final CryptoHash? block_hash;
  final int? block_height;
  final dynamic? last_key;
  final List<String>? proof;
  final List<StateItem>? values;

  Map<String, dynamic> toJson() => {
    if (block_hash != null) r'block_hash': block_hash,
    if (block_height != null) r'block_height': block_height,
    if (last_key != null) r'last_key': last_key,
    if (proof != null) r'proof': proof,
    if (values != null) r'values': values?.map((e) => e.toJson()).toList(),
  };
}

/// Generated from `RuntimeConfigView`.
class RuntimeConfigView {
  const RuntimeConfigView({
    this.account_creation_charge,
    this.account_creation_config,
    this.congestion_control_config,
    this.min_gas_purchase_price,
    this.storage_amount_per_byte,
    this.transaction_costs,
    this.wasm_config,
    this.witness_config,
  });

  factory RuntimeConfigView.fromJson(Map<String, dynamic> json) =>
      RuntimeConfigView(
        account_creation_charge: json[r'account_creation_charge'] == null
            ? null
            : json[r'account_creation_charge'] as NearToken,
        account_creation_config: json[r'account_creation_config'] == null
            ? null
            : AccountCreationConfigView.fromJson(
                json[r'account_creation_config'],
              ),
        congestion_control_config: json[r'congestion_control_config'] == null
            ? null
            : CongestionControlConfigView.fromJson(
                json[r'congestion_control_config'],
              ),
        min_gas_purchase_price: json[r'min_gas_purchase_price'] == null
            ? null
            : json[r'min_gas_purchase_price'] as NearToken,
        storage_amount_per_byte: json[r'storage_amount_per_byte'] == null
            ? null
            : json[r'storage_amount_per_byte'] as NearToken,
        transaction_costs: json[r'transaction_costs'] == null
            ? null
            : RuntimeFeesConfigView.fromJson(json[r'transaction_costs']),
        wasm_config: json[r'wasm_config'] == null
            ? null
            : VMConfigView.fromJson(json[r'wasm_config']),
        witness_config: json[r'witness_config'] == null
            ? null
            : WitnessConfigView.fromJson(json[r'witness_config']),
      );

  final NearToken? account_creation_charge;
  final AccountCreationConfigView? account_creation_config;
  final CongestionControlConfigView? congestion_control_config;
  final NearToken? min_gas_purchase_price;
  final NearToken? storage_amount_per_byte;
  final RuntimeFeesConfigView? transaction_costs;
  final VMConfigView? wasm_config;
  final WitnessConfigView? witness_config;

  Map<String, dynamic> toJson() => {
    if (account_creation_charge != null)
      r'account_creation_charge': account_creation_charge,
    if (account_creation_config != null)
      r'account_creation_config': account_creation_config?.toJson(),
    if (congestion_control_config != null)
      r'congestion_control_config': congestion_control_config?.toJson(),
    if (min_gas_purchase_price != null)
      r'min_gas_purchase_price': min_gas_purchase_price,
    if (storage_amount_per_byte != null)
      r'storage_amount_per_byte': storage_amount_per_byte,
    if (transaction_costs != null)
      r'transaction_costs': transaction_costs?.toJson(),
    if (wasm_config != null) r'wasm_config': wasm_config?.toJson(),
    if (witness_config != null) r'witness_config': witness_config?.toJson(),
  };
}

/// Generated from `RuntimeFeesConfigView`.
class RuntimeFeesConfigView {
  const RuntimeFeesConfigView({
    this.action_creation_config,
    this.action_receipt_creation_config,
    this.burnt_gas_reward,
    this.data_receipt_creation_config,
    this.ml_dsa_65_verification_cost,
    this.pessimistic_gas_price_inflation_ratio,
    this.storage_usage_config,
  });

  factory RuntimeFeesConfigView.fromJson(
    Map<String, dynamic> json,
  ) => RuntimeFeesConfigView(
    action_creation_config: json[r'action_creation_config'] == null
        ? null
        : ActionCreationConfigView.fromJson(json[r'action_creation_config']),
    action_receipt_creation_config:
        json[r'action_receipt_creation_config'] == null
        ? null
        : Fee.fromJson(json[r'action_receipt_creation_config']),
    burnt_gas_reward: json[r'burnt_gas_reward'] == null
        ? null
        : (json[r'burnt_gas_reward'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    data_receipt_creation_config: json[r'data_receipt_creation_config'] == null
        ? null
        : DataReceiptCreationConfigView.fromJson(
            json[r'data_receipt_creation_config'],
          ),
    ml_dsa_65_verification_cost: json[r'ml_dsa_65_verification_cost'] == null
        ? null
        : json[r'ml_dsa_65_verification_cost'] as NearGas,
    pessimistic_gas_price_inflation_ratio:
        json[r'pessimistic_gas_price_inflation_ratio'] == null
        ? null
        : (json[r'pessimistic_gas_price_inflation_ratio'] as List)
              .map<int>((e) => (e as num).toInt())
              .toList(),
    storage_usage_config: json[r'storage_usage_config'] == null
        ? null
        : StorageUsageConfigView.fromJson(json[r'storage_usage_config']),
  );

  final ActionCreationConfigView? action_creation_config;
  final Fee? action_receipt_creation_config;
  final List<int>? burnt_gas_reward;
  final DataReceiptCreationConfigView? data_receipt_creation_config;
  final NearGas? ml_dsa_65_verification_cost;
  final List<int>? pessimistic_gas_price_inflation_ratio;
  final StorageUsageConfigView? storage_usage_config;

  Map<String, dynamic> toJson() => {
    if (action_creation_config != null)
      r'action_creation_config': action_creation_config?.toJson(),
    if (action_receipt_creation_config != null)
      r'action_receipt_creation_config': action_receipt_creation_config
          ?.toJson(),
    if (burnt_gas_reward != null) r'burnt_gas_reward': burnt_gas_reward,
    if (data_receipt_creation_config != null)
      r'data_receipt_creation_config': data_receipt_creation_config?.toJson(),
    if (ml_dsa_65_verification_cost != null)
      r'ml_dsa_65_verification_cost': ml_dsa_65_verification_cost,
    if (pessimistic_gas_price_inflation_ratio != null)
      r'pessimistic_gas_price_inflation_ratio':
          pessimistic_gas_price_inflation_ratio,
    if (storage_usage_config != null)
      r'storage_usage_config': storage_usage_config?.toJson(),
  };
}

/// Alias for `ShardId`.
typedef ShardId = int;

/// Union type generated from `ShardLayout`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ShardLayout {
  const ShardLayout(this.json);
  factory ShardLayout.fromJson(dynamic json) => ShardLayout(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ShardLayoutV0`.
class ShardLayoutV0 {
  const ShardLayoutV0({this.num_shards, this.version});

  factory ShardLayoutV0.fromJson(Map<String, dynamic> json) => ShardLayoutV0(
    num_shards: json[r'num_shards'] == null
        ? null
        : (json[r'num_shards'] as num).toInt(),
    version: json[r'version'] == null
        ? null
        : (json[r'version'] as num).toInt(),
  );

  final int? num_shards;
  final int? version;

  Map<String, dynamic> toJson() => {
    if (num_shards != null) r'num_shards': num_shards,
    if (version != null) r'version': version,
  };
}

/// Generated from `ShardLayoutV1`.
class ShardLayoutV1 {
  const ShardLayoutV1({
    this.boundary_accounts,
    this.shards_split_map,
    this.to_parent_shard_map,
    this.version,
  });

  factory ShardLayoutV1.fromJson(Map<String, dynamic> json) => ShardLayoutV1(
    boundary_accounts: json[r'boundary_accounts'] == null
        ? null
        : (json[r'boundary_accounts'] as List)
              .map<AccountId>((e) => e as AccountId)
              .toList(),
    shards_split_map: json[r'shards_split_map'] == null
        ? null
        : (json[r'shards_split_map'] as List)
              .map<List<ShardId>>(
                (e) => (e as List).map<ShardId>((e) => e as ShardId).toList(),
              )
              .toList(),
    to_parent_shard_map: json[r'to_parent_shard_map'] == null
        ? null
        : (json[r'to_parent_shard_map'] as List)
              .map<ShardId>((e) => e as ShardId)
              .toList(),
    version: json[r'version'] == null
        ? null
        : (json[r'version'] as num).toInt(),
  );

  final List<AccountId>? boundary_accounts;
  final List<List<ShardId>>? shards_split_map;
  final List<ShardId>? to_parent_shard_map;
  final int? version;

  Map<String, dynamic> toJson() => {
    if (boundary_accounts != null) r'boundary_accounts': boundary_accounts,
    if (shards_split_map != null) r'shards_split_map': shards_split_map,
    if (to_parent_shard_map != null)
      r'to_parent_shard_map': to_parent_shard_map,
    if (version != null) r'version': version,
  };
}

/// Generated from `ShardLayoutV2`.
class ShardLayoutV2 {
  const ShardLayoutV2({
    this.boundary_accounts,
    this.id_to_index_map,
    this.index_to_id_map,
    this.shard_ids,
    this.shards_parent_map,
    this.shards_split_map,
    this.version,
  });

  factory ShardLayoutV2.fromJson(Map<String, dynamic> json) => ShardLayoutV2(
    boundary_accounts: json[r'boundary_accounts'] == null
        ? null
        : (json[r'boundary_accounts'] as List)
              .map<AccountId>((e) => e as AccountId)
              .toList(),
    id_to_index_map: json[r'id_to_index_map'] == null
        ? null
        : (json[r'id_to_index_map'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
    index_to_id_map: json[r'index_to_id_map'] == null
        ? null
        : (json[r'index_to_id_map'] as Map).map(
            (k, v) => MapEntry(k as String, v as ShardId),
          ),
    shard_ids: json[r'shard_ids'] == null
        ? null
        : (json[r'shard_ids'] as List)
              .map<ShardId>((e) => e as ShardId)
              .toList(),
    shards_parent_map: json[r'shards_parent_map'] == null
        ? null
        : (json[r'shards_parent_map'] as Map).map(
            (k, v) => MapEntry(k as String, v as ShardId),
          ),
    shards_split_map: json[r'shards_split_map'] == null
        ? null
        : (json[r'shards_split_map'] as Map).map(
            (k, v) => MapEntry(
              k as String,
              (v as List).map<ShardId>((e) => e as ShardId).toList(),
            ),
          ),
    version: json[r'version'] == null
        ? null
        : (json[r'version'] as num).toInt(),
  );

  final List<AccountId>? boundary_accounts;
  final Map<String, int>? id_to_index_map;
  final Map<String, ShardId>? index_to_id_map;
  final List<ShardId>? shard_ids;
  final Map<String, ShardId>? shards_parent_map;
  final Map<String, List<ShardId>>? shards_split_map;
  final int? version;

  Map<String, dynamic> toJson() => {
    if (boundary_accounts != null) r'boundary_accounts': boundary_accounts,
    if (id_to_index_map != null) r'id_to_index_map': id_to_index_map,
    if (index_to_id_map != null)
      r'index_to_id_map': index_to_id_map?.map((k, v) => MapEntry(k, v)),
    if (shard_ids != null) r'shard_ids': shard_ids,
    if (shards_parent_map != null)
      r'shards_parent_map': shards_parent_map?.map((k, v) => MapEntry(k, v)),
    if (shards_split_map != null) r'shards_split_map': shards_split_map,
    if (version != null) r'version': version,
  };
}

/// Generated from `ShardLayoutV3`.
class ShardLayoutV3 {
  const ShardLayoutV3({
    this.boundary_accounts,
    this.id_to_index_map,
    this.last_split,
    this.shard_ids,
    this.shards_split_map,
  });

  factory ShardLayoutV3.fromJson(Map<String, dynamic> json) => ShardLayoutV3(
    boundary_accounts: json[r'boundary_accounts'] == null
        ? null
        : (json[r'boundary_accounts'] as List)
              .map<AccountId>((e) => e as AccountId)
              .toList(),
    id_to_index_map: json[r'id_to_index_map'] == null
        ? null
        : (json[r'id_to_index_map'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
    last_split: json[r'last_split'] == null
        ? null
        : json[r'last_split'] as ShardId,
    shard_ids: json[r'shard_ids'] == null
        ? null
        : (json[r'shard_ids'] as List)
              .map<ShardId>((e) => e as ShardId)
              .toList(),
    shards_split_map: json[r'shards_split_map'] == null
        ? null
        : (json[r'shards_split_map'] as Map).map(
            (k, v) => MapEntry(
              k as String,
              (v as List).map<ShardId>((e) => e as ShardId).toList(),
            ),
          ),
  );

  final List<AccountId>? boundary_accounts;
  final Map<String, int>? id_to_index_map;
  final ShardId? last_split;
  final List<ShardId>? shard_ids;
  final Map<String, List<ShardId>>? shards_split_map;

  Map<String, dynamic> toJson() => {
    if (boundary_accounts != null) r'boundary_accounts': boundary_accounts,
    if (id_to_index_map != null) r'id_to_index_map': id_to_index_map,
    if (last_split != null) r'last_split': last_split,
    if (shard_ids != null) r'shard_ids': shard_ids,
    if (shards_split_map != null) r'shards_split_map': shards_split_map,
  };
}

/// Generated from `ShardUId`.
class ShardUId {
  const ShardUId({this.shard_id, this.version});

  factory ShardUId.fromJson(Map<String, dynamic> json) => ShardUId(
    shard_id: json[r'shard_id'] == null
        ? null
        : (json[r'shard_id'] as num).toInt(),
    version: json[r'version'] == null
        ? null
        : (json[r'version'] as num).toInt(),
  );

  final int? shard_id;
  final int? version;

  Map<String, dynamic> toJson() => {
    if (shard_id != null) r'shard_id': shard_id,
    if (version != null) r'version': version,
  };
}

/// Alias for `Signature`.
typedef Signature = String;

/// Generated from `SignedDelegateAction`.
class SignedDelegateAction {
  const SignedDelegateAction({this.delegate_action, this.signature});

  factory SignedDelegateAction.fromJson(Map<String, dynamic> json) =>
      SignedDelegateAction(
        delegate_action: json[r'delegate_action'] == null
            ? null
            : DelegateAction.fromJson(json[r'delegate_action']),
        signature: json[r'signature'] == null
            ? null
            : json[r'signature'] as Signature,
      );

  final DelegateAction? delegate_action;
  final Signature? signature;

  Map<String, dynamic> toJson() => {
    if (delegate_action != null) r'delegate_action': delegate_action?.toJson(),
    if (signature != null) r'signature': signature,
  };
}

/// Alias for `SignedTransaction`.
typedef SignedTransaction = String;

/// Generated from `SignedTransactionView`.
class SignedTransactionView {
  const SignedTransactionView({
    this.actions,
    this.hash,
    this.nonce,
    this.nonce_index,
    this.nonce_mode,
    this.priority_fee,
    this.public_key,
    this.receiver_id,
    this.signature,
    this.signer_id,
  });

  factory SignedTransactionView.fromJson(Map<String, dynamic> json) =>
      SignedTransactionView(
        actions: json[r'actions'] == null
            ? null
            : (json[r'actions'] as List)
                  .map<ActionView>((e) => ActionView.fromJson(e))
                  .toList(),
        hash: json[r'hash'] == null ? null : json[r'hash'] as CryptoHash,
        nonce: json[r'nonce'] == null ? null : (json[r'nonce'] as num).toInt(),
        nonce_index: json[r'nonce_index'] == null
            ? null
            : (json[r'nonce_index'] as num).toInt(),
        nonce_mode: json[r'nonce_mode'] == null ? null : json[r'nonce_mode'],
        priority_fee: json[r'priority_fee'] == null
            ? null
            : (json[r'priority_fee'] as num).toInt(),
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
        receiver_id: json[r'receiver_id'] == null
            ? null
            : json[r'receiver_id'] as AccountId,
        signature: json[r'signature'] == null
            ? null
            : json[r'signature'] as Signature,
        signer_id: json[r'signer_id'] == null
            ? null
            : json[r'signer_id'] as AccountId,
      );

  final List<ActionView>? actions;
  final CryptoHash? hash;
  final int? nonce;
  final int? nonce_index;
  final dynamic? nonce_mode;
  final int? priority_fee;
  final PublicKey? public_key;
  final AccountId? receiver_id;
  final Signature? signature;
  final AccountId? signer_id;

  Map<String, dynamic> toJson() => {
    if (actions != null) r'actions': actions?.map((e) => e.toJson()).toList(),
    if (hash != null) r'hash': hash,
    if (nonce != null) r'nonce': nonce,
    if (nonce_index != null) r'nonce_index': nonce_index,
    if (nonce_mode != null) r'nonce_mode': nonce_mode,
    if (priority_fee != null) r'priority_fee': priority_fee,
    if (public_key != null) r'public_key': public_key,
    if (receiver_id != null) r'receiver_id': receiver_id,
    if (signature != null) r'signature': signature,
    if (signer_id != null) r'signer_id': signer_id,
  };
}

/// Generated from `SlashedValidator`.
class SlashedValidator {
  const SlashedValidator({this.account_id, this.is_double_sign});

  factory SlashedValidator.fromJson(Map<String, dynamic> json) =>
      SlashedValidator(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        is_double_sign: json[r'is_double_sign'] == null
            ? null
            : json[r'is_double_sign'] as bool,
      );

  final AccountId? account_id;
  final bool? is_double_sign;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (is_double_sign != null) r'is_double_sign': is_double_sign,
  };
}

/// Generated from `SpiceChunkEndorsementStats`.
class SpiceChunkEndorsementStats {
  const SpiceChunkEndorsementStats({this.expected, this.produced});

  factory SpiceChunkEndorsementStats.fromJson(Map<String, dynamic> json) =>
      SpiceChunkEndorsementStats(
        expected: json[r'expected'] == null
            ? null
            : (json[r'expected'] as num).toInt(),
        produced: json[r'produced'] == null
            ? null
            : (json[r'produced'] as num).toInt(),
      );

  final int? expected;
  final int? produced;

  Map<String, dynamic> toJson() => {
    if (expected != null) r'expected': expected,
    if (produced != null) r'produced': produced,
  };
}

/// Generated from `StakeAction`.
class StakeAction {
  const StakeAction({this.public_key, this.stake});

  factory StakeAction.fromJson(Map<String, dynamic> json) => StakeAction(
    public_key: json[r'public_key'] == null
        ? null
        : json[r'public_key'] as PublicKey,
    stake: json[r'stake'] == null ? null : json[r'stake'] as NearToken,
  );

  final PublicKey? public_key;
  final NearToken? stake;

  Map<String, dynamic> toJson() => {
    if (public_key != null) r'public_key': public_key,
    if (stake != null) r'stake': stake,
  };
}

/// Union type generated from `StateChangeCauseView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class StateChangeCauseView {
  const StateChangeCauseView(this.json);
  factory StateChangeCauseView.fromJson(dynamic json) =>
      StateChangeCauseView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `StateChangeKindView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class StateChangeKindView {
  const StateChangeKindView(this.json);
  factory StateChangeKindView.fromJson(dynamic json) =>
      StateChangeKindView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `StateChangeWithCauseView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class StateChangeWithCauseView {
  const StateChangeWithCauseView(this.json);
  factory StateChangeWithCauseView.fromJson(dynamic json) =>
      StateChangeWithCauseView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `StateItem`.
class StateItem {
  const StateItem({this.key, this.value});

  factory StateItem.fromJson(Map<String, dynamic> json) => StateItem(
    key: json[r'key'] == null ? null : json[r'key'] as StoreKey,
    value: json[r'value'] == null ? null : json[r'value'] as StoreValue,
  );

  final StoreKey? key;
  final StoreValue? value;

  Map<String, dynamic> toJson() => {
    if (key != null) r'key': key,
    if (value != null) r'value': value,
  };
}

/// Generated from `StateSyncConfig`.
class StateSyncConfig {
  const StateSyncConfig({
    this.concurrency,
    this.dump,
    this.parts_compression_lvl,
    this.sync,
  });

  factory StateSyncConfig.fromJson(Map<String, dynamic> json) =>
      StateSyncConfig(
        concurrency: json[r'concurrency'] == null
            ? null
            : SyncConcurrency.fromJson(json[r'concurrency']),
        dump: json[r'dump'] == null ? null : json[r'dump'],
        parts_compression_lvl: json[r'parts_compression_lvl'] == null
            ? null
            : (json[r'parts_compression_lvl'] as num).toInt(),
        sync: json[r'sync'] == null ? null : SyncConfig.fromJson(json[r'sync']),
      );

  final SyncConcurrency? concurrency;
  final dynamic? dump;
  final int? parts_compression_lvl;
  final SyncConfig? sync;

  Map<String, dynamic> toJson() => {
    if (concurrency != null) r'concurrency': concurrency?.toJson(),
    if (dump != null) r'dump': dump,
    if (parts_compression_lvl != null)
      r'parts_compression_lvl': parts_compression_lvl,
    if (sync != null) r'sync': sync?.toJson(),
  };
}

/// Generated from `StatusSyncInfo`.
class StatusSyncInfo {
  const StatusSyncInfo({
    this.earliest_block_hash,
    this.earliest_block_height,
    this.earliest_block_time,
    this.epoch_id,
    this.epoch_start_height,
    this.latest_block_hash,
    this.latest_block_height,
    this.latest_block_time,
    this.latest_state_root,
    this.syncing,
  });

  factory StatusSyncInfo.fromJson(Map<String, dynamic> json) => StatusSyncInfo(
    earliest_block_hash: json[r'earliest_block_hash'] == null
        ? null
        : json[r'earliest_block_hash'],
    earliest_block_height: json[r'earliest_block_height'] == null
        ? null
        : (json[r'earliest_block_height'] as num).toInt(),
    earliest_block_time: json[r'earliest_block_time'] == null
        ? null
        : json[r'earliest_block_time'] as String,
    epoch_id: json[r'epoch_id'] == null ? null : json[r'epoch_id'],
    epoch_start_height: json[r'epoch_start_height'] == null
        ? null
        : (json[r'epoch_start_height'] as num).toInt(),
    latest_block_hash: json[r'latest_block_hash'] == null
        ? null
        : json[r'latest_block_hash'] as CryptoHash,
    latest_block_height: json[r'latest_block_height'] == null
        ? null
        : (json[r'latest_block_height'] as num).toInt(),
    latest_block_time: json[r'latest_block_time'] == null
        ? null
        : json[r'latest_block_time'] as String,
    latest_state_root: json[r'latest_state_root'] == null
        ? null
        : json[r'latest_state_root'] as CryptoHash,
    syncing: json[r'syncing'] == null ? null : json[r'syncing'] as bool,
  );

  final dynamic? earliest_block_hash;
  final int? earliest_block_height;
  final String? earliest_block_time;
  final dynamic? epoch_id;
  final int? epoch_start_height;
  final CryptoHash? latest_block_hash;
  final int? latest_block_height;
  final String? latest_block_time;
  final CryptoHash? latest_state_root;
  final bool? syncing;

  Map<String, dynamic> toJson() => {
    if (earliest_block_hash != null)
      r'earliest_block_hash': earliest_block_hash,
    if (earliest_block_height != null)
      r'earliest_block_height': earliest_block_height,
    if (earliest_block_time != null)
      r'earliest_block_time': earliest_block_time,
    if (epoch_id != null) r'epoch_id': epoch_id,
    if (epoch_start_height != null) r'epoch_start_height': epoch_start_height,
    if (latest_block_hash != null) r'latest_block_hash': latest_block_hash,
    if (latest_block_height != null)
      r'latest_block_height': latest_block_height,
    if (latest_block_time != null) r'latest_block_time': latest_block_time,
    if (latest_state_root != null) r'latest_state_root': latest_state_root,
    if (syncing != null) r'syncing': syncing,
  };
}

/// Union type generated from `StorageError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class StorageError {
  const StorageError(this.json);
  factory StorageError.fromJson(dynamic json) => StorageError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `StorageGetMode`.
enum StorageGetMode {
  FlatStorage(r'FlatStorage'),
  Trie(r'Trie');

  const StorageGetMode(this.wireValue);
  final String wireValue;

  static StorageGetMode fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Generated from `StorageUsageConfigView`.
class StorageUsageConfigView {
  const StorageUsageConfigView({
    this.num_bytes_account,
    this.num_extra_bytes_record,
  });

  factory StorageUsageConfigView.fromJson(Map<String, dynamic> json) =>
      StorageUsageConfigView(
        num_bytes_account: json[r'num_bytes_account'] == null
            ? null
            : (json[r'num_bytes_account'] as num).toInt(),
        num_extra_bytes_record: json[r'num_extra_bytes_record'] == null
            ? null
            : (json[r'num_extra_bytes_record'] as num).toInt(),
      );

  final int? num_bytes_account;
  final int? num_extra_bytes_record;

  Map<String, dynamic> toJson() => {
    if (num_bytes_account != null) r'num_bytes_account': num_bytes_account,
    if (num_extra_bytes_record != null)
      r'num_extra_bytes_record': num_extra_bytes_record,
  };
}

/// Alias for `StoreKey`.
typedef StoreKey = String;

/// Alias for `StoreValue`.
typedef StoreValue = String;

/// Generated from `SyncCheckpoint`.
enum SyncCheckpoint {
  genesis(r'genesis'),
  earliest_available(r'earliest_available');

  const SyncCheckpoint(this.wireValue);
  final String wireValue;

  static SyncCheckpoint fromJson(dynamic json) =>
      values.firstWhere((e) => e.wireValue == json);
  String toJson() => wireValue;
}

/// Generated from `SyncConcurrency`.
class SyncConcurrency {
  const SyncConcurrency({
    this.apply,
    this.apply_during_catchup,
    this.peer_downloads,
    this.per_shard,
  });

  factory SyncConcurrency.fromJson(Map<String, dynamic> json) =>
      SyncConcurrency(
        apply: json[r'apply'] == null ? null : (json[r'apply'] as num).toInt(),
        apply_during_catchup: json[r'apply_during_catchup'] == null
            ? null
            : (json[r'apply_during_catchup'] as num).toInt(),
        peer_downloads: json[r'peer_downloads'] == null
            ? null
            : (json[r'peer_downloads'] as num).toInt(),
        per_shard: json[r'per_shard'] == null
            ? null
            : (json[r'per_shard'] as num).toInt(),
      );

  final int? apply;
  final int? apply_during_catchup;
  final int? peer_downloads;
  final int? per_shard;

  Map<String, dynamic> toJson() => {
    if (apply != null) r'apply': apply,
    if (apply_during_catchup != null)
      r'apply_during_catchup': apply_during_catchup,
    if (peer_downloads != null) r'peer_downloads': peer_downloads,
    if (per_shard != null) r'per_shard': per_shard,
  };
}

/// Union type generated from `SyncConfig`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class SyncConfig {
  const SyncConfig(this.json);
  factory SyncConfig.fromJson(dynamic json) => SyncConfig(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `Tier1ProxyView`.
class Tier1ProxyView {
  const Tier1ProxyView({this.addr, this.peer_id});

  factory Tier1ProxyView.fromJson(Map<String, dynamic> json) => Tier1ProxyView(
    addr: json[r'addr'] == null ? null : json[r'addr'] as String,
    peer_id: json[r'peer_id'] == null ? null : json[r'peer_id'] as PublicKey,
  );

  final String? addr;
  final PublicKey? peer_id;

  Map<String, dynamic> toJson() => {
    if (addr != null) r'addr': addr,
    if (peer_id != null) r'peer_id': peer_id,
  };
}

/// Union type generated from `TrackedShardsConfig`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class TrackedShardsConfig {
  const TrackedShardsConfig(this.json);
  factory TrackedShardsConfig.fromJson(dynamic json) =>
      TrackedShardsConfig(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `TransactionNonce`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class TransactionNonce {
  const TransactionNonce(this.json);
  factory TransactionNonce.fromJson(dynamic json) => TransactionNonce(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `TransferAction`.
class TransferAction {
  const TransferAction({this.deposit});

  factory TransferAction.fromJson(Map<String, dynamic> json) => TransferAction(
    deposit: json[r'deposit'] == null ? null : json[r'deposit'] as NearToken,
  );

  final NearToken? deposit;

  Map<String, dynamic> toJson() => {if (deposit != null) r'deposit': deposit};
}

/// Generated from `TransferToGasKeyAction`.
class TransferToGasKeyAction {
  const TransferToGasKeyAction({this.deposit, this.public_key});

  factory TransferToGasKeyAction.fromJson(Map<String, dynamic> json) =>
      TransferToGasKeyAction(
        deposit: json[r'deposit'] == null
            ? null
            : json[r'deposit'] as NearToken,
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
      );

  final NearToken? deposit;
  final PublicKey? public_key;

  Map<String, dynamic> toJson() => {
    if (deposit != null) r'deposit': deposit,
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `TrieSplit`.
class TrieSplit {
  const TrieSplit({this.boundary_account, this.left_memory, this.right_memory});

  factory TrieSplit.fromJson(Map<String, dynamic> json) => TrieSplit(
    boundary_account: json[r'boundary_account'] == null
        ? null
        : json[r'boundary_account'] as AccountId,
    left_memory: json[r'left_memory'] == null
        ? null
        : (json[r'left_memory'] as num).toInt(),
    right_memory: json[r'right_memory'] == null
        ? null
        : (json[r'right_memory'] as num).toInt(),
  );

  final AccountId? boundary_account;
  final int? left_memory;
  final int? right_memory;

  Map<String, dynamic> toJson() => {
    if (boundary_account != null) r'boundary_account': boundary_account,
    if (left_memory != null) r'left_memory': left_memory,
    if (right_memory != null) r'right_memory': right_memory,
  };
}

/// Union type generated from `TxExecutionError`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class TxExecutionError {
  const TxExecutionError(this.json);
  factory TxExecutionError.fromJson(dynamic json) => TxExecutionError(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Union type generated from `TxExecutionStatus`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class TxExecutionStatus {
  const TxExecutionStatus(this.json);
  factory TxExecutionStatus.fromJson(dynamic json) => TxExecutionStatus(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `UseGlobalContractAction`.
class UseGlobalContractAction {
  const UseGlobalContractAction({this.contract_identifier});

  factory UseGlobalContractAction.fromJson(Map<String, dynamic> json) =>
      UseGlobalContractAction(
        contract_identifier: json[r'contract_identifier'] == null
            ? null
            : GlobalContractIdentifier.fromJson(json[r'contract_identifier']),
      );

  final GlobalContractIdentifier? contract_identifier;

  Map<String, dynamic> toJson() => {
    if (contract_identifier != null)
      r'contract_identifier': contract_identifier?.toJson(),
  };
}

/// Generated from `VMConfigView`.
class VMConfigView {
  const VMConfigView({
    this.bls12381_not_in_group_fix,
    this.chain_id_host_fn,
    this.discard_custom_sections,
    this.eth_implicit_accounts,
    this.eth_implicit_global_contract,
    this.ext_costs,
    this.fix_contract_loading_cost,
    this.gas_key_host_fns,
    this.global_contract_host_fns,
    this.grow_mem_cost,
    this.implicit_account_creation,
    this.limit_config,
    this.linear_op_base_cost,
    this.linear_op_unit_cost,
    this.one_yocto_on_promise,
    this.p256_verify_host_fn,
    this.reftypes_bulk_memory,
    this.regular_op_cost,
    this.storage_get_mode,
    this.vm_kind,
    this.yield_with_id_host_fns,
  });

  factory VMConfigView.fromJson(Map<String, dynamic> json) => VMConfigView(
    bls12381_not_in_group_fix: json[r'bls12381_not_in_group_fix'] == null
        ? null
        : json[r'bls12381_not_in_group_fix'] as bool,
    chain_id_host_fn: json[r'chain_id_host_fn'] == null
        ? null
        : json[r'chain_id_host_fn'] as bool,
    discard_custom_sections: json[r'discard_custom_sections'] == null
        ? null
        : json[r'discard_custom_sections'] as bool,
    eth_implicit_accounts: json[r'eth_implicit_accounts'] == null
        ? null
        : json[r'eth_implicit_accounts'] as bool,
    eth_implicit_global_contract: json[r'eth_implicit_global_contract'] == null
        ? null
        : json[r'eth_implicit_global_contract'] as bool,
    ext_costs: json[r'ext_costs'] == null
        ? null
        : ExtCostsConfigView.fromJson(json[r'ext_costs']),
    fix_contract_loading_cost: json[r'fix_contract_loading_cost'] == null
        ? null
        : json[r'fix_contract_loading_cost'] as bool,
    gas_key_host_fns: json[r'gas_key_host_fns'] == null
        ? null
        : json[r'gas_key_host_fns'] as bool,
    global_contract_host_fns: json[r'global_contract_host_fns'] == null
        ? null
        : json[r'global_contract_host_fns'] as bool,
    grow_mem_cost: json[r'grow_mem_cost'] == null
        ? null
        : (json[r'grow_mem_cost'] as num).toInt(),
    implicit_account_creation: json[r'implicit_account_creation'] == null
        ? null
        : json[r'implicit_account_creation'] as bool,
    limit_config: json[r'limit_config'] == null
        ? null
        : LimitConfig.fromJson(json[r'limit_config']),
    linear_op_base_cost: json[r'linear_op_base_cost'] == null
        ? null
        : (json[r'linear_op_base_cost'] as num).toInt(),
    linear_op_unit_cost: json[r'linear_op_unit_cost'] == null
        ? null
        : (json[r'linear_op_unit_cost'] as num).toInt(),
    one_yocto_on_promise: json[r'one_yocto_on_promise'] == null
        ? null
        : json[r'one_yocto_on_promise'] as bool,
    p256_verify_host_fn: json[r'p256_verify_host_fn'] == null
        ? null
        : json[r'p256_verify_host_fn'] as bool,
    reftypes_bulk_memory: json[r'reftypes_bulk_memory'] == null
        ? null
        : json[r'reftypes_bulk_memory'] as bool,
    regular_op_cost: json[r'regular_op_cost'] == null
        ? null
        : (json[r'regular_op_cost'] as num).toInt(),
    storage_get_mode: json[r'storage_get_mode'] == null
        ? null
        : StorageGetMode.fromJson(json[r'storage_get_mode']),
    vm_kind: json[r'vm_kind'] == null
        ? null
        : VMKind.fromJson(json[r'vm_kind']),
    yield_with_id_host_fns: json[r'yield_with_id_host_fns'] == null
        ? null
        : json[r'yield_with_id_host_fns'] as bool,
  );

  final bool? bls12381_not_in_group_fix;
  final bool? chain_id_host_fn;
  final bool? discard_custom_sections;
  final bool? eth_implicit_accounts;
  final bool? eth_implicit_global_contract;
  final ExtCostsConfigView? ext_costs;
  final bool? fix_contract_loading_cost;
  final bool? gas_key_host_fns;
  final bool? global_contract_host_fns;
  final int? grow_mem_cost;
  final bool? implicit_account_creation;
  final LimitConfig? limit_config;
  final int? linear_op_base_cost;
  final int? linear_op_unit_cost;
  final bool? one_yocto_on_promise;
  final bool? p256_verify_host_fn;
  final bool? reftypes_bulk_memory;
  final int? regular_op_cost;
  final StorageGetMode? storage_get_mode;
  final VMKind? vm_kind;
  final bool? yield_with_id_host_fns;

  Map<String, dynamic> toJson() => {
    if (bls12381_not_in_group_fix != null)
      r'bls12381_not_in_group_fix': bls12381_not_in_group_fix,
    if (chain_id_host_fn != null) r'chain_id_host_fn': chain_id_host_fn,
    if (discard_custom_sections != null)
      r'discard_custom_sections': discard_custom_sections,
    if (eth_implicit_accounts != null)
      r'eth_implicit_accounts': eth_implicit_accounts,
    if (eth_implicit_global_contract != null)
      r'eth_implicit_global_contract': eth_implicit_global_contract,
    if (ext_costs != null) r'ext_costs': ext_costs?.toJson(),
    if (fix_contract_loading_cost != null)
      r'fix_contract_loading_cost': fix_contract_loading_cost,
    if (gas_key_host_fns != null) r'gas_key_host_fns': gas_key_host_fns,
    if (global_contract_host_fns != null)
      r'global_contract_host_fns': global_contract_host_fns,
    if (grow_mem_cost != null) r'grow_mem_cost': grow_mem_cost,
    if (implicit_account_creation != null)
      r'implicit_account_creation': implicit_account_creation,
    if (limit_config != null) r'limit_config': limit_config?.toJson(),
    if (linear_op_base_cost != null)
      r'linear_op_base_cost': linear_op_base_cost,
    if (linear_op_unit_cost != null)
      r'linear_op_unit_cost': linear_op_unit_cost,
    if (one_yocto_on_promise != null)
      r'one_yocto_on_promise': one_yocto_on_promise,
    if (p256_verify_host_fn != null)
      r'p256_verify_host_fn': p256_verify_host_fn,
    if (reftypes_bulk_memory != null)
      r'reftypes_bulk_memory': reftypes_bulk_memory,
    if (regular_op_cost != null) r'regular_op_cost': regular_op_cost,
    if (storage_get_mode != null)
      r'storage_get_mode': storage_get_mode?.toJson(),
    if (vm_kind != null) r'vm_kind': vm_kind?.toJson(),
    if (yield_with_id_host_fns != null)
      r'yield_with_id_host_fns': yield_with_id_host_fns,
  };
}

/// Union type generated from `VMKind`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class VMKind {
  const VMKind(this.json);
  factory VMKind.fromJson(dynamic json) => VMKind(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ValidatorInfo`.
class ValidatorInfo {
  const ValidatorInfo({this.account_id});

  factory ValidatorInfo.fromJson(Map<String, dynamic> json) => ValidatorInfo(
    account_id: json[r'account_id'] == null
        ? null
        : json[r'account_id'] as AccountId,
  );

  final AccountId? account_id;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
  };
}

/// Union type generated from `ValidatorKickoutReason`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ValidatorKickoutReason {
  const ValidatorKickoutReason(this.json);
  factory ValidatorKickoutReason.fromJson(dynamic json) =>
      ValidatorKickoutReason(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ValidatorKickoutView`.
class ValidatorKickoutView {
  const ValidatorKickoutView({this.account_id, this.reason});

  factory ValidatorKickoutView.fromJson(Map<String, dynamic> json) =>
      ValidatorKickoutView(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        reason: json[r'reason'] == null
            ? null
            : ValidatorKickoutReason.fromJson(json[r'reason']),
      );

  final AccountId? account_id;
  final ValidatorKickoutReason? reason;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (reason != null) r'reason': reason?.toJson(),
  };
}

/// Union type generated from `ValidatorStakeView`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class ValidatorStakeView {
  const ValidatorStakeView(this.json);
  factory ValidatorStakeView.fromJson(dynamic json) => ValidatorStakeView(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `ValidatorStakeViewV1`.
class ValidatorStakeViewV1 {
  const ValidatorStakeViewV1({this.account_id, this.public_key, this.stake});

  factory ValidatorStakeViewV1.fromJson(Map<String, dynamic> json) =>
      ValidatorStakeViewV1(
        account_id: json[r'account_id'] == null
            ? null
            : json[r'account_id'] as AccountId,
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
        stake: json[r'stake'] == null ? null : json[r'stake'] as NearToken,
      );

  final AccountId? account_id;
  final PublicKey? public_key;
  final NearToken? stake;

  Map<String, dynamic> toJson() => {
    if (account_id != null) r'account_id': account_id,
    if (public_key != null) r'public_key': public_key,
    if (stake != null) r'stake': stake,
  };
}

/// Generated from `Version`.
class Version {
  const Version({this.build, this.commit, this.rustc_version, this.version});

  factory Version.fromJson(Map<String, dynamic> json) => Version(
    build: json[r'build'] == null ? null : json[r'build'] as String,
    commit: json[r'commit'] == null ? null : json[r'commit'] as String,
    rustc_version: json[r'rustc_version'] == null
        ? null
        : json[r'rustc_version'] as String,
    version: json[r'version'] == null ? null : json[r'version'] as String,
  );

  final String? build;
  final String? commit;
  final String? rustc_version;
  final String? version;

  Map<String, dynamic> toJson() => {
    if (build != null) r'build': build,
    if (commit != null) r'commit': commit,
    if (rustc_version != null) r'rustc_version': rustc_version,
    if (version != null) r'version': version,
  };
}

/// Union type generated from `VersionedDelegateActionPayload`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class VersionedDelegateActionPayload {
  const VersionedDelegateActionPayload(this.json);
  factory VersionedDelegateActionPayload.fromJson(dynamic json) =>
      VersionedDelegateActionPayload(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `VersionedSignedDelegateAction`.
class VersionedSignedDelegateAction {
  const VersionedSignedDelegateAction({this.delegate_action, this.signature});

  factory VersionedSignedDelegateAction.fromJson(Map<String, dynamic> json) =>
      VersionedSignedDelegateAction(
        delegate_action: json[r'delegate_action'] == null
            ? null
            : VersionedDelegateActionPayload.fromJson(json[r'delegate_action']),
        signature: json[r'signature'] == null
            ? null
            : json[r'signature'] as Signature,
      );

  final VersionedDelegateActionPayload? delegate_action;
  final Signature? signature;

  Map<String, dynamic> toJson() => {
    if (delegate_action != null) r'delegate_action': delegate_action?.toJson(),
    if (signature != null) r'signature': signature,
  };
}

/// Generated from `ViewStateResult`.
class ViewStateResult {
  const ViewStateResult({this.last_key, this.proof, this.values});

  factory ViewStateResult.fromJson(Map<String, dynamic> json) =>
      ViewStateResult(
        last_key: json[r'last_key'] == null ? null : json[r'last_key'],
        proof: json[r'proof'] == null
            ? null
            : (json[r'proof'] as List).map<String>((e) => e as String).toList(),
        values: json[r'values'] == null
            ? null
            : (json[r'values'] as List)
                  .map<StateItem>((e) => StateItem.fromJson(e))
                  .toList(),
      );

  final dynamic? last_key;
  final List<String>? proof;
  final List<StateItem>? values;

  Map<String, dynamic> toJson() => {
    if (last_key != null) r'last_key': last_key,
    if (proof != null) r'proof': proof,
    if (values != null) r'values': values?.map((e) => e.toJson()).toList(),
  };
}

/// Union type generated from `WasmTrap`.
///
/// Holds the raw decoded JSON; inspect [json] for the
/// active variant (NEAR serializes these tagged).
class WasmTrap {
  const WasmTrap(this.json);
  factory WasmTrap.fromJson(dynamic json) => WasmTrap(json);
  final dynamic json;
  dynamic toJson() => json;
}

/// Generated from `WithdrawFromGasKeyAction`.
class WithdrawFromGasKeyAction {
  const WithdrawFromGasKeyAction({this.amount, this.public_key});

  factory WithdrawFromGasKeyAction.fromJson(Map<String, dynamic> json) =>
      WithdrawFromGasKeyAction(
        amount: json[r'amount'] == null ? null : json[r'amount'] as NearToken,
        public_key: json[r'public_key'] == null
            ? null
            : json[r'public_key'] as PublicKey,
      );

  final NearToken? amount;
  final PublicKey? public_key;

  Map<String, dynamic> toJson() => {
    if (amount != null) r'amount': amount,
    if (public_key != null) r'public_key': public_key,
  };
}

/// Generated from `WitnessConfigView`.
class WitnessConfigView {
  const WitnessConfigView({
    this.combined_transactions_size_limit,
    this.main_storage_proof_size_soft_limit,
    this.new_transactions_validation_state_size_soft_limit,
  });

  factory WitnessConfigView.fromJson(Map<String, dynamic> json) =>
      WitnessConfigView(
        combined_transactions_size_limit:
            json[r'combined_transactions_size_limit'] == null
            ? null
            : (json[r'combined_transactions_size_limit'] as num).toInt(),
        main_storage_proof_size_soft_limit:
            json[r'main_storage_proof_size_soft_limit'] == null
            ? null
            : (json[r'main_storage_proof_size_soft_limit'] as num).toInt(),
        new_transactions_validation_state_size_soft_limit:
            json[r'new_transactions_validation_state_size_soft_limit'] == null
            ? null
            : (json[r'new_transactions_validation_state_size_soft_limit']
                      as num)
                  .toInt(),
      );

  final int? combined_transactions_size_limit;
  final int? main_storage_proof_size_soft_limit;
  final int? new_transactions_validation_state_size_soft_limit;

  Map<String, dynamic> toJson() => {
    if (combined_transactions_size_limit != null)
      r'combined_transactions_size_limit': combined_transactions_size_limit,
    if (main_storage_proof_size_soft_limit != null)
      r'main_storage_proof_size_soft_limit': main_storage_proof_size_soft_limit,
    if (new_transactions_validation_state_size_soft_limit != null)
      r'new_transactions_validation_state_size_soft_limit':
          new_transactions_validation_state_size_soft_limit,
  };
}
