import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

import 'actions.dart';

/// A NEAR transaction containing one or more actions.
@immutable
class Transaction extends Equatable {
  const Transaction({
    required this.signerId,
    required this.receiverId,
    required this.actions,
  });

  /// The account signing the transaction.
  final AccountId signerId;

  /// The account receiving the transaction.
  final AccountId receiverId;

  /// The actions to perform.
  final List<Action> actions;

  /// Serializes the transaction to JSON.
  Map<String, dynamic> toJson() => {
        'signerId': signerId.value,
        'receiverId': receiverId.value,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  @override
  List<Object?> get props => [signerId, receiverId, actions];
}

/// A signed NEAR transaction.
@immutable
class SignedTransaction extends Equatable {
  const SignedTransaction({
    required this.transaction,
    required this.signature,
    required this.publicKey,
  });

  /// The unsigned transaction.
  final Transaction transaction;

  /// The signature of the transaction.
  final String signature;

  /// The public key used to sign.
  final PublicKey publicKey;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'transaction': transaction.toJson(),
        'signature': signature,
        'public_key': publicKey.value,
      };

  @override
  List<Object?> get props => [transaction, signature, publicKey];
}
