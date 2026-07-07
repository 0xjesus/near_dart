@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// The *.near.org RPC endpoints were deprecated in 2025 and are severely
/// rate limited. Defaults must point to FastNear, with failover support.
void main() {
  group('default endpoints', () {
    test('testnet defaults to FastNear', () {
      final client = NearRpcClient.testnet();
      expect(client.rpcUrl, 'https://test.rpc.fastnear.com');
      expect(client.network, NearNetwork.testnet);
      client.close();
    });

    test('mainnet defaults to FastNear', () {
      final client = NearRpcClient.mainnet();
      expect(client.rpcUrl, 'https://free.rpc.fastnear.com');
      expect(client.network, NearNetwork.mainnet);
      client.close();
    });

    test('testnet and mainnet include legacy fallbacks', () {
      final testnet = NearRpcClient.testnet();
      final mainnet = NearRpcClient.mainnet();
      expect(testnet.fallbackUrls, isNotEmpty);
      expect(mainnet.fallbackUrls, isNotEmpty);
      testnet.close();
      mainnet.close();
    });

    test('can create a client from a custom network config', () {
      final network = NearNetwork.custom(
        name: 'sandbox',
        rpcUrl: 'https://rpc.example.com',
        fallbackRpcUrls: const ['https://rpc-fallback.example.com'],
        explorerUrl: 'https://explorer.example.com',
      );

      final client = NearRpcClient.forNetwork(network);

      expect(client.network, network);
      expect(client.rpcUrl, 'https://rpc.example.com');
      expect(client.fallbackUrls, ['https://rpc-fallback.example.com']);
      client.close();
    });
  });

  group('failover', () {
    late HttpServer fallbackServer;
    late List<String> servedMethods;

    setUp(() async {
      servedMethods = [];
      fallbackServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      fallbackServer.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        servedMethods.add(body['method'] as String);
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
    });

    tearDown(() => fallbackServer.close(force: true));

    test(
      'falls back to the next URL when the primary is unreachable',
      () async {
        // Bind-then-close to get a port that is guaranteed unreachable.
        final dead = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final deadPort = dead.port;
        await dead.close();

        final client = NearRpcClient(
          rpcUrl: 'http://127.0.0.1:$deadPort',
          fallbackUrls: ['http://127.0.0.1:${fallbackServer.port}'],
        );

        final result = await client.gasPrice();

        expect(result.isSuccess, isTrue);
        expect(servedMethods, ['gas_price']);
        client.close();
      },
    );

    test('does not fail over on JSON-RPC level errors', () async {
      final errorServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      errorServer.listen((request) async {
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
              'error': {'code': -32000, 'message': 'Server error'},
            }),
          );
        await request.response.close();
      });

      final client = NearRpcClient(
        rpcUrl: 'http://127.0.0.1:${errorServer.port}',
        fallbackUrls: ['http://127.0.0.1:${fallbackServer.port}'],
      );

      final result = await client.gasPrice();

      // The RPC answered; its error is the answer — no retry on fallback.
      expect(result.isFailure, isTrue);
      expect(servedMethods, isEmpty);
      client.close();
      await errorServer.close(force: true);
    });

    test('fails over on HTTP 429 rate limiting', () async {
      final limitedServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      limitedServer.listen((request) async {
        await utf8.decoder.bind(request).join();
        request.response.statusCode = 429;
        await request.response.close();
      });

      final client = NearRpcClient(
        rpcUrl: 'http://127.0.0.1:${limitedServer.port}',
        fallbackUrls: ['http://127.0.0.1:${fallbackServer.port}'],
      );

      final result = await client.gasPrice();

      expect(result.isSuccess, isTrue);
      expect(servedMethods, ['gas_price']);
      client.close();
      await limitedServer.close(force: true);
    });
  });
}
