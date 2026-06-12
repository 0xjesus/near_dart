@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Tests sendTransaction/sendTransactionAsync against a real in-process
/// HTTP JSON-RPC server (no mocks — full HTTP round trip).
void main() {
  late HttpServer server;
  late NearRpcClient client;
  late List<Map<String, dynamic>> receivedRequests;
  late Map<String, dynamic> Function(Map<String, dynamic> request) responder;

  setUp(() async {
    receivedRequests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      receivedRequests.add(decoded);
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': decoded['id'],
            'result': responder(decoded),
          }),
        );
      await request.response.close();
    });
    client = NearRpcClient(rpcUrl: 'http://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  Future<SignedTransaction> buildSignedTransaction() async {
    final keyPair = await KeyPairEd25519.generate();
    return signTransaction(
      Transaction(
        signerId: AccountId('alice.testnet'),
        receiverId: AccountId('bob.testnet'),
        nonce: BigInt.from(7),
        blockHash: const CryptoHash(
          '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM',
        ),
        actions: [TransferAction(deposit: NearToken.fromYocto('1'))],
      ),
      keyPair,
    );
  }

  Map<String, dynamic> successOutcome(SignedTransaction signed) => {
    'status': {'SuccessValue': ''},
    'transaction': {
      'signer_id': 'alice.testnet',
      'public_key': signed.publicKey.value,
      'nonce': 7,
      'receiver_id': 'bob.testnet',
      'hash': signed.hash,
      'actions': [
        {
          'Transfer': {'deposit': '1'},
        },
      ],
    },
    'transaction_outcome': {
      'id': signed.hash,
      'block_hash': '9MzuZrRPW1BGpFnZJUJg6SzCrixPpJDfjsNeUobRXsLe',
      'outcome': {
        'logs': <String>[],
        'receipt_ids': ['8hxkU4avDWFDCsZckU8nWPRSV3wsAxZFCzZeBcGCZAqX'],
        'gas_burnt': 223182562500,
        'tokens_burnt': '22318256250000000000',
        'executor_id': 'alice.testnet',
        'status': {
          'SuccessReceiptId': '8hxkU4avDWFDCsZckU8nWPRSV3wsAxZFCzZeBcGCZAqX',
        },
      },
    },
    'receipts_outcome': <Map<String, dynamic>>[],
  };

  group('sendTransaction', () {
    test('posts send_tx with the Borsh base64 payload', () async {
      final signed = await buildSignedTransaction();
      responder = (_) => successOutcome(signed);

      await client.sendTransaction(signed);

      expect(receivedRequests, hasLength(1));
      final request = receivedRequests.single;
      expect(request['method'], 'send_tx');
      final params = request['params'] as Map<String, dynamic>;
      expect(params['signed_tx_base64'], signed.encodeToBase64());
      expect(params['wait_until'], 'EXECUTED_OPTIMISTIC');
    });

    test('honours a custom waitUntil', () async {
      final signed = await buildSignedTransaction();
      responder = (_) => successOutcome(signed);

      await client.sendTransaction(signed, waitUntil: TxExecutionStatus.final_);

      final params = receivedRequests.single['params'] as Map<String, dynamic>;
      expect(params['wait_until'], 'FINAL');
    });

    test('parses a successful execution outcome', () async {
      final signed = await buildSignedTransaction();
      responder = (_) => successOutcome(signed);

      final result = await client.sendTransaction(signed);

      expect(result.isSuccess, isTrue);
      final outcome = result.getOrNull()!;
      expect(outcome.status, isA<TransactionStatusSuccess>());
      expect(outcome.transaction.hash, signed.hash);
    });

    test('surfaces RPC errors as failures', () async {
      final signed = await buildSignedTransaction();
      await server.close(force: true);
      final errorServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      errorServer.listen((request) async {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 'x',
              'error': {
                'code': -32000,
                'message': 'Server error',
                'data': 'InvalidNonce',
              },
            }),
          );
        await request.response.close();
      });
      final errorClient = NearRpcClient(
        rpcUrl: 'http://127.0.0.1:${errorServer.port}',
      );

      final result = await errorClient.sendTransaction(signed);

      expect(result.isFailure, isTrue);
      errorClient.close();
      await errorServer.close(force: true);
    });
  });

  group('sendTransactionAsync', () {
    test('posts broadcast_tx_async and returns the hash', () async {
      final signed = await buildSignedTransaction();
      responder = (_) => throw UnimplementedError();

      // broadcast_tx_async returns a bare string result.
      await server.close(force: true);
      final asyncServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      late Map<String, dynamic> received;
      asyncServer.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        received = jsonDecode(body) as Map<String, dynamic>;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': received['id'],
              'result': signed.hash,
            }),
          );
        await request.response.close();
      });
      final asyncClient = NearRpcClient(
        rpcUrl: 'http://127.0.0.1:${asyncServer.port}',
      );

      final result = await asyncClient.sendTransactionAsync(signed);

      expect(received['method'], 'broadcast_tx_async');
      expect(received['params'], [signed.encodeToBase64()]);
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), signed.hash);
      asyncClient.close();
      await asyncServer.close(force: true);
    });
  });
}
