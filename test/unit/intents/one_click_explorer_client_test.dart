import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OneClickExplorerClient', () {
    test(
      'fetches transactions with bearer auth and repeated filters',
      () async {
        final client = OneClickExplorerClient(
          auth: OneClickAuth.bearerToken('jwt'),
          httpClient: MockClient((request) async {
            expect(request.method, 'GET');
            expect(
              request.url.toString(),
              startsWith(
                'https://explorer.near-intents.org/api/v0/transactions',
              ),
            );
            expect(request.headers['Authorization'], 'Bearer jwt');
            expect(request.url.queryParameters['numberOfTransactions'], '25');
            expect(request.url.queryParameters['direction'], 'prev');
            expect(request.url.queryParametersAll['fromChainId'], [
              'near',
              'eth',
            ]);
            expect(request.url.queryParametersAll['toTokenId'], [
              'nep141:usdc.near',
              'nep141:wrap.near',
            ]);
            expect(request.url.queryParameters['statuses'], 'SUCCESS,REFUNDED');
            expect(request.url.queryParameters['showTestTxs'], 'true');
            expect(
              request.url.queryParameters['startTimestamp'],
              '2026-07-01T00:00:00.000Z',
            );
            return http.Response(
              jsonEncode([
                {
                  'originAsset': 'nep141:wrap.near',
                  'destinationAsset': 'nep141:usdc.near',
                  'depositAddress': 'deposit-address',
                  'depositMemo': 'memo-1',
                  'depositAddressAndMemo': 'deposit-address_memo-1',
                  'recipient': 'alice.near',
                  'status': 'SUCCESS',
                  'createdAt': '2026-07-06T12:00:00.000Z',
                  'createdAtTimestamp': 1783339200,
                  'intentHashes': 'intent-hash',
                  'referral': 'nearcoffee',
                  'amountInFormatted': '0.1',
                  'amountOutFormatted': '0.24',
                  'appFees': [
                    {'recipient': 'nearcoffee.near', 'fee': 25},
                  ],
                  'nearTxHashes': ['near-tx'],
                  'originChainTxHashes': ['origin-tx'],
                  'destinationChainTxHashes': ['destination-tx'],
                  'amountIn': '100000000000000000000000',
                  'amountInUsd': '0.25',
                  'amountOut': '240000',
                  'amountOutUsd': '0.24',
                  'refundTo': 'alice.near',
                  'senders': ['alice.near'],
                  'refundFeeFormatted': '0.001',
                  'depositType': 'ORIGIN_CHAIN',
                  'recipientType': 'INTENTS',
                  'refundType': 'ORIGIN_CHAIN',
                  'refundReason': null,
                  'refundFee': null,
                },
              ]),
              200,
            );
          }),
        );

        final txs = await client.transactions(
          OneClickExplorerTransactionsRequest(
            numberOfTransactions: 25,
            direction: OneClickExplorerDirection.prev,
            fromChainIds: const ['near', 'eth'],
            toTokenIds: const ['nep141:usdc.near', 'nep141:wrap.near'],
            statuses: const [
              OneClickStatusKind.success,
              OneClickStatusKind.refunded,
            ],
            showTestTxs: true,
            startTimestamp: DateTime.utc(2026, 7),
          ),
        );

        expect(txs.single.originAsset, 'nep141:wrap.near');
        expect(txs.single.statusKind, OneClickStatusKind.success);
        expect(txs.single.createdAt, DateTime.utc(2026, 7, 6, 12));
        expect(txs.single.appFees.single.recipient, 'nearcoffee.near');
        expect(txs.single.depositType, OneClickDepositType.originChain);
        expect(txs.single.recipientType, OneClickRecipientType.intents);
        expect(txs.single.nearTxHashes, ['near-tx']);
      },
    );

    test('validates page size and throws typed API errors', () async {
      expect(
        () => OneClickExplorerTransactionsRequest(numberOfTransactions: 0),
        throwsArgumentError,
      );

      final client = OneClickExplorerClient(
        httpClient: MockClient((_) async => http.Response('rate limited', 429)),
      );

      await expectLater(
        client.transactions(),
        throwsA(
          isA<OneClickExplorerApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.body, 'body', 'rate limited'),
        ),
      );
    });
  });
}
