import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('SolverRelayClient', () {
    test('requests quotes over JSON-RPC with API key auth', () async {
      late Map<String, dynamic> body;
      final client = SolverRelayClient(
        auth: OneClickAuth.xApiKey('jwt'),
        httpClient: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://solver-relay-v2.chaindefuser.com/rpc',
          );
          expect(request.headers['X-API-Key'], 'jwt');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': [
                {
                  'quote_hash': 'qh',
                  'defuse_asset_identifier_in': 'nep141:wrap.near',
                  'defuse_asset_identifier_out': 'nep141:usdc.near',
                  'amount_in': '100',
                  'amount_out': '98',
                  'expiration_time': '2026-07-06T12:00:00.000Z',
                },
              ],
            }),
            200,
          );
        }),
      );

      final quotes = await client.quote(
        const SolverRelayQuoteRequest(
          defuseAssetIdentifierIn: 'nep141:wrap.near',
          defuseAssetIdentifierOut: 'nep141:usdc.near',
          exactAmountIn: '100',
          minDeadlineMs: 60000,
        ),
      );

      expect(body['method'], 'quote');
      final params = (body['params'] as List).single as Map<String, dynamic>;
      expect(params['exact_amount_in'], '100');
      expect(params['min_deadline_ms'], 60000);
      expect(quotes.single.quoteHash, 'qh');
      expect(quotes.single.amountOut, '98');
    });

    test('publishes signed intents and checks status', () async {
      final client = SolverRelayClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['method'] == 'publish_intent') {
            final params =
                (body['params'] as List).single as Map<String, dynamic>;
            expect(params['quote_hashes'], ['qh']);
            expect(params['signed_data']['standard'], 'nep413');
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'result': {'status': 'OK', 'intent_hash': 'ih'},
              }),
              200,
            );
          }
          expect(body['method'], 'get_status');
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'intent_hash': 'ih',
                'status': 'TX_BROADCASTED',
                'data': {'hash': 'near-tx'},
              },
            }),
            200,
          );
        }),
      );

      final published = await client.publishIntent(
        const SolverRelayPublishIntentRequest(
          quoteHashes: ['qh'],
          signedData: SignedMultiPayload(
            standard: IntentSigningStandard.nep413,
            payload: {'message': 'm'},
            publicKey: 'ed25519:pub',
            signature: 'sig',
          ),
        ),
      );
      final status = await client.getStatus('ih');

      expect(published.status, 'OK');
      expect(published.intentHash, 'ih');
      expect(status.kind, SolverRelayIntentStatusKind.txBroadcasted);
      expect(status.nearTransactionHash, 'near-tx');
    });

    test('throws on JSON-RPC errors', () async {
      final client = SolverRelayClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'error': {'code': -32602, 'message': 'invalid params'},
            }),
            200,
          );
        }),
      );

      expect(
        () => client.getStatus('ih'),
        throwsA(
          isA<SolverRelayException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.invalidResponse,
          ),
        ),
      );
    });

    test(
      'keeps solver model decode failures inside the request lifecycle',
      () async {
        final calls = <Future<void> Function(SolverRelayClient)>[
          (client) async => client.quote(
            const SolverRelayQuoteRequest(
              defuseAssetIdentifierIn: 'nep141:wrap.near',
              defuseAssetIdentifierOut: 'nep141:usdc.near',
              exactAmountIn: '100',
            ),
          ),
          (client) async => client.publishIntent(
            const SolverRelayPublishIntentRequest(
              quoteHashes: ['qh'],
              signedData: SignedMultiPayload(
                standard: IntentSigningStandard.nep413,
                payload: {'message': 'm'},
                publicKey: 'ed25519:pub',
                signature: 'sig',
              ),
            ),
          ),
          (client) async => client.getStatus('intent-hash'),
        ];
        final invalidResults = [
          <Object?>[{}],
          <String, Object?>{},
          <String, Object?>{},
        ];

        for (var index = 0; index < calls.length; index++) {
          final events = <NearLogEvent>[];
          final client = SolverRelayClient(
            logger: events.add,
            httpClient: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'jsonrpc': '2.0',
                  'id': 1,
                  'result': invalidResults[index],
                }),
                200,
              ),
            ),
          );

          await expectLater(calls[index](client), throwsA(anything));
          expect(events.map((event) => event.type), [
            NearLogEventType.intentsRequestStarted,
            NearLogEventType.intentsRequestFailed,
          ]);
        }
      },
    );

    test('logs malformed solver JSON as a request failure', () async {
      final events = <NearLogEvent>[];
      final client = SolverRelayClient(
        logger: events.add,
        httpClient: MockClient((_) async => http.Response('not-json', 200)),
      );

      await expectLater(client.getStatus('intent-hash'), throwsA(anything));

      expect(events.map((event) => event.type), [
        NearLogEventType.intentsRequestStarted,
        NearLogEventType.intentsRequestFailed,
      ]);
    });

    test(
      'classifies local request encoding failures as invalid input',
      () async {
        for (final extra in _nonJsonRelayExtras()) {
          final events = <NearLogEvent>[];
          var transportCalls = 0;
          final client = SolverRelayClient(
            logger: events.add,
            httpClient: MockClient((_) async {
              transportCalls++;
              return http.Response('{}', 200);
            }),
          );

          late Object escaped;
          try {
            await client.quote(
              SolverRelayQuoteRequest(
                defuseAssetIdentifierIn: 'nep141:wrap.near',
                defuseAssetIdentifierOut: 'nep141:usdc.near',
                exactAmountIn: '100',
                extra: extra,
              ),
            );
          } catch (error) {
            escaped = error;
          }

          expect(escaped, isA<SolverRelayException>());
          final exception = escaped as SolverRelayException;
          expect(exception.code, NearErrorCode.invalidInput);
          expect(exception.retryable, isFalse);
          expect(events.map((event) => event.type), [
            NearLogEventType.intentsRequestStarted,
            NearLogEventType.intentsRequestFailed,
          ]);
          _expectOneIntentsTerminalEvent(events);
          expect(transportCalls, 0);
          expect(
            [...events, escaped].join(),
            isNot(contains('request-sentinel')),
          );
        }
      },
    );

    test('supports const relay exceptions without exposing their bodies', () {
      const exception = SolverRelayException(
        'private message',
        statusCode: 429,
        body: 'test-secret',
      );

      expect(exception, isA<NearSdkException>());
      expect(exception.code, NearErrorCode.rateLimited);
      expect(exception.retryable, isTrue);
      expect(exception.toString(), isNot(contains('test-secret')));
    });

    test(
      'logs safe lifecycle events without API key or quote parameters',
      () async {
        final events = <NearLogEvent>[];
        final client = SolverRelayClient(
          auth: OneClickAuth.xApiKey('test-secret'),
          logger: events.add,
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': []}),
              200,
            ),
          ),
        );

        await client.quote(
          const SolverRelayQuoteRequest(
            defuseAssetIdentifierIn: 'nep141:wrap.near',
            defuseAssetIdentifierOut: 'nep141:usdc.near',
            exactAmountIn: 'test-secret',
            minDeadlineMs: 60000,
          ),
        );

        expect(events.map((event) => event.type), [
          NearLogEventType.intentsRequestStarted,
          NearLogEventType.intentsRequestSucceeded,
        ]);
        expect(
          events.last.metadata['endpoint'],
          'https://solver-relay-v2.chaindefuser.com',
        );
        expect(events.last.metadata['method'], 'POST');
        expect(events.last.metadata['operation'], 'quote');
        expect(events.last.metadata['path'], '/rpc');
        expect(events.last.metadata['statusCode'], 200);
        expect(
          events.map((event) => event.toString()).join(),
          isNot(contains('test-secret')),
        );
      },
    );

    test(
      'logs a terminal failure for JSON-RPC errors without API key',
      () async {
        final events = <NearLogEvent>[];
        final client = SolverRelayClient(
          auth: OneClickAuth.xApiKey('test-secret'),
          logger: events.add,
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': 1,
                'error': {'code': -32602, 'message': 'private body'},
              }),
              200,
            ),
          ),
        );

        await expectLater(
          client.getStatus('intent-hash'),
          throwsA(isA<SolverRelayException>()),
        );

        expect(events.map((event) => event.type), [
          NearLogEventType.intentsRequestStarted,
          NearLogEventType.intentsRequestFailed,
        ]);
        expect(events.last.metadata['statusCode'], 200);
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

    test('keeps custom-scheme endpoint failures private', () async {
      const endpoint =
          'custom://userinfo-sentinel@example.com/path-sentinel?query-sentinel';
      final events = <NearLogEvent>[];
      var transportCalls = 0;
      final client = SolverRelayClient(
        endpoint: Uri.parse(endpoint),
        logger: events.add,
        httpClient: MockClient((_) async {
          transportCalls++;
          throw StateError('transport should not be called');
        }),
      );

      late Object escaped;
      try {
        await client.getStatus('intent-hash');
      } catch (error) {
        escaped = error;
      }

      expect(escaped, isA<SolverRelayException>());
      final exception = escaped as SolverRelayException;
      expect(exception.code, NearErrorCode.invalidInput);
      expect(
        exception.message,
        'Solver relay endpoint is invalid or unsupported.',
      );
      expect(exception.retryable, isFalse);

      expect(events.map((event) => event.type), [
        NearLogEventType.intentsRequestStarted,
        NearLogEventType.intentsRequestFailed,
      ]);
      _expectOneIntentsTerminalEvent(events);
      _expectNoCustomEndpointSentinels([...events, escaped]);
      expect(transportCalls, 0);
    });

    test('normalizes supported endpoint transport errors', () async {
      const endpoint =
          'https://userinfo-sentinel@transport.example.com/path-sentinel?query-sentinel';
      final events = <NearLogEvent>[];
      var transportCalls = 0;
      final client = SolverRelayClient(
        endpoint: Uri.parse(endpoint),
        logger: events.add,
        httpClient: MockClient((request) async {
          transportCalls++;
          throw StateError('transport failure for ${request.url}');
        }),
      );

      late Object escaped;
      try {
        await client.getStatus('intent-hash');
      } catch (error) {
        escaped = error;
      }

      expect(escaped, isA<SolverRelayException>());
      final exception = escaped as SolverRelayException;
      expect(exception.code, NearErrorCode.rpcUnavailable);
      expect(exception.message, 'Solver relay transport failed.');
      expect(exception.retryable, isTrue);
      expect(events.map((event) => event.type), [
        NearLogEventType.intentsRequestStarted,
        NearLogEventType.intentsRequestFailed,
      ]);
      _expectOneIntentsTerminalEvent(events);
      _expectNoTransportEndpointSentinels([...events, escaped]);
      expect(transportCalls, 1);
    });
  });
}

void _expectOneIntentsTerminalEvent(List<NearLogEvent> events) {
  expect(
    events.where(
      (event) =>
          event.type == NearLogEventType.intentsRequestSucceeded ||
          event.type == NearLogEventType.intentsRequestFailed,
    ),
    hasLength(1),
  );
}

void _expectNoCustomEndpointSentinels(Iterable<Object> values) {
  for (final value in values) {
    final rendered = value.toString();
    expect(rendered, isNot(contains('userinfo-sentinel')));
    expect(rendered, isNot(contains('path-sentinel')));
    expect(rendered, isNot(contains('query-sentinel')));
  }
}

void _expectNoTransportEndpointSentinels(Iterable<Object> values) {
  for (final value in values) {
    final rendered = value.toString();
    expect(rendered, isNot(contains('userinfo-sentinel')));
    expect(rendered, isNot(contains('query-sentinel')));
  }
}

Iterable<Map<String, dynamic>> _nonJsonRelayExtras() sync* {
  yield {'unsupported': _RelayRequestSentinel()};
  final cyclic = <String, dynamic>{};
  cyclic['cycle'] = cyclic;
  yield {'cyclic': cyclic};
}

class _RelayRequestSentinel {
  @override
  String toString() => 'request-sentinel';
}
