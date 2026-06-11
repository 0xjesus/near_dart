import 'dart:typed_data';

/// The base58 alphabet used by Bitcoin and NEAR.
const String _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

final Map<int, int> _charToIndex = {
  for (var i = 0; i < _alphabet.length; i++) _alphabet.codeUnitAt(i): i,
};

/// Decodes a base58 string into bytes.
///
/// Throws [FormatException] if [input] contains characters outside the
/// base58 alphabet.
Uint8List base58Decode(String input) {
  if (input.isEmpty) return Uint8List(0);

  var value = BigInt.zero;
  final base = BigInt.from(58);
  for (final codeUnit in input.codeUnits) {
    final digit = _charToIndex[codeUnit];
    if (digit == null) {
      throw FormatException(
        'Invalid base58 character: ${String.fromCharCode(codeUnit)}',
        input,
      );
    }
    value = value * base + BigInt.from(digit);
  }

  // Count leading '1's (zero bytes).
  var leadingZeros = 0;
  while (leadingZeros < input.length && input[leadingZeros] == '1') {
    leadingZeros++;
  }

  final bytes = <int>[];
  final mask = BigInt.from(0xFF);
  while (value > BigInt.zero) {
    bytes.add((value & mask).toInt());
    value = value >> 8;
  }

  return Uint8List.fromList([
    ...List.filled(leadingZeros, 0),
    ...bytes.reversed,
  ]);
}

/// Encodes bytes into a base58 string.
String base58Encode(List<int> bytes) {
  if (bytes.isEmpty) return '';

  var value = BigInt.zero;
  for (final byte in bytes) {
    value = (value << 8) + BigInt.from(byte & 0xFF);
  }

  final base = BigInt.from(58);
  final buffer = StringBuffer();
  while (value > BigInt.zero) {
    final remainder = (value % base).toInt();
    buffer.write(_alphabet[remainder]);
    value = value ~/ base;
  }

  // Leading zero bytes become leading '1's.
  var leadingZeros = 0;
  while (leadingZeros < bytes.length && bytes[leadingZeros] == 0) {
    leadingZeros++;
  }

  return '1' * leadingZeros + buffer.toString().split('').reversed.join();
}
