import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

/// A NEAR transaction containing one or more actions.
///
/// For wallet-redirect flows only [signerId], [receiverId] and [actions]
/// are required. To sign locally (see `signTransaction`) the transaction
/// must also carry [publicKey], [nonce] and [blockHash].
@immutable
class Transaction extends Equatable {
  const Transaction({
    required this.signerId,
    required this.receiverId,
    required this.actions,
    this.publicKey,
    this.nonce,
    this.blockHash,
  });

  /// The account signing the transaction.
  final AccountId signerId;

  /// The account receiving the transaction.
  final AccountId receiverId;

  /// The actions to perform.
  final List<Action> actions;

  /// The public key of the access key used to sign.
  ///
  /// Required for local signing and Borsh serialization.
  final PublicKey? publicKey;

  /// The access key nonce + 1.
  ///
  /// Required for local signing and Borsh serialization.
  final BigInt? nonce;

  /// A recent block hash (within ~24h) proving transaction recency.
  ///
  /// Required for local signing and Borsh serialization.
  final CryptoHash? blockHash;

  /// Returns a copy with the given signing fields filled in.
  Transaction copyWith({
    PublicKey? publicKey,
    BigInt? nonce,
    CryptoHash? blockHash,
  }) => Transaction(
    signerId: signerId,
    receiverId: receiverId,
    actions: actions,
    publicKey: publicKey ?? this.publicKey,
    nonce: nonce ?? this.nonce,
    blockHash: blockHash ?? this.blockHash,
  );

  /// Serializes the transaction to JSON.
  Map<String, dynamic> toJson() => {
    'signerId': signerId.value,
    'receiverId': receiverId.value,
    'actions': actions.map((a) => a.toJson()).toList(),
    if (publicKey != null) 'publicKey': publicKey!.value,
    if (nonce != null) 'nonce': nonce!.toString(),
    if (blockHash != null) 'blockHash': blockHash!.value,
  };

  @override
  List<Object?> get props => [
    signerId,
    receiverId,
    actions,
    publicKey,
    nonce,
    blockHash,
  ];
}

/// A signed NEAR transaction, ready to broadcast via `send_tx`.
///
/// Produced by `signTransaction` (local signing with a [KeyPairEd25519])
/// or by wallet adapters.
@immutable
class SignedTransaction extends Equatable {
  const SignedTransaction({
    required this.transaction,
    required this.signature,
    required this.publicKey,
    this.hash,
  });

  /// The transaction that was signed (carries publicKey/nonce/blockHash).
  final Transaction transaction;

  /// The signature in NEAR format: `ed25519:<base58 of 64 bytes>`.
  final String signature;

  /// The public key used to sign.
  final PublicKey publicKey;

  /// The transaction hash (base58 of `sha256(borsh(transaction))`),
  /// if known. Useful for explorer links and `tx` status queries.
  final String? hash;

  /// The raw 64-byte signature.
  Uint8List get signatureBytes {
    final colonIndex = signature.indexOf(':');
    final data = colonIndex == -1
        ? signature
        : signature.substring(colonIndex + 1);
    return base58Decode(data);
  }

  /// Borsh-serializes this signed transaction and base64-encodes it —
  /// the exact payload expected by the `send_tx` RPC method.
  String encodeToBase64() => base64Encode(serializeSignedTransaction(this));

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'transaction': transaction.toJson(),
    'signature': signature,
    'public_key': publicKey.value,
    if (hash != null) 'hash': hash,
  };

  @override
  List<Object?> get props => [transaction, signature, publicKey, hash];
}
