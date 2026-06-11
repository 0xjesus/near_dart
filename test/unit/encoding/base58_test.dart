import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('base58Decode', () {
    test('decodes empty string to empty bytes', () {
      expect(base58Decode(''), isEmpty);
    });

    test('decodes leading 1s as zero bytes', () {
      expect(base58Decode('111'), [0, 0, 0]);
    });

    test('decodes known bitcoin test vector', () {
      // From the canonical base58 test vectors
      expect(base58Decode('2g'), [0x61]);
      expect(base58Decode('a3gV'), [0x62, 0x62, 0x62]);
    });

    test('decodes long string vector', () {
      expect(
        base58Decode('2cFupjhnEsSn59qHXstmK2ffpLv2'),
        utf8.encode('simply a long string'),
      );
    });

    test('decodes a NEAR block hash to 32 bytes', () {
      final bytes = base58Decode(
        '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM',
      );
      expect(bytes.length, 32);
    });

    test('throws on invalid characters', () {
      expect(() => base58Decode('0OIl'), throwsFormatException);
    });
  });

  group('base58Encode', () {
    test('encodes empty bytes to empty string', () {
      expect(base58Encode([]), '');
    });

    test('encodes zero bytes as 1s', () {
      expect(base58Encode([0, 0, 0]), '111');
    });

    test('encodes known vectors', () {
      expect(base58Encode([0x61]), '2g');
      expect(base58Encode([0x62, 0x62, 0x62]), 'a3gV');
      expect(
        base58Encode(utf8.encode('simply a long string')),
        '2cFupjhnEsSn59qHXstmK2ffpLv2',
      );
    });

    test('round-trips a NEAR public key', () {
      const keyB58 = '9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj';
      expect(base58Encode(base58Decode(keyB58)), keyB58);
    });
  });
}
