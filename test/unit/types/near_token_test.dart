import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NearToken.parse (decimal NEAR string -> exact yocto)', () {
    test('parses a whole number', () {
      expect(
        NearToken.parse('1').yoctoNear,
        BigInt.parse('1000000000000000000000000'),
      );
    });

    test('parses a fractional amount exactly', () {
      expect(
        NearToken.parse('1.5').yoctoNear,
        BigInt.parse('1500000000000000000000000'),
      );
    });

    test('parses the smallest representable fraction', () {
      expect(
        NearToken.parse('0.000000000000000000000001').yoctoNear,
        BigInt.one,
      );
    });

    test('parses zero', () {
      expect(NearToken.parse('0').yoctoNear, BigInt.zero);
      expect(NearToken.parse('0.0').yoctoNear, BigInt.zero);
    });

    test('parses a large value without precision loss', () {
      // 2^53 + 1 NEAR — would lose precision as a double.
      expect(
        NearToken.parse('9007199254740993').yoctoNear,
        BigInt.parse('9007199254740993') *
            BigInt.parse('1000000000000000000000000'),
      );
    });

    test(
      'ignores a leading plus and surrounding behaviour for trailing zeros',
      () {
        expect(
          NearToken.parse('2.50').yoctoNear,
          BigInt.parse('2500000000000000000000000'),
        );
      },
    );

    test('rejects more than 24 fractional digits', () {
      expect(
        () => NearToken.parse('0.0000000000000000000000001'),
        throwsFormatException,
      );
    });

    test('rejects non-numeric input', () {
      expect(() => NearToken.parse('abc'), throwsFormatException);
      expect(() => NearToken.parse('1.2.3'), throwsFormatException);
      expect(() => NearToken.parse(''), throwsFormatException);
    });

    test('rejects negative amounts', () {
      expect(() => NearToken.parse('-1'), throwsFormatException);
    });
  });

  group('NearToken.toNearString (exact, no double)', () {
    test('formats a whole number without a fractional part', () {
      expect(NearToken.fromNear(5).toNearString(), '5');
    });

    test('formats a fractional amount and trims trailing zeros', () {
      expect(
        NearToken.fromYocto('1500000000000000000000000').toNearString(),
        '1.5',
      );
    });

    test('formats one yocto', () {
      expect(NearToken.oneYocto().toNearString(), '0.000000000000000000000001');
    });

    test('formats zero', () {
      expect(NearToken.zero().toNearString(), '0');
    });

    test('round-trips an arbitrary precise amount', () {
      const yocto = '123456789012345678901234567';
      final token = NearToken.fromYocto(yocto);
      // toNearString -> parse must return the exact same yocto value.
      expect(
        NearToken.parse(token.toNearString()).yoctoNear,
        BigInt.parse(yocto),
      );
    });

    test('supports a fixed number of fraction digits', () {
      expect(
        NearToken.fromYocto(
          '1500000000000000000000000',
        ).toNearString(fractionDigits: 2),
        '1.50',
      );
      expect(NearToken.fromNear(3).toNearString(fractionDigits: 4), '3.0000');
    });
  });

  group('NearToken arithmetic', () {
    test('adds two amounts', () {
      final sum = NearToken.fromNear(1) + NearToken.fromNear(2);
      expect(sum, NearToken.fromNear(3));
    });

    test('subtracts two amounts', () {
      final diff = NearToken.fromNear(5) - NearToken.fromYocto('1');
      expect(diff.yoctoNear, BigInt.parse('4999999999999999999999999'));
    });

    test('throws when subtraction would go negative', () {
      expect(
        () => NearToken.fromYocto('1') - NearToken.fromYocto('2'),
        throwsArgumentError,
      );
    });

    test('compares amounts', () {
      expect(NearToken.fromNear(1) < NearToken.fromNear(2), isTrue);
      expect(NearToken.fromNear(2) > NearToken.fromNear(1), isTrue);
      expect(NearToken.fromNear(1) <= NearToken.fromNear(1), isTrue);
      expect(NearToken.fromNear(1) >= NearToken.fromNear(1), isTrue);
      expect(NearToken.fromNear(1).compareTo(NearToken.fromNear(2)), -1);
    });
  });
}
