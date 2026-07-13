/// Edge case tests for primitive types.
///
/// Tests validation boundaries and special cases - no network calls required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('AccountId Edge Cases', () {
    group('Valid account IDs', () {
      test('rejects 1-char account (protocol minimum is 2)', () {
        expect(() => AccountId('a'), throwsArgumentError);
        expect(() => AccountId('z'), throwsArgumentError);
        expect(() => AccountId('0'), throwsArgumentError);
        expect(() => AccountId('ab'), returnsNormally);
        expect(() => AccountId('a0'), returnsNormally);
      });

      test('maximum length named account (64 chars)', () {
        final maxLength = 'a' * 64;
        expect(() => AccountId(maxLength), returnsNormally);
      });

      test('implicit account (64 hex chars)', () {
        final implicit = '0123456789abcdef' * 4; // 64 hex chars
        final account = AccountId(implicit);
        expect(account.value.length, equals(64));
      });

      test('account with all valid characters', () {
        expect(() => AccountId('a-b_c.d'), returnsNormally);
        expect(() => AccountId('test-account_123.near'), returnsNormally);
      });

      test('account with numbers', () {
        expect(() => AccountId('123'), returnsNormally);
        expect(() => AccountId('a1b2c3'), returnsNormally);
      });

      test('account with multiple dots (subaccounts)', () {
        expect(() => AccountId('sub.account.near'), returnsNormally);
        expect(() => AccountId('a.b.c.d.e'), returnsNormally);
      });

      test('account with dashes and underscores', () {
        expect(() => AccountId('my-account'), returnsNormally);
        expect(() => AccountId('my_account'), returnsNormally);
        expect(() => AccountId('my-test_account.near'), returnsNormally);
      });
    });

    group('Invalid account IDs', () {
      test('empty string throws', () {
        expect(() => AccountId(''), throwsArgumentError);
      });

      test('too long (>64 chars for non-implicit)', () {
        final tooLong = 'a' * 65;
        expect(() => AccountId(tooLong), throwsArgumentError);
      });

      test('uppercase letters throw', () {
        expect(() => AccountId('Alice'), throwsArgumentError);
        expect(() => AccountId('NEAR'), throwsArgumentError);
        expect(() => AccountId('Test.near'), throwsArgumentError);
      });

      test('special characters throw', () {
        expect(() => AccountId('test@near'), throwsArgumentError);
        expect(() => AccountId('test#near'), throwsArgumentError);
        expect(() => AccountId('test!near'), throwsArgumentError);
        expect(() => AccountId('test near'), throwsArgumentError);
      });
    });

    group('JSON serialization', () {
      test('toJson returns value', () {
        final account = AccountId('test.near');
        expect(account.toJson(), equals('test.near'));
      });

      test('fromJson creates account', () {
        final account = AccountId.fromJson('alice.testnet');
        expect(account.value, equals('alice.testnet'));
      });

      test('roundtrip preserves value', () {
        final original = AccountId('my-account.near');
        final json = original.toJson();
        final restored = AccountId.fromJson(json);
        expect(restored, equals(original));
      });
    });

    group('Equality', () {
      test('same value equals', () {
        final a1 = AccountId('test.near');
        final a2 = AccountId('test.near');
        expect(a1, equals(a2));
        expect(a1.hashCode, equals(a2.hashCode));
      });

      test('different value not equal', () {
        final a1 = AccountId('alice.near');
        final a2 = AccountId('bob.near');
        expect(a1, isNot(equals(a2)));
      });
    });
  });

  group('NearToken Edge Cases', () {
    group('Creation', () {
      test('zero token', () {
        final token = NearToken.zero();
        expect(token.yoctoNear, equals(BigInt.zero));
        expect(token.toNear(), equals(0.0));
      });

      test('one yocto token', () {
        final token = NearToken.oneYocto();
        expect(token.yoctoNear, equals(BigInt.one));
      });

      test('from 1 NEAR', () {
        final token = NearToken.fromNear(1);
        expect(
          token.yoctoNear,
          equals(BigInt.parse('1000000000000000000000000')),
        );
      });

      test('from large NEAR amount', () {
        final token = NearToken.fromNear(1000000);
        expect(token.toNear(), closeTo(1000000.0, 0.0001));
      });

      test('from yocto string', () {
        final token = NearToken.fromYocto('500000000000000000000000');
        expect(token.toNear(), closeTo(0.5, 0.0001));
      });

      test('from very large yocto value', () {
        // 1 billion NEAR
        final token = NearToken.fromYocto('1000000000000000000000000000000000');
        expect(
          token.yoctoNear.toString(),
          equals('1000000000000000000000000000000000'),
        );
      });
    });

    group('Conversions', () {
      test('toNear for fractional amounts', () {
        final token = NearToken.fromYocto('2500000000000000000000000');
        expect(token.toNear(), closeTo(2.5, 0.0001));
      });

      test('toNear for very small amounts', () {
        final token = NearToken.fromYocto('1');
        expect(token.toNear(), closeTo(1e-24, 1e-30));
      });

      test('toJson returns yoctoNear string', () {
        final token = NearToken.fromNear(5);
        expect(token.toJson(), equals('5000000000000000000000000'));
      });
    });

    group('Equality', () {
      test('same yocto amount equals', () {
        final t1 = NearToken.fromYocto('1000000000000000000000000');
        final t2 = NearToken.fromNear(1);
        expect(t1, equals(t2));
      });

      test('different amounts not equal', () {
        final t1 = NearToken.fromNear(1);
        final t2 = NearToken.fromNear(2);
        expect(t1, isNot(equals(t2)));
      });
    });

    group('toString', () {
      test('includes NEAR suffix', () {
        final token = NearToken.fromNear(5);
        expect(token.toString(), contains('NEAR'));
        expect(token.toString(), contains('5'));
      });
    });
  });

  group('CryptoHash Edge Cases', () {
    test('creates from any string', () {
      // CryptoHash doesn't validate - it accepts any string
      const hash = CryptoHash('any-string');
      expect(hash.value, equals('any-string'));
    });

    test('creates from valid base58', () {
      const hash = CryptoHash('9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f');
      expect(hash.value.length, equals(44));
    });

    test('JSON roundtrip', () {
      const hashStr = '11111111111111111111111111111111';
      const original = CryptoHash(hashStr);
      final json = original.toJson();
      final restored = CryptoHash.fromJson(json);
      expect(restored, equals(original));
    });

    test('equality', () {
      const h1 = CryptoHash('abc123');
      const h2 = CryptoHash('abc123');
      const h3 = CryptoHash('xyz789');

      expect(h1, equals(h2));
      expect(h1, isNot(equals(h3)));
    });

    test('toString returns value', () {
      const hash = CryptoHash('test-hash');
      expect(hash.toString(), equals('test-hash'));
    });
  });

  group('PublicKey Edge Cases', () {
    group('Valid keys', () {
      test('ed25519 key', () {
        const keyStr = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
        final key = PublicKey(keyStr);

        expect(key.value, equals(keyStr));
        expect(key.keyType, equals(KeyType.ed25519));
        expect(
          key.keyData,
          equals('6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );
      });

      test('secp256k1 key', () {
        const keyStr =
            'secp256k1:2Ana1pUpv2ZbMVkwF5FXapYeBEjdxDatLn7nvJkhgTSXbs59SyZSx866bXirPgj8QQVB57uxHJBG1YFvkRbFj4T';
        final key = PublicKey(keyStr);

        expect(key.keyType, equals(KeyType.secp256k1));
      });
    });

    group('Invalid keys', () {
      test('no prefix throws', () {
        expect(
          () => PublicKey('6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
          throwsArgumentError,
        );
      });

      test('unknown prefix throws', () {
        expect(() => PublicKey('rsa:abc123'), throwsArgumentError);
        expect(() => PublicKey('unknown:data'), throwsArgumentError);
      });

      test('empty string throws', () {
        expect(() => PublicKey(''), throwsArgumentError);
      });

      test('only prefix throws', () {
        expect(() => PublicKey('ed25519:'), throwsArgumentError);
      });

      test('wrong byte length throws', () {
        // valid base58, but not 32 bytes
        expect(() => PublicKey('ed25519:abc'), throwsArgumentError);
      });

      test('invalid base58 throws', () {
        // 0, O, I, l are not base58 characters
        expect(
          () => PublicKey('ed25519:0OIl0OIl0OIl0OIl0OIl0OIl0OIl0OIl'),
          throwsArgumentError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson returns value', () {
        const keyStr = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
        final key = PublicKey(keyStr);
        expect(key.toJson(), equals(keyStr));
      });

      test('fromJson creates key', () {
        const keyStr = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
        final key = PublicKey.fromJson(keyStr);
        expect(key.value, equals(keyStr));
      });
    });

    group('Equality', () {
      test('same key equals', () {
        const keyStr = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
        final k1 = PublicKey(keyStr);
        final k2 = PublicKey(keyStr);
        expect(k1, equals(k2));
      });

      test('different keys not equal', () {
        final k1 = PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        );
        final k2 = PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        );
        expect(k1, isNot(equals(k2)));
      });

      test('different types not equal', () {
        final k1 = PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        );
        final k2 = PublicKey(
          'secp256k1:2Ana1pUpv2ZbMVkwF5FXapYeBEjdxDatLn7nvJkhgTSXbs59SyZSx866bXirPgj8QQVB57uxHJBG1YFvkRbFj4T',
        );
        expect(k1, isNot(equals(k2)));
      });
    });
  });

  group('KeyType', () {
    test('has both key types', () {
      expect(KeyType.values, contains(KeyType.ed25519));
      expect(KeyType.values, contains(KeyType.secp256k1));
      expect(KeyType.values.length, equals(2));
    });
  });
}
