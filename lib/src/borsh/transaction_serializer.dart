import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../encoding/base58.dart';
import '../types/primitives.dart';
import '../wallet/actions.dart';
import '../wallet/transaction.dart';
import 'borsh_writer.dart';

/// Computes the SHA-256 hash of [bytes].
///
/// NEAR transaction hashes are `sha256(borsh(transaction))`.
Uint8List sha256Hash(List<int> bytes) =>
    Uint8List.fromList(crypto.sha256.convert(bytes).bytes);

/// Serializes a [Transaction] to Borsh bytes, per the NEAR transaction
/// schema (https://nomicon.io/RuntimeSpec/Transactions).
///
/// The transaction must carry [Transaction.publicKey], [Transaction.nonce]
/// and [Transaction.blockHash]; otherwise a [StateError] is thrown.
Uint8List serializeTransaction(Transaction transaction) {
  final publicKey = transaction.publicKey;
  final nonce = transaction.nonce;
  final blockHash = transaction.blockHash;
  if (publicKey == null || nonce == null || blockHash == null) {
    throw StateError(
      'Transaction is missing publicKey, nonce or blockHash. '
      'These are required for Borsh serialization and signing.',
    );
  }

  final writer = BorshWriter()..writeString(transaction.signerId.value);
  _writePublicKey(writer, publicKey);
  writer
    ..writeU64(nonce)
    ..writeString(transaction.receiverId.value)
    ..writeFixedBytes(_decodeBlockHash(blockHash))
    ..writeVec<Action>(transaction.actions, _writeAction);
  return writer.toBytes();
}

/// Serializes a [SignedTransaction] to Borsh bytes:
/// `borsh(transaction) || Signature { key_type: u8, data: [64]u8 }`.
Uint8List serializeSignedTransaction(SignedTransaction signedTransaction) {
  final signatureBytes = signedTransaction.signatureBytes;
  if (signatureBytes.length != 64) {
    throw StateError(
      'ed25519 signature must be 64 bytes, got ${signatureBytes.length}',
    );
  }
  final writer = BorshWriter()
    ..writeFixedBytes(serializeTransaction(signedTransaction.transaction))
    ..writeU8(signedTransaction.publicKey.keyType == KeyType.ed25519 ? 0 : 1)
    ..writeFixedBytes(signatureBytes);
  return writer.toBytes();
}

Uint8List _decodeBlockHash(CryptoHash blockHash) {
  final bytes = base58Decode(blockHash.value);
  if (bytes.length != 32) {
    throw StateError(
      'Block hash must decode to 32 bytes, got ${bytes.length} '
      '(${blockHash.value})',
    );
  }
  return bytes;
}

void _writePublicKey(BorshWriter writer, PublicKey publicKey) {
  final data = base58Decode(publicKey.keyData);
  switch (publicKey.keyType) {
    case KeyType.ed25519:
      if (data.length != 32) {
        throw StateError('ed25519 public key must be 32 bytes');
      }
      writer
        ..writeU8(0)
        ..writeFixedBytes(data);
    case KeyType.secp256k1:
      if (data.length != 64) {
        throw StateError('secp256k1 public key must be 64 bytes');
      }
      writer
        ..writeU8(1)
        ..writeFixedBytes(data);
  }
}

/// Borsh enum indices for `Action`, per nearcore's `Action` enum order.
void _writeAction(BorshWriter writer, Action action) {
  switch (action) {
    case CreateAccountAction():
      writer.writeU8(0);
    case DeployContractAction(:final code):
      writer
        ..writeU8(1)
        ..writeBytes(code);
    case FunctionCallAction(
      :final methodName,
      :final args,
      :final gas,
      :final deposit,
    ):
      writer
        ..writeU8(2)
        ..writeString(methodName)
        ..writeBytes(args == null ? const [] : utf8.encode(jsonEncode(args)))
        ..writeU64(gas)
        ..writeU128(deposit.yoctoNear);
    case TransferAction(:final deposit):
      writer
        ..writeU8(3)
        ..writeU128(deposit.yoctoNear);
    case StakeAction(:final stake, :final publicKey):
      writer
        ..writeU8(4)
        ..writeU128(stake.yoctoNear);
      _writePublicKey(writer, publicKey);
    case AddKeyAction(:final publicKey, :final accessKey):
      writer.writeU8(5);
      _writePublicKey(writer, publicKey);
      _writeAccessKey(writer, accessKey);
    case DeleteKeyAction(:final publicKey):
      writer.writeU8(6);
      _writePublicKey(writer, publicKey);
    case DeleteAccountAction(:final beneficiaryId):
      writer
        ..writeU8(7)
        ..writeString(beneficiaryId.value);
    // Index 8 is Delegate (NEP-366), not yet supported.
    case DeployGlobalContractAction(:final code, :final deployMode):
      writer
        ..writeU8(9)
        ..writeBytes(code)
        ..writeU8(deployMode == GlobalContractDeployMode.codeHash ? 0 : 1);
    case UseGlobalContractAction(:final identifier):
      writer.writeU8(10);
      switch (identifier) {
        case GlobalContractCodeHash(:final hash):
          if (hash.length != 32) {
            throw StateError('Global contract code hash must be 32 bytes');
          }
          writer
            ..writeU8(0)
            ..writeFixedBytes(hash);
        case GlobalContractAccountId(:final accountId):
          writer
            ..writeU8(1)
            ..writeString(accountId.value);
      }
  }
}

void _writeAccessKey(BorshWriter writer, AccessKey accessKey) {
  // AccessKey { nonce: u64, permission: AccessKeyPermission }
  writer.writeU64(BigInt.zero);
  switch (accessKey) {
    case FunctionCallAccessKey(
      :final allowance,
      :final receiverId,
      :final methodNames,
    ):
      writer
        ..writeU8(0)
        ..writeOption<BigInt>(allowance?.yoctoNear, (w, v) => w.writeU128(v))
        ..writeString(receiverId.value)
        ..writeVec<String>(methodNames, (w, v) => w.writeString(v));
    case FullAccessKey():
      writer.writeU8(1);
  }
}
