import 'dart:typed_data';

import 'package:near_dart/near_dart.dart';

Future<void> main() async {
  final key = await KeyPairEd25519.fromSeed(Uint8List(32));
  final message = Uint8List.fromList(const [1, 2, 3]);
  final signature = await key.sign(message);
  if (signature.length != 64) throw StateError('Invalid ed25519 signature');
  if (!await verifySignature(
    message: message,
    signature: signature,
    publicKey: key.publicKey,
  )) {
    throw StateError('Valid ed25519 signature was rejected');
  }

  final identity = <int>[1, ...List<int>.filled(31, 0)];
  if (await verifySignature(
    message: message,
    signature: [...identity, ...List<int>.filled(32, 0)],
    publicKey: key.publicKey,
  )) {
    throw StateError('Weak ed25519 signature was accepted');
  }
}
