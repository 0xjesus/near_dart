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
        throwsA(isA<SolverRelayException>()),
      );
    });
  });
}
