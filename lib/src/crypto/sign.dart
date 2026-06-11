import '../borsh/transaction_serializer.dart';
import '../encoding/base58.dart';
import '../wallet/transaction.dart';
import 'key_pair.dart';

/// Signs a [Transaction] locally with [keyPair], producing a
/// [SignedTransaction] ready to broadcast via `send_tx`.
///
/// The transaction must carry [Transaction.nonce] and
/// [Transaction.blockHash] (a [StateError] is thrown otherwise). If
/// [Transaction.publicKey] is unset, the key pair's public key is filled
/// in automatically.
///
/// The signature is `ed25519(sha256(borsh(transaction)))`, per the NEAR
/// transaction spec.
///
/// ```dart
/// final signed = await signTransaction(transaction, keyPair);
/// final result = await client.sendTransaction(signed);
/// ```
Future<SignedTransaction> signTransaction(
  Transaction transaction,
  KeyPairEd25519 keyPair,
) async {
  final tx = transaction.publicKey == null
      ? transaction.copyWith(publicKey: keyPair.publicKey)
      : transaction;

  final txBytes = serializeTransaction(tx);
  final txHash = sha256Hash(txBytes);
  final signature = await keyPair.sign(txHash);

  return SignedTransaction(
    transaction: tx,
    signature: 'ed25519:${base58Encode(signature)}',
    publicKey: keyPair.publicKey,
    hash: base58Encode(txHash),
  );
}
