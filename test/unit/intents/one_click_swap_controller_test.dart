import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OneClickSwapController', () {
    OneClickQuoteRequest quoteRequest({bool dry = false}) {
      return OneClickQuoteRequest(
        dry: dry,
        swapType: OneClickSwapType.exactInput,
        slippageTolerance: 100,
        originAsset: 'nep141:wrap.near',
        depositType: OneClickDepositType.originChain,
        destinationAsset: 'nep141:usdc.near',
        amount: '1000',
        refundTo: 'alice.near',
        refundType: OneClickRefundType.originChain,
        recipient: 'alice.near',
        recipientType: OneClickRecipientType.intents,
        deadline: DateTime.utc(2026, 7, 6, 12, 5),
      );
    }

    test('tracks quote state and exposes deposit instructions', () async {
      final controller = OneClickSwapController(
        client: OneClickClient(
          httpClient: MockClient((request) async {
            expect(request.url.path, '/v0/quote');
            return http.Response(
              jsonEncode({
                'correlationId': 'cid-1',
                'quote': {
                  'depositAddress': 'deposit-address',
                  'depositMemo': 'memo-1',
                  'amountOut': '990',
                },
              }),
              200,
            );
          }),
        ),
      );
      addTearDown(controller.dispose);
      final states = <OneClickSwapState>[];
      final sub = controller.states.listen(states.add);
      addTearDown(sub.cancel);

      final quote = await controller.quote(quoteRequest());

      expect(quote.correlationId, 'cid-1');
      expect(controller.state.stage, OneClickSwapStage.awaitingDeposit);
      expect(controller.state.depositAddress, 'deposit-address');
      expect(controller.state.depositMemo, 'memo-1');
      expect(
        states.map((state) => state.stage),
        containsAllInOrder([
          OneClickSwapStage.quoting,
          OneClickSwapStage.awaitingDeposit,
        ]),
      );
    });

    test('marks dry quotes as quoted instead of awaiting deposit', () async {
      final controller = OneClickSwapController(
        client: OneClickClient(
          httpClient: MockClient((_) async {
            return http.Response(
              jsonEncode({
                'correlationId': 'cid-1',
                'quote': {'amountOut': '990'},
              }),
              200,
            );
          }),
        ),
      );
      addTearDown(controller.dispose);

      await controller.quote(quoteRequest(dry: true));

      expect(controller.state.stage, OneClickSwapStage.quoted);
      expect(controller.state.isTerminal, isFalse);
    });

    test(
      'submits deposit and maps status responses to terminal stages',
      () async {
        var statusCalls = 0;
        final controller = OneClickSwapController(
          client: OneClickClient(
            httpClient: MockClient((request) async {
              if (request.url.path == '/v0/deposit/submit') {
                final body = jsonDecode(request.body) as Map<String, dynamic>;
                expect(body['depositAddress'], 'deposit-address');
                expect(body['txHash'], '0xabc');
                return http.Response('{}', 200);
              }
              statusCalls++;
              expect(request.url.path, '/v0/status');
              return http.Response(
                jsonEncode({
                  'correlationId': 'cid-$statusCalls',
                  'status': statusCalls == 1 ? 'PROCESSING' : 'SUCCESS',
                  'swapDetails': {
                    'nearTxHashes': ['near-tx'],
                  },
                }),
                200,
              );
            }),
          ),
        );
        addTearDown(controller.dispose);

        await controller.submitDeposit(
          depositAddress: 'deposit-address',
          txHash: '0xabc',
        );
        expect(controller.state.stage, OneClickSwapStage.depositSubmitted);

        final status = await controller.refreshStatus(
          depositAddress: 'deposit-address',
        );
        expect(status.kind, OneClickStatusKind.processing);
        expect(controller.state.stage, OneClickSwapStage.processing);

        final polled = await controller
            .pollStatus(
              depositAddress: 'deposit-address',
              interval: Duration.zero,
              timeout: const Duration(seconds: 1),
            )
            .toList();

        expect(polled.single.stage, OneClickSwapStage.success);
        expect(controller.state.isTerminal, isTrue);
      },
    );

    test('captures quote errors in state before rethrowing', () async {
      final controller = OneClickSwapController(
        client: OneClickClient(
          httpClient: MockClient((_) async => http.Response('bad quote', 400)),
        ),
      );
      addTearDown(controller.dispose);

      await expectLater(
        controller.quote(quoteRequest()),
        throwsA(isA<OneClickApiException>()),
      );
      expect(controller.state.stage, OneClickSwapStage.failed);
      expect(
        controller.state.error,
        'OneClickApiException(statusCode: 400, code: NearErrorCode.invalidResponse)',
      );
    });
  });
}
