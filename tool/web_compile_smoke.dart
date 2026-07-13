import 'dart:typed_data';

import 'package:near_dart/near_dart.dart';

Future<void> main() async {
  final key = await KeyPairEd25519.fromSeed(Uint8List(32));
  final signature = await key.sign(Uint8List.fromList(const [1, 2, 3]));
  if (signature.length != 64) throw StateError('Invalid ed25519 signature');
}
