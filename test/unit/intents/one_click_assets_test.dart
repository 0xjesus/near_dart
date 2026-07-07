import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OneClickAssetId', () {
    test('parses standard and reference', () {
      final id = OneClickAssetId.parse('nep141:wrap.near');

      expect(id.standard, 'nep141');
      expect(id.reference, 'wrap.near');
      expect(id.isNep141, isTrue);
      expect(id.toString(), 'nep141:wrap.near');
    });

    test('rejects malformed asset ids', () {
      expect(() => OneClickAssetId.parse('wrap.near'), throwsFormatException);
      expect(() => OneClickAssetId.parse(':wrap.near'), throwsFormatException);
      expect(() => OneClickAssetId.parse('nep141:'), throwsFormatException);
    });
  });

  group('OneClickAmount', () {
    test('converts user decimals into smallest-unit strings exactly', () {
      expect(OneClickAmount.parseDecimal('1.25', 6), '1250000');
      expect(OneClickAmount.parseDecimal('.5', 6), '500000');
      expect(OneClickAmount.parseDecimal('0001.2300', 4), '12300');
      expect(OneClickAmount.parseDecimal('0', 24), '0');
    });

    test('formats smallest-unit strings for display without float math', () {
      expect(OneClickAmount.formatSmallestUnit('1250000', 6), '1.25');
      expect(OneClickAmount.formatSmallestUnit('1000000', 6), '1');
      expect(
        OneClickAmount.formatSmallestUnit('123456789', 6, maxFractionDigits: 2),
        '123.45',
      );
      expect(
        OneClickAmount.formatSmallestUnit(
          '123400',
          6,
          trimTrailingZeros: false,
        ),
        '0.123400',
      );
    });

    test('rejects unsafe or imprecise amount input', () {
      expect(() => OneClickAmount.parseDecimal('', 6), throwsFormatException);
      expect(() => OneClickAmount.parseDecimal('-1', 6), throwsFormatException);
      expect(
        () => OneClickAmount.parseDecimal('1.0000001', 6),
        throwsFormatException,
      );
      expect(
        () => OneClickAmount.formatSmallestUnit('12.3', 6),
        throwsFormatException,
      );
    });
  });

  group('OneClickAssetCatalog', () {
    test('loads tokens once, searches locally, and can refresh', () async {
      var calls = 0;
      final catalog = OneClickAssetCatalog(
        client: OneClickClient(
          httpClient: MockClient((request) async {
            calls++;
            return http.Response(
              jsonEncode([
                {
                  'assetId': 'nep141:wrap.near',
                  'decimals': 24,
                  'blockchain': 'near',
                  'symbol': 'wNEAR',
                  'contractAddress': 'wrap.near',
                },
                {
                  'assetId': 'nep141:usdc.near',
                  'decimals': 6,
                  'blockchain': 'near',
                  'symbol': 'USDC',
                  'contractAddress': 'usdc.near',
                },
              ]),
              200,
            );
          }),
        ),
      );

      final tokens = await catalog.load();
      final cached = await catalog.load();
      final byAsset = await catalog.requireByAssetId('nep141:wrap.near');
      final search = await catalog.search(query: 'usd', blockchain: 'near');
      final refreshed = await catalog.load(refresh: true);

      expect(tokens, same(cached));
      expect(byAsset.symbol, 'wNEAR');
      expect(search.single.assetId, 'nep141:usdc.near');
      expect(refreshed, isNot(same(tokens)));
      expect(calls, 2);
    });

    test('throws a useful error when a required token is absent', () async {
      final catalog = OneClickAssetCatalog(
        client: OneClickClient(
          httpClient: MockClient((_) async => http.Response('[]', 200)),
        ),
      );

      expect(
        () => catalog.requireByAssetId('nep141:missing.near'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
