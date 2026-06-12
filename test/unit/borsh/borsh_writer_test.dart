import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BorshWriter primitives', () {
    test('writes u8', () {
      final writer = BorshWriter()..writeU8(0x12);
      expect(writer.toBytes(), [0x12]);
    });

    test('writes u16 little-endian', () {
      final writer = BorshWriter()..writeU16(0x1234);
      expect(writer.toBytes(), [0x34, 0x12]);
    });

    test('writes u32 little-endian', () {
      final writer = BorshWriter()..writeU32(1);
      expect(writer.toBytes(), [1, 0, 0, 0]);
    });

    test('writes u64 little-endian', () {
      final writer = BorshWriter()..writeU64(BigInt.from(123456789));
      expect(writer.toBytes(), [0x15, 0xCD, 0x5B, 0x07, 0, 0, 0, 0]);
    });

    test('writes u64 max value', () {
      final writer = BorshWriter()
        ..writeU64(BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16));
      expect(writer.toBytes(), List.filled(8, 0xFF));
    });

    test('writes u128 little-endian (1 NEAR in yocto)', () {
      final writer = BorshWriter()
        ..writeU128(BigInt.parse('1000000000000000000000000'));
      // 10^24 = 0xD3C21BCECCEDA1000000 -> LE, padded to 16 bytes
      expect(writer.toBytes(), [
        0x00, 0x00, 0x00, 0xA1, 0xED, 0xCC, 0xCE, 0x1B, //
        0xC2, 0xD3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      ]);
    });

    test('writes string with u32 length prefix', () {
      final writer = BorshWriter()..writeString('abc');
      expect(writer.toBytes(), [3, 0, 0, 0, 0x61, 0x62, 0x63]);
    });

    test('writes utf8 string bytes', () {
      final writer = BorshWriter()..writeString('ñ');
      expect(writer.toBytes(), [2, 0, 0, 0, 0xC3, 0xB1]);
    });

    test('writes fixed bytes without length prefix', () {
      final writer = BorshWriter()..writeFixedBytes([9, 8, 7]);
      expect(writer.toBytes(), [9, 8, 7]);
    });

    test('writes vec of bytes with u32 length prefix', () {
      final writer = BorshWriter()..writeBytes([9, 8, 7]);
      expect(writer.toBytes(), [3, 0, 0, 0, 9, 8, 7]);
    });

    test('writes option none as 0 byte', () {
      final writer = BorshWriter()
        ..writeOption<int>(null, (w, v) => w.writeU8(v));
      expect(writer.toBytes(), [0]);
    });

    test('writes option some as 1 byte plus value', () {
      final writer = BorshWriter()..writeOption<int>(5, (w, v) => w.writeU8(v));
      expect(writer.toBytes(), [1, 5]);
    });

    test('writes vec of strings', () {
      final writer = BorshWriter()
        ..writeVec<String>(['m1', 'm2'], (w, v) => w.writeString(v));
      expect(writer.toBytes(), [
        2, 0, 0, 0, // vec length
        2, 0, 0, 0, 0x6D, 0x31, // "m1"
        2, 0, 0, 0, 0x6D, 0x32, // "m2"
      ]);
    });

    test('concatenates sequential writes', () {
      final writer = BorshWriter()
        ..writeU8(1)
        ..writeU32(2);
      expect(writer.toBytes(), [1, 2, 0, 0, 0]);
    });

    test('rejects negative u64', () {
      expect(
        () => BorshWriter().writeU64(BigInt.from(-1)),
        throwsArgumentError,
      );
    });

    test('rejects u128 overflow', () {
      expect(
        () => BorshWriter().writeU128(BigInt.two.pow(128)),
        throwsArgumentError,
      );
    });
  });
}
