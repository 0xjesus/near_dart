import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('CryptoHash', () {
    test('creates from valid base58 string', () {
      // Valid 32-byte hash in base58
      const validHash = '11111111111111111111111111111111';
      const hash = CryptoHash(validHash);

      expect(hash.value, equals(validHash));
    });

    test('serializes to string in JSON', () {
      const hashStr = '9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f';
      const hash = CryptoHash(hashStr);

      expect(hash.toJson(), equals(hashStr));
    });

    test('deserializes from JSON string', () {
      const hashStr = '9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f';
      final hash = CryptoHash.fromJson(hashStr);

      expect(hash.value, equals(hashStr));
    });

    test('two hashes with same value are equal', () {
      const hashStr = '11111111111111111111111111111111';
      const hash1 = CryptoHash(hashStr);
      const hash2 = CryptoHash(hashStr);

      expect(hash1, equals(hash2));
    });
  });

  group('AccountId', () {
    test('creates from valid account id', () {
      final account = AccountId('alice.near');
      expect(account.value, equals('alice.near'));
    });

    test('creates from implicit account (64 hex chars)', () {
      final implicitAccount = AccountId(
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      );
      expect(implicitAccount.value.length, equals(64));
    });

    test('serializes to string in JSON', () {
      final account = AccountId('bob.testnet');
      expect(account.toJson(), equals('bob.testnet'));
    });

    test('deserializes from JSON string', () {
      final account = AccountId.fromJson('carol.near');
      expect(account.value, equals('carol.near'));
    });

    test('validates basic account id format', () {
      // Valid accounts
      expect(() => AccountId('a'), returnsNormally);
      expect(() => AccountId('alice'), returnsNormally);
      expect(() => AccountId('alice.near'), returnsNormally);
      expect(() => AccountId('a-b_c.near'), returnsNormally);

      // Invalid: empty
      expect(() => AccountId(''), throwsArgumentError);

      // Invalid: too long (>64 chars for non-implicit)
      expect(() => AccountId('a' * 65), throwsArgumentError);
    });
  });

  group('NearToken', () {
    test('creates from yoctoNEAR string', () {
      final token = NearToken.fromYocto('1000000000000000000000000');
      expect(
        token.yoctoNear,
        equals(BigInt.parse('1000000000000000000000000')),
      );
    });

    test('creates from NEAR amount', () {
      final token = NearToken.fromNear(1);
      // 1 NEAR = 10^24 yoctoNEAR
      expect(
        token.yoctoNear,
        equals(BigInt.parse('1000000000000000000000000')),
      );
    });

    test('converts to NEAR', () {
      final token = NearToken.fromYocto('2500000000000000000000000');
      // Use closeTo for floating point comparison
      expect(token.toNear(), closeTo(2.5, 0.0001));
    });

    test('serializes to yoctoNEAR string in JSON', () {
      final token = NearToken.fromNear(1);
      expect(token.toJson(), equals('1000000000000000000000000'));
    });

    test('deserializes from JSON string', () {
      final token = NearToken.fromJson('5000000000000000000000000');
      // Use closeTo for floating point comparison
      expect(token.toNear(), closeTo(5.0, 0.0001));
    });

    test('handles zero correctly', () {
      final token = NearToken.zero();
      expect(token.yoctoNear, equals(BigInt.zero));
      expect(token.toNear(), equals(0.0));
    });

    test('two tokens with same value are equal', () {
      final token1 = NearToken.fromNear(10);
      final token2 = NearToken.fromYocto('10000000000000000000000000');

      expect(token1, equals(token2));
    });
  });

  group('PublicKey', () {
    test('creates ed25519 public key', () {
      const keyStr = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
      final key = PublicKey(keyStr);

      expect(key.value, equals(keyStr));
      expect(key.keyType, equals(KeyType.ed25519));
    });

    test('creates secp256k1 public key', () {
      const keyStr =
          'secp256k1:5ftgm7wYK5gtVqq1kxMGy7gSudkrfYCbpsjL6sH1nwx2oj5NtSXqg6EYgAAeL';
      final key = PublicKey(keyStr);

      expect(key.keyType, equals(KeyType.secp256k1));
    });

    test('serializes to string in JSON', () {
      const keyStr = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
      final key = PublicKey(keyStr);

      expect(key.toJson(), equals(keyStr));
    });

    test('throws on invalid key format', () {
      expect(() => PublicKey('invalid_key'), throwsArgumentError);
      expect(() => PublicKey('unknown:12345'), throwsArgumentError);
    });
  });

  group('BlockReference', () {
    test('creates finality reference', () {
      final ref = BlockReference.finality(Finality.final_);

      expect(ref.toJson(), equals({'finality': 'final'}));
    });

    test('creates optimistic finality reference', () {
      final ref = BlockReference.finality(Finality.optimistic);

      expect(ref.toJson(), equals({'finality': 'optimistic'}));
    });

    test('creates block height reference', () {
      final ref = BlockReference.blockId(12345678);

      expect(ref.toJson(), equals({'block_id': 12345678}));
    });

    test('creates block hash reference', () {
      const hash = '9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f';
      final ref = BlockReference.blockHash(const CryptoHash(hash));

      expect(ref.toJson(), equals({'block_id': hash}));
    });
  });
}
