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
  });
}
