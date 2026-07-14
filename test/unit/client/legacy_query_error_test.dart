import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  test(
    'normalizes a legacy query result error before response parsing',
    () async {
      const remoteError = 'synthetic-runtime-error-sentinel';
      const remoteLog = 'synthetic-runtime-log-sentinel';
      const legacyResult = <String, dynamic>{
        'block_hash': '11111111111111111111111111111111',
        'block_height': 123,
        'error': remoteError,
        'logs': <String>[remoteLog],
      };
      final events = <NearLogEvent>[];
      final client = NearRpcClient(
        rpcUrl: 'https://rpc.example.com',
        logger: events.add,
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 'ignored',
              'result': legacyResult,
            }),
            200,
          ),
        ),
      );
      addTearDown(client.close);

      final result = await client.viewAccessKey(
        accountId: AccountId('missing.testnet'),
        publicKey: PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
        blockReference: BlockReference.finality(Finality.optimistic),
      );

      expect(result, isA<RpcFailure<AccessKeyView>>());
      final error = (result as RpcFailure<AccessKeyView>).error;
      expect(error.kind, RpcErrorKind.runtimeError);
      expect(error.data, legacyResult);
      expect(error.toString(), isNot(contains(remoteError)));
      expect(error.toString(), isNot(contains(remoteLog)));
      expect(
        events.map((event) => event.toString()).join(),
        allOf(isNot(contains(remoteError)), isNot(contains(remoteLog))),
      );
    },
  );

  test('keeps an ordinary query result map on the success path', () async {
    final client = NearRpcClient(
      rpcUrl: 'https://rpc.example.com',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': 'ignored',
            'result': {
              'nonce': 7,
              'permission': 'FullAccess',
              'block_height': 123,
              'block_hash': '11111111111111111111111111111111',
            },
          }),
          200,
        ),
      ),
    );
    addTearDown(client.close);

    final result = await client.viewAccessKey(
      accountId: AccountId('alice.testnet'),
      publicKey: PublicKey(
        'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
      ),
      blockReference: BlockReference.finality(Finality.optimistic),
    );

    expect(result, isA<RpcSuccess<AccessKeyView>>());
    expect(result.getOrThrow().nonce, 7);
  });

  group('legacy query result near-misses', () {
    const completeEnvelope = <String, dynamic>{
      'block_hash': '11111111111111111111111111111111',
      'block_height': 123,
      'error': 'synthetic-runtime-error-sentinel',
      'logs': <String>['synthetic-runtime-log-sentinel'],
    };

    for (final missingField in <String>[
      'block_hash',
      'block_height',
      'error',
      'logs',
    ]) {
      test('does not recognize an envelope missing $missingField', () async {
        final nearMiss = Map<String, dynamic>.of(completeEnvelope)
          ..remove(missingField);
        final client = NearRpcClient(
          rpcUrl: 'https://rpc.example.com',
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': 'ignored',
                'result': nearMiss,
              }),
              200,
            ),
          ),
        );
        addTearDown(client.close);

        final result = await client.viewAccessKey(
          accountId: AccountId('missing.testnet'),
          publicKey: PublicKey(
            'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
          ),
          blockReference: BlockReference.finality(Finality.optimistic),
        );

        expect(result, isA<RpcFailure<AccessKeyView>>());
        expect(
          (result as RpcFailure<AccessKeyView>).error.kind,
          RpcErrorKind.parseError,
        );
      });
    }

    test('does not recognize an envelope with a non-string error', () async {
      final nearMiss = <String, dynamic>{...completeEnvelope, 'error': 7};
      final client = NearRpcClient(
        rpcUrl: 'https://rpc.example.com',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': 'ignored', 'result': nearMiss}),
            200,
          ),
        ),
      );
      addTearDown(client.close);

      final result = await client.viewAccessKey(
        accountId: AccountId('missing.testnet'),
        publicKey: PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
        blockReference: BlockReference.finality(Finality.optimistic),
      );

      expect(result, isA<RpcFailure<AccessKeyView>>());
      expect(
        (result as RpcFailure<AccessKeyView>).error.kind,
        RpcErrorKind.parseError,
      );
    });
  });
}
