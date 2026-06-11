/// Unit tests for BlockReference types.
///
/// Tests pure logic - no network calls required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('Finality', () {
    test('has optimistic and final variants', () {
      expect(Finality.values, contains(Finality.optimistic));
      expect(Finality.values, contains(Finality.final_));
      expect(Finality.values.length, equals(2));
    });

    test('toJson converts optimistic', () {
      expect(Finality.optimistic.toJson(), equals('optimistic'));
    });

    test('toJson converts final_ to "final"', () {
      expect(Finality.final_.toJson(), equals('final'));
    });
  });

  group('BlockReference', () {
    group('FinalityBlockReference', () {
      test('creates from finality factory', () {
        final ref = BlockReference.finality(Finality.final_);

        expect(ref, isA<FinalityBlockReference>());
        expect(
          (ref as FinalityBlockReference).finality,
          equals(Finality.final_),
        );
      });

      test('creates optimistic reference', () {
        final ref = BlockReference.finality(Finality.optimistic);

        expect(
          (ref as FinalityBlockReference).finality,
          equals(Finality.optimistic),
        );
      });

      test('toJson for final finality', () {
        final ref = BlockReference.finality(Finality.final_);

        expect(ref.toJson(), equals({'finality': 'final'}));
      });

      test('toJson for optimistic finality', () {
        final ref = BlockReference.finality(Finality.optimistic);

        expect(ref.toJson(), equals({'finality': 'optimistic'}));
      });

      test('equality for same finality', () {
        final ref1 = BlockReference.finality(Finality.final_);
        final ref2 = BlockReference.finality(Finality.final_);

        expect(ref1, equals(ref2));
      });

      test('inequality for different finality', () {
        final ref1 = BlockReference.finality(Finality.final_);
        final ref2 = BlockReference.finality(Finality.optimistic);

        expect(ref1, isNot(equals(ref2)));
      });
    });

    group('HeightBlockReference', () {
      test('creates from blockId factory', () {
        final ref = BlockReference.blockId(12345678);

        expect(ref, isA<HeightBlockReference>());
        expect((ref as HeightBlockReference).blockHeight, equals(12345678));
      });

      test('creates with zero height', () {
        final ref = BlockReference.blockId(0);

        expect((ref as HeightBlockReference).blockHeight, equals(0));
      });

      test('creates with large height', () {
        final ref = BlockReference.blockId(999999999);

        expect((ref as HeightBlockReference).blockHeight, equals(999999999));
      });

      test('toJson includes block_id', () {
        final ref = BlockReference.blockId(42);

        expect(ref.toJson(), equals({'block_id': 42}));
      });

      test('equality for same height', () {
        final ref1 = BlockReference.blockId(100);
        final ref2 = BlockReference.blockId(100);

        expect(ref1, equals(ref2));
      });

      test('inequality for different heights', () {
        final ref1 = BlockReference.blockId(100);
        final ref2 = BlockReference.blockId(200);

        expect(ref1, isNot(equals(ref2)));
      });
    });

    group('HashBlockReference', () {
      test('creates from blockHash factory', () {
        const hash = CryptoHash('9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f');
        final ref = BlockReference.blockHash(hash);

        expect(ref, isA<HashBlockReference>());
        expect((ref as HashBlockReference).blockHash, equals(hash));
      });

      test('toJson includes block_id as hash string', () {
        const hashStr = '9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f';
        final ref = BlockReference.blockHash(const CryptoHash(hashStr));

        expect(ref.toJson(), equals({'block_id': hashStr}));
      });

      test('equality for same hash', () {
        const hash = CryptoHash('abc123');
        final ref1 = BlockReference.blockHash(hash);
        final ref2 = BlockReference.blockHash(const CryptoHash('abc123'));

        expect(ref1, equals(ref2));
      });

      test('inequality for different hashes', () {
        final ref1 = BlockReference.blockHash(const CryptoHash('hash1'));
        final ref2 = BlockReference.blockHash(const CryptoHash('hash2'));

        expect(ref1, isNot(equals(ref2)));
      });
    });

    group('Cross-type comparisons', () {
      test('different types are not equal', () {
        final finalityRef = BlockReference.finality(Finality.final_);
        final heightRef = BlockReference.blockId(100);
        final hashRef = BlockReference.blockHash(const CryptoHash('abc'));

        expect(finalityRef, isNot(equals(heightRef)));
        expect(finalityRef, isNot(equals(hashRef)));
        expect(heightRef, isNot(equals(hashRef)));
      });
    });

    group('Pattern matching', () {
      test('switch exhaustively matches finality', () {
        final ref = BlockReference.finality(Finality.final_);
        String result;

        switch (ref) {
          case FinalityBlockReference(:final finality):
            result = 'finality: ${finality.toJson()}';
          case HeightBlockReference(:final blockHeight):
            result = 'height: $blockHeight';
          case HashBlockReference(:final blockHash):
            result = 'hash: ${blockHash.value}';
        }

        expect(result, equals('finality: final'));
      });

      test('switch exhaustively matches height', () {
        final ref = BlockReference.blockId(42);
        String result;

        switch (ref) {
          case FinalityBlockReference(:final finality):
            result = 'finality: ${finality.toJson()}';
          case HeightBlockReference(:final blockHeight):
            result = 'height: $blockHeight';
          case HashBlockReference(:final blockHash):
            result = 'hash: ${blockHash.value}';
        }

        expect(result, equals('height: 42'));
      });

      test('switch exhaustively matches hash', () {
        final ref = BlockReference.blockHash(const CryptoHash('myhash'));
        String result;

        switch (ref) {
          case FinalityBlockReference(:final finality):
            result = 'finality: ${finality.toJson()}';
          case HeightBlockReference(:final blockHeight):
            result = 'height: $blockHeight';
          case HashBlockReference(:final blockHash):
            result = 'hash: ${blockHash.value}';
        }

        expect(result, equals('hash: myhash'));
      });
    });
  });
}
