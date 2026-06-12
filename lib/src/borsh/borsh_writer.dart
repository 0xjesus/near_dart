import 'dart:convert';
import 'dart:typed_data';

/// A writer for Borsh binary serialization.
///
/// Borsh (Binary Object Representation Serializer for Hashing) is the
/// serialization format used by NEAR Protocol for transactions.
/// All integers are little-endian. See https://borsh.io.
class BorshWriter {
  final BytesBuilder _builder = BytesBuilder();

  static final BigInt _maxU64 = BigInt.two.pow(64) - BigInt.one;
  static final BigInt _maxU128 = BigInt.two.pow(128) - BigInt.one;

  /// Writes a single unsigned byte.
  void writeU8(int value) {
    RangeError.checkValueInInterval(value, 0, 0xFF, 'value');
    _builder.addByte(value);
  }

  /// Writes an unsigned 16-bit integer (little-endian).
  void writeU16(int value) {
    RangeError.checkValueInInterval(value, 0, 0xFFFF, 'value');
    _builder.addByte(value & 0xFF);
    _builder.addByte((value >> 8) & 0xFF);
  }

  /// Writes an unsigned 32-bit integer (little-endian).
  void writeU32(int value) {
    RangeError.checkValueInInterval(value, 0, 0xFFFFFFFF, 'value');
    for (var i = 0; i < 4; i++) {
      _builder.addByte((value >> (8 * i)) & 0xFF);
    }
  }

  /// Writes an unsigned 64-bit integer (little-endian).
  void writeU64(BigInt value) => _writeUnsigned(value, 8, _maxU64);

  /// Writes an unsigned 128-bit integer (little-endian).
  void writeU128(BigInt value) => _writeUnsigned(value, 16, _maxU128);

  void _writeUnsigned(BigInt value, int byteLength, BigInt max) {
    if (value.isNegative || value > max) {
      throw ArgumentError.value(
        value,
        'value',
        'Must be an unsigned integer that fits in $byteLength bytes',
      );
    }
    final mask = BigInt.from(0xFF);
    var remaining = value;
    for (var i = 0; i < byteLength; i++) {
      _builder.addByte((remaining & mask).toInt());
      remaining = remaining >> 8;
    }
  }

  /// Writes a UTF-8 string with a u32 length prefix.
  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeU32(bytes.length);
    _builder.add(bytes);
  }

  /// Writes raw bytes without a length prefix (fixed-size arrays).
  void writeFixedBytes(List<int> bytes) {
    _builder.add(bytes);
  }

  /// Writes bytes with a u32 length prefix (`Vec<u8>`).
  void writeBytes(List<int> bytes) {
    writeU32(bytes.length);
    _builder.add(bytes);
  }

  /// Writes an optional value: 0 byte for none, 1 byte plus value for some.
  void writeOption<T>(T? value, void Function(BorshWriter, T) writeValue) {
    if (value == null) {
      writeU8(0);
    } else {
      writeU8(1);
      writeValue(this, value);
    }
  }

  /// Writes a `Vec<T>` with a u32 length prefix.
  void writeVec<T>(List<T> values, void Function(BorshWriter, T) writeValue) {
    writeU32(values.length);
    for (final value in values) {
      writeValue(this, value);
    }
  }

  /// Returns the serialized bytes.
  Uint8List toBytes() => _builder.toBytes();
}
