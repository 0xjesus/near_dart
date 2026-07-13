import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NearRpcClient diagnostics', () {
    test(
      'logs a failed primary and successful fallback without request data',
      () async {
        final events = <NearLogEvent>[];
        final client = NearRpcClient(
          rpcUrl: 'https://primary.example.com/rpc',
          fallbackUrls: const ['https://fallback.example.com/rpc'],
          logger: events.add,
          httpClient: MockClient((request) async {
            if (request.url.host == 'primary.example.com') {
              return http.Response('unavailable', 503);
            }
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': 'ignored',
                'result': {'gas_price': '100'},
              }),
              200,
            );
          }),
        );

        final result = await client.gasPrice();

        expect(result.isSuccess, isTrue);
        expect(events.map((event) => event.type), [
          NearLogEventType.rpcRequestStarted,
          NearLogEventType.rpcRequestRetried,
          NearLogEventType.rpcRequestSucceeded,
        ]);
        expect(
          events.expand((event) => event.metadata.keys),
          isNot(contains('params')),
        );
        expect(
          events.first.metadata,
          containsPair('endpoint', 'https://primary.example.com'),
        );
        expect(events.first.metadata, containsPair('attempt', 1));
        expect(events.first.metadata, containsPair('endpointCount', 2));
        expect(events.first.metadata['durationMs'], isA<int>());
        expect(events[1].metadata['statusCode'], 503);
        expect(
          events.last.metadata['endpoint'],
          'https://fallback.example.com',
        );
        expect(events.last.metadata['attempt'], 2);
        expect(events.last.metadata['statusCode'], 200);
        for (final event in events) {
          expect(
            event.metadata.keys,
            everyElement(
              isIn([
                'endpoint',
                'attempt',
                'endpointCount',
                'statusCode',
                'durationMs',
              ]),
            ),
          );
        }
        client.close();
      },
    );

    test('logs one terminal failure for a JSON-RPC error', () async {
      final events = <NearLogEvent>[];
      final client = NearRpcClient(
        rpcUrl: 'https://primary.example.com/rpc',
        logger: events.add,
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 'private-id',
              'error': {'code': -32000, 'message': 'private error'},
            }),
            200,
          ),
        ),
      );

      final result = await client.gasPrice();

      expect(result.isFailure, isTrue);
      expect(events.map((event) => event.type), [
        NearLogEventType.rpcRequestStarted,
        NearLogEventType.rpcRequestFailed,
      ]);
      expect(events.last.metadata['statusCode'], 200);
      expect(
        events.map((event) => event.toString()).join(),
        isNot(contains('private')),
      );
      client.close();
    });

    test(
      'logs one terminal failure after exhausted transport fallbacks',
      () async {
        final events = <NearLogEvent>[];
        final client = NearRpcClient(
          rpcUrl: 'https://primary.example.com/rpc',
          fallbackUrls: const ['https://fallback.example.com/rpc'],
          logger: events.add,
          httpClient: MockClient((_) async => http.Response('offline', 503)),
        );

        final result = await client.gasPrice();

        expect(result.isFailure, isTrue);
        expect(events.map((event) => event.type), [
          NearLogEventType.rpcRequestStarted,
          NearLogEventType.rpcRequestRetried,
          NearLogEventType.rpcRequestFailed,
        ]);
        expect(events.last.metadata['attempt'], 2);
        expect(events.last.metadata['statusCode'], 503);
        client.close();
      },
    );

    test(
      'keeps invalid primary endpoint failures inside diagnostics lifecycle',
      () async {
        final events = <NearLogEvent>[];
        final client = NearRpcClient(
          rpcUrl: 'http://[invalid',
          logger: events.add,
          httpClient: MockClient((_) async => throw StateError('not reached')),
        );

        final result = await client.gasPrice();

        expect(result.isFailure, isTrue);
        expect(events.map((event) => event.type), [
          NearLogEventType.rpcRequestStarted,
          NearLogEventType.rpcRequestFailed,
        ]);
        expect(
          events.expand((event) => event.metadata.values).join(),
          isNot(contains('http://[invalid')),
        );
        expect(events.first.metadata['endpoint'], 'invalid-endpoint');
        expect(events.last.metadata['endpoint'], 'invalid-endpoint');
        client.close();
      },
    );

    test(
      'keeps invalid fallback endpoint failures inside diagnostics lifecycle',
      () async {
        final events = <NearLogEvent>[];
        final client = NearRpcClient(
          rpcUrl: 'https://primary.example.com/rpc',
          fallbackUrls: const ['http://[invalid'],
          logger: events.add,
          httpClient: MockClient((_) async => http.Response('offline', 503)),
        );

        final result = await client.gasPrice();

        expect(result.isFailure, isTrue);
        expect(events.map((event) => event.type), [
          NearLogEventType.rpcRequestStarted,
          NearLogEventType.rpcRequestRetried,
          NearLogEventType.rpcRequestFailed,
        ]);
        expect(events.last.metadata['endpoint'], 'invalid-endpoint');
        expect(
          events.expand((event) => event.metadata.values).join(),
          isNot(contains('http://[invalid')),
        );
        client.close();
      },
    );

    test(
      'retries a custom-scheme primary endpoint with a valid fallback',
      () async {
        const endpoint =
            'custom://userinfo-sentinel@example.com/path-sentinel?query-sentinel';
        final events = <NearLogEvent>[];
        var transportCalls = 0;
        final client = NearRpcClient(
          rpcUrl: endpoint,
          fallbackUrls: const ['https://fallback.example.com/rpc'],
          logger: events.add,
          httpClient: MockClient((request) async {
            transportCalls++;
            expect(request.url.host, 'fallback.example.com');
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': 'ignored',
                'result': {'gas_price': '100'},
              }),
              200,
            );
          }),
        );

        final result = await client.gasPrice();

        expect(result.isSuccess, isTrue);
        expect(events.map((event) => event.type), [
          NearLogEventType.rpcRequestStarted,
          NearLogEventType.rpcRequestRetried,
          NearLogEventType.rpcRequestSucceeded,
        ]);
        _expectOneTerminalEvent(events);
        _expectNoEndpointSentinels([...events, result]);
        expect(transportCalls, 1);
        client.close();
      },
    );

    test(
      'keeps custom-scheme final fallback failures inside diagnostics',
      () async {
        const endpoint =
            'custom://userinfo-sentinel@example.com/path-sentinel?query-sentinel';
        final events = <NearLogEvent>[];
        var transportCalls = 0;
        final client = NearRpcClient(
          rpcUrl: 'https://primary.example.com/rpc',
          fallbackUrls: const [endpoint],
          logger: events.add,
          httpClient: MockClient((_) async {
            transportCalls++;
            return http.Response('offline', 503);
          }),
        );

        final result = await client.gasPrice();

        expect(result.isFailure, isTrue);
        expect(events.map((event) => event.type), [
          NearLogEventType.rpcRequestStarted,
          NearLogEventType.rpcRequestRetried,
          NearLogEventType.rpcRequestFailed,
        ]);
        _expectOneTerminalEvent(events);
        _expectNoEndpointSentinels([...events, result]);
        expect(transportCalls, 1);
        final error = (result as RpcFailure).error;
        expect(error.kind, RpcErrorKind.networkError);
        expect(error.message, 'RPC endpoint is invalid or unsupported.');
        expect(
          result.getOrThrow,
          throwsA(predicate<Object>(_doesNotContainEndpointSentinel)),
        );
        client.close();
      },
    );

    test('normalizes supported endpoint transport errors', () async {
      const endpoint =
          'https://userinfo-sentinel@transport.example.com/path-sentinel?query-sentinel';
      final events = <NearLogEvent>[];
      var transportCalls = 0;
      final client = NearRpcClient(
        rpcUrl: endpoint,
        logger: events.add,
        httpClient: MockClient((request) async {
          transportCalls++;
          throw StateError('transport failure for ${request.url}');
        }),
      );

      final result = await client.gasPrice();

      expect(result.isFailure, isTrue);
      expect((result as RpcFailure).error.message, 'RPC transport failed.');
      expect(events.map((event) => event.type), [
        NearLogEventType.rpcRequestStarted,
        NearLogEventType.rpcRequestFailed,
      ]);
      _expectOneTerminalEvent(events);
      _expectNoEndpointSentinels([...events, result]);
      expect(transportCalls, 1);
      client.close();
    });
  });
}

void _expectOneTerminalEvent(List<NearLogEvent> events) {
  expect(
    events.where(
      (event) =>
          event.type == NearLogEventType.rpcRequestSucceeded ||
          event.type == NearLogEventType.rpcRequestFailed,
    ),
    hasLength(1),
  );
}

void _expectNoEndpointSentinels(Iterable<Object> values) {
  for (final value in values) {
    expect(_containsEndpointSentinel(value.toString()), isFalse);
  }
}

bool _containsEndpointSentinel(String value) {
  return value.contains('userinfo-sentinel') ||
      value.contains('path-sentinel') ||
      value.contains('query-sentinel');
}

bool _doesNotContainEndpointSentinel(Object error) {
  return !_containsEndpointSentinel(error.toString());
}
