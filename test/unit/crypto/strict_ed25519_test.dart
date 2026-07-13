import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

final BigInt _ed25519Order =
    (BigInt.one << 252) +
    BigInt.parse('27742317777372353535851937790883648493');

final Map<String, List<int>> _rejectedPoints = {
  'zero point': List<int>.filled(32, 0),
  'identity': [1, ...List<int>.filled(31, 0)],
  'order-2 point': [0xec, ...List<int>.filled(30, 0xff), 0x7f],
  'order-8 point': _hex(
    '26e8958fc2b227b045c3f489f2ef98f0'
    'd5dfac05d3c63339b13802886d53fc05',
  ),
  'other order-8 point': _hex(
    'c7176a703d4dd84fba3c0b760d10670f'
    '2a2053fa2c39ccc64ce5213b4c0f037a',
  ),
  'noncanonical y': [0xed, ...List<int>.filled(30, 0xff), 0x7f],
  'noncanonical identity': [1, ...List<int>.filled(30, 0), 0x80],
  'mixed-order point': _hex(
    '16a567fe7d4ef5482ab4012c369bf8c5'
    'f11e8d0c2559dcda50fde59708f8aee5',
  ),
};

void main() {
  group('strict Ed25519 public keys', () {
    for (final vector in _rejectedPoints.entries) {
      test('PublicKey rejects ${vector.key}', () {
        expect(
          () => PublicKey('ed25519:${base58Encode(vector.value)}'),
          throwsArgumentError,
        );
      });
    }

    test('verifySignature rejects the identity universal forgery', () async {
      final identity = _rejectedPoints['identity']!;
      final forgedSignature = [...identity, ...List<int>.filled(32, 0)];
      final uncheckedIdentity = _UncheckedPublicKey(
        'ed25519:${base58Encode(identity)}',
      );

      expect(
        await verifySignature(
          message: utf8.encode('any message is accepted by the weak backend'),
          signature: forgedSignature,
          publicKey: uncheckedIdentity,
        ),
        isFalse,
      );
    });

    for (final vector in {
      ..._rejectedPoints,
      '31-byte encoding': List<int>.filled(31, 7),
      '33-byte encoding': List<int>.filled(33, 7),
    }.entries) {
      test('verifySignature returns false for ${vector.key} A', () async {
        final uncheckedKey = _UncheckedPublicKey(
          'ed25519:${base58Encode(vector.value)}',
        );

        expect(
          await verifySignature(
            message: const [1, 2, 3],
            signature: List<int>.filled(64, 0),
            publicKey: uncheckedKey,
          ),
          isFalse,
        );
      });
    }

    test('verifySignature returns false for malformed base58 A', () async {
      expect(
        await verifySignature(
          message: const [1, 2, 3],
          signature: List<int>.filled(64, 0),
          publicKey: const _UncheckedPublicKey('ed25519:0OIl'),
        ),
        isFalse,
      );
    });
  });

  group('strict Ed25519 signatures', () {
    final publicKeyBytes = _hex(
      'd75a980182b10ab7d54bfed3c964073a'
      '0ee172f3daa62325af021a68f707511a',
    );
    final publicKey = PublicKey('ed25519:${base58Encode(publicKeyBytes)}');
    final validSignature = _hex(
      'e5564300c360ac729086e2cc806e828a'
      '84877f1eb8e5d974d873e06522490155'
      '5fb8821590a33bacc61e39701cf9b46b'
      'd25bf5f0595bbe24655141438e7a100b',
    );

    test('accepts RFC 8032 test vector 1', () async {
      expect(
        await verifySignature(
          message: const [],
          signature: validSignature,
          publicKey: publicKey,
        ),
        isTrue,
      );
    });

    for (final length in [0, 1, 31, 32, 63, 65]) {
      test('returns false for a $length-byte signature', () async {
        expect(
          await verifySignature(
            message: const [],
            signature: List<int>.filled(length, 0),
            publicKey: publicKey,
          ),
          isFalse,
        );
      });
    }

    for (final vector in _rejectedPoints.entries) {
      test('returns false for ${vector.key} R', () async {
        expect(
          await verifySignature(
            message: const [],
            signature: [...vector.value, ...List<int>.filled(32, 0)],
            publicKey: publicKey,
          ),
          isFalse,
        );
      });
    }

    final validR = validSignature.sublist(0, 32);
    final validS = _decodeLittleEndian(validSignature.sublist(32));
    final scalars = {
      'S = L': _ed25519Order,
      'S = L + 1': _ed25519Order + BigInt.one,
      'valid S + L': validS + _ed25519Order,
    };
    for (final vector in scalars.entries) {
      test('returns false for ${vector.key}', () async {
        expect(
          await verifySignature(
            message: const [],
            signature: [...validR, ..._encodeLittleEndian(vector.value, 32)],
            publicKey: publicKey,
          ),
          isFalse,
        );
      });
    }
  });
}

class _UncheckedPublicKey extends Equatable implements PublicKey {
  const _UncheckedPublicKey(this.value);

  @override
  final String value;

  @override
  KeyType get keyType => KeyType.ed25519;

  @override
  String get keyData => value.substring(value.indexOf(':') + 1);

  @override
  String toJson() => value;

  @override
  List<Object?> get props => [value];
}

List<int> _hex(String value) {
  if (value.length.isOdd) throw ArgumentError.value(value, 'value');
  return [
    for (var i = 0; i < value.length; i += 2)
      int.parse(value.substring(i, i + 2), radix: 16),
  ];
}

BigInt _decodeLittleEndian(List<int> bytes) {
  var value = BigInt.zero;
  for (var i = bytes.length - 1; i >= 0; i--) {
    value = (value << 8) | BigInt.from(bytes[i]);
  }
  return value;
}

List<int> _encodeLittleEndian(BigInt value, int length) {
  final bytes = List<int>.filled(length, 0);
  var remaining = value;
  for (var i = 0; i < length; i++) {
    bytes[i] = (remaining & BigInt.from(0xff)).toInt();
    remaining >>= 8;
  }
  if (remaining != BigInt.zero) {
    throw ArgumentError.value(value, 'value', 'does not fit in $length bytes');
  }
  return bytes;
}
