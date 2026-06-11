@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// A network SDK must not hang forever on a stalled node. These tests use a
/// real server that deliberately never responds.
void main() {
  late HttpServer hangingServer;
  late List<HttpRequest> hungRequests;

  setUp(() async {
    hungRequests = [];
    hangingServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    // Accept the request but never write a response.
    hangingServer.listen(hungRequests.add);
  });

  tearDown(() async {
    for (final r in hungRequests) {
      await r.response.close().catchError((_) {});
    }
    await hangingServer.close(force: true);
  });

  test('a stalled node yields a timeout failure, not a hang', () async {
    final client = NearRpcClient(
      rpcUrl: 'http://127.0.0.1:${hangingServer.port}',
      timeout: const Duration(milliseconds: 300),
    );

    final result = await client.status().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError('client never returned — it hung'),
    );

    expect(result.isFailure, isTrue);
    expect((result as RpcFailure).error.kind, RpcErrorKind.timeout);
    client.close();
  });

  test('times out the primary then succeeds on a healthy fallback', () async {
    final healthy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    healthy.listen((request) async {
      final body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': {'gas_price': '100000000'},
          }),
        );
      await request.response.close();
    });

    final client = NearRpcClient(
      rpcUrl: 'http://127.0.0.1:${hangingServer.port}',
      fallbackUrls: ['http://127.0.0.1:${healthy.port}'],
      timeout: const Duration(milliseconds: 300),
    );

    final result = await client.gasPrice();

    expect(result.isSuccess, isTrue);
    client.close();
    await healthy.close(force: true);
  });

  test('defaults to a finite timeout when none is given', () {
    final client = NearRpcClient(rpcUrl: 'http://127.0.0.1:1');
    expect(client.timeout, isNotNull);
    expect(client.timeout.inSeconds, greaterThan(0));
    client.close();
  });
}
