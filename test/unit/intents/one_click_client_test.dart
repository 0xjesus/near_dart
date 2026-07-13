import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OneClickClient', () {
    test('fetches supported tokens with API key auth', () async {
      final client = OneClickClient(
        auth: OneClickAuth.xApiKey('partner-key'),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://1click.chaindefuser.com/v0/tokens',
          );
          expect(request.headers['X-API-Key'], 'partner-key');
          return http.Response(
            jsonEncode([
              {
                'assetId': 'nep141:wrap.near',
                'decimals': 24,
                'blockchain': 'near',
                'symbol': 'wNEAR',
                'price': 2.5,
                'priceUpdatedAt': '2026-02-27T15:18:30.437Z',
                'contractAddress': 'wrap.near',
              },
            ]),
            200,
          );
        }),
      );

      final tokens = await client.tokens();

      expect(tokens, hasLength(1));
      expect(tokens.single.assetId, 'nep141:wrap.near');
      expect(tokens.single.decimals, 24);
      expect(tokens.single.price, 2.5);
      expect(tokens.single.priceUpdatedAt, isNotNull);
    });

    test(
      'posts typed quote requests and parses full quote responses',
      () async {
        late Map<String, dynamic> body;
        final client = OneClickClient(
          httpClient: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/v0/quote');
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'timestamp': '2026-07-06T12:00:01.000Z',
                'signature': 'sig',
                'quoteRequest': {'dry': true},
                'quote': {
                  'depositAddress': 'near-intents-deposit-address',
                  'depositMemo': 'memo-1',
                  'amountIn': '1000',
                  'amountInFormatted': '0.000000000000000000001',
                  'amountOut': '990',
                  'amountOutFormatted': '0.99',
                  'timeEstimate': 30,
                  'deadline': '2026-07-06T12:05:00.000Z',
                  'chainDepositAddresses': [
                    {
                      'blockchain': 'near',
                      'address': 'near-intents-deposit-address',
                      'memo': 'memo-1',
                    },
                  ],
                },
                'correlationId': 'cid-1',
              }),
              200,
            );
          }),
        );

        final response = await client.quote(
          OneClickQuoteRequest(
            dry: true,
            swapType: OneClickSwapType.exactInput,
            slippageTolerance: 50,
            originAsset: 'nep141:wrap.near',
            depositType: OneClickDepositType.originChain,
            destinationAsset: 'nep141:usdc.near',
            amount: '1000',
            refundTo: 'alice.near',
            refundType: OneClickRefundType.originChain,
            recipient: 'bob.near',
            recipientType: OneClickRecipientType.intents,
            deadline: DateTime.utc(2026, 7, 6, 12, 5),
            depositMode: OneClickDepositMode.memo,
            appFees: const [
              OneClickAppFee(recipient: 'affiliate.near', fee: 10),
            ],
            rebates: const [OneClickRebate(recipient: 'rebate.near', share: 1)],
          ),
        );

        expect(body['dry'], isTrue);
        expect(body['swapType'], 'EXACT_INPUT');
        expect(body['slippageTolerance'], 50);
        expect(body['originAsset'], 'nep141:wrap.near');
        expect(body['depositType'], 'ORIGIN_CHAIN');
        expect(body['destinationAsset'], 'nep141:usdc.near');
        expect(body['recipientType'], 'INTENTS');
        expect(body['deadline'], '2026-07-06T12:05:00.000Z');
        expect(body['depositMode'], 'MEMO');
        expect(body['appFees'].single['fee'], 10);
        expect(body['rebates'].single['recipient'], 'rebate.near');
        expect(response.correlationId, 'cid-1');
        expect(response.quote.depositAddress, 'near-intents-deposit-address');
        expect(response.quote.depositMemo, 'memo-1');
        expect(response.quote.amountOut, '990');
        expect(response.quote.chainDepositAddresses.single.memo, 'memo-1');
      },
    );

    test('submits deposit hashes with optional NEAR metadata', () async {
      late Map<String, dynamic> body;
      final client = OneClickClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v0/deposit/submit');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }),
      );

      await client.submitDeposit(
        depositAddress: 'deposit-address',
        txHash: '0xabc',
        nearSenderAccount: 'alice.near',
        memo: 'memo-1',
      );

      expect(body, {
        'depositAddress': 'deposit-address',
        'txHash': '0xabc',
        'nearSenderAccount': 'alice.near',
        'memo': 'memo-1',
      });
    });

    test('checks status with deposit memo and parses swap details', () async {
      final client = OneClickClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v0/status');
          expect(
            request.url.queryParameters['depositAddress'],
            'deposit-address',
          );
          expect(request.url.queryParameters['depositMemo'], 'memo-1');
          return http.Response(
            jsonEncode({
              'correlationId': 'cid-1',
              'status': 'SUCCESS',
              'updatedAt': '2026-07-06T12:01:00.000Z',
              'swapDetails': {
                'intentHashes': ['ih'],
                'nearTxHashes': ['near-tx'],
                'originChainTxHashes': [
                  {'hash': '0xabc', 'explorerUrl': 'https://explorer/0xabc'},
                ],
                'amountOut': '990',
              },
            }),
            200,
          );
        }),
      );

      final status = await client.status(
        depositAddress: 'deposit-address',
        depositMemo: 'memo-1',
      );

      expect(status.correlationId, 'cid-1');
      expect(status.status, 'SUCCESS');
      expect(status.kind, OneClickStatusKind.success);
      expect(status.swapDetails!.intentHashes, ['ih']);
      expect(status.swapDetails!.originChainTxHashes.single.hash, '0xabc');
      expect(status.swapDetails!.amountOut, '990');
    });

    test('generates and submits signed intents with bearer auth', () async {
      final nonce = base64Encode(List<int>.filled(32, 7));
      final requests = <http.Request>[];
      final client = OneClickClient(
        auth: OneClickAuth.bearerToken('jwt'),
        httpClient: MockClient((request) async {
          requests.add(request);
          expect(request.headers['Authorization'], 'Bearer jwt');
          if (request.url.path == '/v0/generate-intent') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['type'], 'swap_transfer');
            expect(body['depositAddress'], 'deposit-address');
            expect(body['signerId'], 'alice.near');
            expect(body['standard'], 'nep413');
            return http.Response(
              jsonEncode({
                'correlationId': 'cid-1',
                'intent': {
                  'standard': 'nep413',
                  'payload': {
                    'message': 'Sign this intent',
                    'nonce': nonce,
                    'recipient': 'intents.near',
                    'callbackUrl': 'nearcoffee://callback',
                  },
                },
              }),
              200,
            );
          }

          expect(request.url.path, '/v0/submit-intent');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['type'], 'swap_transfer');
          expect(body['signedData']['standard'], 'nep413');
          expect(body['signedData']['public_key'], startsWith('ed25519:'));
          return http.Response(
            jsonEncode({'correlationId': 'cid-2', 'intentHash': 'intent-hash'}),
            200,
          );
        }),
      );

      final generated = await client.generateIntent(
        depositAddress: 'deposit-address',
        signerId: 'alice.near',
        standard: IntentSigningStandard.nep413,
      );
      final payload = generated.asNep413Payload();
      final submitted = await client.submitIntent(
        type: 'swap_transfer',
        signedData: SignedMultiPayload.fromNep413(
          generated: generated,
          signed: Nep413SignedMessage(
            accountId: AccountId('alice.near'),
            publicKey: PublicKey(
              'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
            ),
            signature: 'sig',
          ),
        ),
      );

      expect(requests, hasLength(2));
      expect(generated.correlationId, 'cid-1');
      expect(generated.standard, IntentSigningStandard.nep413);
      expect(payload.message, 'Sign this intent');
      expect(payload.nonce, List<int>.filled(32, 7));
      expect(payload.recipient, 'intents.near');
      expect(payload.callbackUrl, 'nearcoffee://callback');
      expect(submitted.correlationId, 'cid-2');
      expect(submitted.intentHash, 'intent-hash');
    });

    test('fetches ANY_INPUT withdrawals', () async {
      final client = OneClickClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v0/any-input/withdrawals');
          expect(request.url.queryParameters['depositAddress'], 'deposit');
          expect(request.url.queryParameters['sortOrder'], 'desc');
          return http.Response(
            jsonEncode({
              'asset': 'nep141:usdc.near',
              'recipient': 'bob.near',
              'affiliateRecipient': 'affiliate.near',
              'withdrawals': {
                'amountOut': '100',
                'amountOutFormatted': '1',
                'timestamp': '2026-07-06T12:00:00.000Z',
                'hash': 'tx',
              },
            }),
            200,
          );
        }),
      );

      final withdrawals = await client.anyInputWithdrawals(
        depositAddress: 'deposit',
        sortOrder: OneClickSortOrder.desc,
      );

      expect(withdrawals.asset, 'nep141:usdc.near');
      expect(withdrawals.withdrawals!.amountOutFormatted, '1');
      expect(withdrawals.withdrawals!.hash, 'tx');
    });

    test('throws on non-2xx responses', () async {
      final client = OneClickClient(
        httpClient: MockClient((_) async {
          return http.Response('rate limited', 429);
        }),
      );

      expect(
        client.tokens,
        throwsA(
          isA<OneClickApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.code, 'code', NearErrorCode.rateLimited)
              .having((e) => e.body, 'body', 'rate limited'),
        ),
      );
    });

    test(
      'logs safe lifecycle events without auth or request contents',
      () async {
        final events = <NearLogEvent>[];
        final client = OneClickClient(
          auth: OneClickAuth.bearerToken('test-secret'),
          logger: events.add,
          httpClient: MockClient(
            (_) async => http.Response(jsonEncode([]), 200),
          ),
        );

        await client.tokens();

        expect(events.map((event) => event.type), [
          NearLogEventType.intentsRequestStarted,
          NearLogEventType.intentsRequestSucceeded,
        ]);
        expect(
          events.last.metadata['endpoint'],
          'https://1click.chaindefuser.com',
        );
        expect(events.last.metadata['method'], 'GET');
        expect(events.last.metadata['path'], '/v0/tokens');
        expect(events.last.metadata['statusCode'], 200);
        expect(
          events.map((event) => event.toString()).join(),
          isNot(contains('test-secret')),
        );
      },
    );

    test(
      'logs a terminal failure for HTTP errors without auth contents',
      () async {
        final events = <NearLogEvent>[];
        final client = OneClickClient(
          auth: OneClickAuth.bearerToken('test-secret'),
          logger: events.add,
          httpClient: MockClient(
            (_) async => http.Response('private body', 429),
          ),
        );

        await expectLater(
          client.tokens(),
          throwsA(isA<OneClickApiException>()),
        );

        expect(events.map((event) => event.type), [
          NearLogEventType.intentsRequestStarted,
          NearLogEventType.intentsRequestFailed,
        ]);
        expect(events.last.metadata['statusCode'], 429);
        expect(
          events.map((event) => event.toString()).join(),
          isNot(contains('test-secret')),
        );
        expect(
          events.map((event) => event.toString()).join(),
          isNot(contains('private body')),
        );
      },
    );
  });
}
