import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../borsh/borsh_writer.dart';
import '../borsh/transaction_serializer.dart' show sha256Hash;
import '../crypto/key_pair.dart';
import '../types/primitives.dart';

/// NEP-413 off-chain message signing.
///
/// Serializes and signs messages for "Sign in with NEAR"-style authentication
/// without a transaction. The signable bytes are:
///
/// ```
/// borsh(u32 tag = 2^31 + 413) ++ borsh({ message, nonce[32], recipient, callbackUrl? })
/// ```
///
/// hashed with SHA-256 and signed with ed25519. Signatures are exchanged
/// base64-encoded, per the NEP-413 wallet standard.
///
/// See: https://github.com/near/NEPs/blob/master/neps/nep-0413.md
class Nep413Payload {
  Nep413Payload({
    required this.message,
    required this.nonce,
    required this.recipient,
    this.callbackUrl,
  }) {
    if (nonce.length != 32) {
      throw ArgumentError.value(
        nonce.length,
        'nonce',
        'NEP-413 nonce must be exactly 32 bytes',
      );
    }
  }

  /// Tag prefix ensuring a signed message can never be a valid transaction.
  static const int tag = 2147484061; // 2^31 + 413

  final String message;
  final List<int> nonce;
  final String recipient;

  /// Present when a web wallet signs via full-page redirect — the wallet
  /// includes the callback URL in the signed payload, so verifiers must too.
  final String? callbackUrl;

  /// The Borsh-serialized signable bytes (tag + payload).
  Uint8List serialize() {
    final writer = BorshWriter()
      ..writeU32(tag)
      ..writeString(message)
      ..writeFixedBytes(nonce)
      ..writeString(recipient)
      ..writeOption<String>(callbackUrl, (w, v) => w.writeString(v));
    return writer.toBytes();
  }

  /// SHA-256 of [serialize] — the bytes that are actually ed25519-signed.
  Uint8List hash() => sha256Hash(serialize());
}

/// The result of signing a [Nep413Payload]: what a NEP-413 verifier expects.
class Nep413SignedMessage {
  const Nep413SignedMessage({
    required this.accountId,
    required this.publicKey,
    required this.signature,
  });

  final AccountId accountId;
  final PublicKey publicKey;

  /// Base64-encoded 64-byte ed25519 signature.
  final String signature;
}

/// Signs [payload] with [keyPair] on behalf of [accountId].
///
/// The key must be registered to the account on-chain; most verifiers
/// (including near-kit / better-near-auth) require a **full-access** key.
Future<Nep413SignedMessage> signNep413Message({
  required Nep413Payload payload,
  required KeyPairEd25519 keyPair,
  required AccountId accountId,
}) async {
  final signature = await keyPair.sign(payload.hash());
  return Nep413SignedMessage(
    accountId: accountId,
    publicKey: keyPair.publicKey,
    signature: base64Encode(signature),
  );
}

/// Generates a NEP-413 nonce: 8-byte big-endian millisecond timestamp
/// followed by 24 random bytes, so verifiers can expire old signatures.
Uint8List generateNep413Nonce({DateTime? now}) {
  final nonce = Uint8List(32);
  final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
  ByteData.sublistView(nonce, 0, 8).setUint64(0, ts);
  final rnd = Random.secure();
  for (var i = 8; i < 32; i++) {
    nonce[i] = rnd.nextInt(256);
  }
  return nonce;
}
