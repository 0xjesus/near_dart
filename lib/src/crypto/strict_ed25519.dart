import 'dart:typed_data';

import 'package:edwards25519/edwards25519.dart' as edwards;

final BigInt _groupOrder =
    (BigInt.one << 252) +
    BigInt.parse('27742317777372353535851937790883648493');

/// Returns whether [encoding] is a canonical, non-identity Ed25519 point in
/// the prime-order subgroup.
bool isStrictEd25519Point(List<int> encoding) {
  if (encoding.length != 32) return false;

  try {
    final point = edwards.Point.zero()..setBytes(Uint8List.fromList(encoding));
    if (!_bytesEqual(point.Bytes(), encoding)) return false;
    if (point.equal(edwards.Point.identity) == 1) return false;
    return _multiplyByGroupOrder(point).equal(edwards.Point.identity) == 1;
  } catch (_) {
    return false;
  }
}

/// Returns whether [scalar] is the canonical Ed25519 scalar encoding.
bool isCanonicalEd25519Scalar(List<int> scalar) {
  if (scalar.length != 32) return false;
  return _decodeLittleEndian(scalar) < _groupOrder;
}

edwards.Point _multiplyByGroupOrder(edwards.Point point) {
  var scalar = _groupOrder;
  final result = edwards.Point.newIdentityPoint();
  final addend = edwards.Point.zero()..set(point);

  while (scalar > BigInt.zero) {
    if ((scalar & BigInt.one) == BigInt.one) {
      result.add(result, addend);
    }
    scalar >>= 1;
    if (scalar > BigInt.zero) {
      addend.add(addend, addend);
    }
  }
  return result;
}

BigInt _decodeLittleEndian(List<int> bytes) {
  var value = BigInt.zero;
  for (var index = bytes.length - 1; index >= 0; index--) {
    value = (value << 8) | BigInt.from(bytes[index]);
  }
  return value;
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
