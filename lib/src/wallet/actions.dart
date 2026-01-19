import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_flutter/near_flutter.dart';

/// Types of actions that can be performed in a NEAR transaction.
enum ActionType {
  createAccount,
  deployContract,
  functionCall,
  transfer,
  stake,
  addKey,
  deleteKey,
  deleteAccount,
}

/// Base class for all NEAR transaction actions.
@immutable
sealed class Action extends Equatable {
  const Action();

  /// The type of this action.
  ActionType get type;

  /// Serializes the action to JSON format.
  Map<String, dynamic> toJson();
}

/// Creates a new account.
@immutable
class CreateAccountAction extends Action {
  const CreateAccountAction();

  @override
  ActionType get type => ActionType.createAccount;

  @override
  Map<String, dynamic> toJson() => {'CreateAccount': <String, dynamic>{}};

  @override
  List<Object?> get props => [];
}

/// Deploys a smart contract to the account.
@immutable
class DeployContractAction extends Action {
  const DeployContractAction({required this.code});

  /// The WASM code of the contract.
  final List<int> code;

  @override
  ActionType get type => ActionType.deployContract;

  @override
  Map<String, dynamic> toJson() => {
        'DeployContract': {'code': code},
      };

  @override
  List<Object?> get props => [code];
}

/// Calls a method on a smart contract.
@immutable
class FunctionCallAction extends Action {
  FunctionCallAction({
    required this.methodName,
    this.args,
    BigInt? gas,
    required this.deposit,
  }) : gas = gas ?? _defaultGas;

  /// Default gas: 30 TGas (30 * 10^12).
  static final BigInt _defaultGas = BigInt.from(30) * BigInt.from(10).pow(12);

  /// The name of the method to call.
  final String methodName;

  /// Arguments to pass to the method. Can be a Map or a List.
  final Object? args;

  /// Maximum gas to use for this call.
  final BigInt gas;

  /// Amount of NEAR to attach to the call.
  final NearToken deposit;

  @override
  ActionType get type => ActionType.functionCall;

  @override
  Map<String, dynamic> toJson() {
    String encodedArgs = '';
    if (args != null) {
      final jsonString = jsonEncode(args);
      encodedArgs = base64Encode(utf8.encode(jsonString));
    }

    return {
      'FunctionCall': {
        'method_name': methodName,
        'args': encodedArgs,
        'gas': gas.toString(),
        'deposit': deposit.yoctoNear.toString(),
      },
    };
  }

  @override
  List<Object?> get props => [methodName, args, gas, deposit];
}

/// Transfers NEAR tokens to another account.
@immutable
class TransferAction extends Action {
  const TransferAction({required this.deposit});

  /// Amount of NEAR to transfer.
  final NearToken deposit;

  @override
  ActionType get type => ActionType.transfer;

  @override
  Map<String, dynamic> toJson() => {
        'Transfer': {
          'deposit': deposit.yoctoNear.toString(),
        },
      };

  @override
  List<Object?> get props => [deposit];
}

/// Stakes NEAR tokens with a validator.
@immutable
class StakeAction extends Action {
  const StakeAction({
    required this.stake,
    required this.publicKey,
  });

  /// Amount of NEAR to stake.
  final NearToken stake;

  /// Public key of the validator.
  final PublicKey publicKey;

  @override
  ActionType get type => ActionType.stake;

  @override
  Map<String, dynamic> toJson() => {
        'Stake': {
          'stake': stake.yoctoNear.toString(),
          'public_key': publicKey.value,
        },
      };

  @override
  List<Object?> get props => [stake, publicKey];
}

/// Adds a new access key to the account.
@immutable
class AddKeyAction extends Action {
  const AddKeyAction({
    required this.publicKey,
    required this.accessKey,
  });

  /// The public key to add.
  final PublicKey publicKey;

  /// The access key configuration.
  final AccessKey accessKey;

  @override
  ActionType get type => ActionType.addKey;

  @override
  Map<String, dynamic> toJson() => {
        'AddKey': {
          'public_key': publicKey.value,
          'access_key': accessKey.toJson(),
        },
      };

  @override
  List<Object?> get props => [publicKey, accessKey];
}

/// Deletes an access key from the account.
@immutable
class DeleteKeyAction extends Action {
  const DeleteKeyAction({required this.publicKey});

  /// The public key to delete.
  final PublicKey publicKey;

  @override
  ActionType get type => ActionType.deleteKey;

  @override
  Map<String, dynamic> toJson() => {
        'DeleteKey': {
          'public_key': publicKey.value,
        },
      };

  @override
  List<Object?> get props => [publicKey];
}

/// Deletes the account and transfers remaining balance to beneficiary.
@immutable
class DeleteAccountAction extends Action {
  const DeleteAccountAction({required this.beneficiaryId});

  /// The account to receive remaining balance.
  final AccountId beneficiaryId;

  @override
  ActionType get type => ActionType.deleteAccount;

  @override
  Map<String, dynamic> toJson() => {
        'DeleteAccount': {
          'beneficiary_id': beneficiaryId.value,
        },
      };

  @override
  List<Object?> get props => [beneficiaryId];
}

/// Base class for access key configurations.
@immutable
sealed class AccessKey extends Equatable {
  const AccessKey();

  /// Serializes the access key to JSON.
  Map<String, dynamic> toJson();
}

/// Full access key - allows all operations.
@immutable
class FullAccessKey extends AccessKey {
  const FullAccessKey();

  @override
  Map<String, dynamic> toJson() => {'permission': 'FullAccess'};

  @override
  List<Object?> get props => [];
}

/// Function call access key - only allows calling specified methods.
@immutable
class FunctionCallAccessKey extends AccessKey {
  const FunctionCallAccessKey({
    required this.receiverId,
    this.methodNames = const [],
    this.allowance,
  });

  /// The contract that can be called.
  final AccountId receiverId;

  /// List of methods that can be called. Empty means all methods.
  final List<String> methodNames;

  /// Maximum amount of gas that can be spent. Null means unlimited.
  final NearToken? allowance;

  @override
  Map<String, dynamic> toJson() => {
        'permission': {
          'FunctionCall': {
            'receiver_id': receiverId.value,
            'method_names': methodNames,
            'allowance': allowance?.yoctoNear.toString(),
          },
        },
      };

  @override
  List<Object?> get props => [receiverId, methodNames, allowance];
}
