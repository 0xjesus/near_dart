@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// Tests the high-level Account API (nonce/blockHash resolution + sign +
/// send) against a real in-process JSON-RPC server.
void main() {
  const blockHashB58 = '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM';
  const accessKeyNonce = 100;

  late HttpServer server;
  late NearRpcClient client;
  late KeyPairEd25519 keyPair;
  late Account account;
  late List<Map<String, dynamic>> requests;
  int rpcNonce = accessKeyNonce;

  Map<String, dynamic> accessKeyResult() => {
    'nonce': rpcNonce,
    'permission': 'FullAccess',
    'block_height': 1234,
    'block_hash': blockHashB58,
  };

  Map<String, dynamic> sendTxResult(String hash) => {
    'status': {'SuccessValue': ''},
    'transaction': {
      'signer_id': 'alice.testnet',
      'public_key': keyPair.publicKey.value,
      'nonce': accessKeyNonce + 1,
      'receiver_id': 'bob.testnet',
      'hash': hash,
      'actions': <dynamic>[],
    },
    'transaction_outcome': {
      'id': hash,
      'block_hash': blockHashB58,
      'outcome': {
        'logs': <String>[],
        'receipt_ids': <String>[],
        'gas_burnt': 0,
        'tokens_burnt': '0',
        'executor_id': 'alice.testnet',
        'status': {'SuccessValue': ''},
      },
    },
    'receipts_outcome': <Map<String, dynamic>>[],
  };

  setUp(() async {
    requests = [];
    rpcNonce = accessKeyNonce;
    keyPair = await KeyPairEd25519.fromSeed(List.filled(32, 7));
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      requests.add(body);
      final Object result;
      switch (body['method']) {
        case 'query':
          result = accessKeyResult();
        case 'send_tx':
          final payload =
              (body['params'] as Map<String, dynamic>)['signed_tx_base64']
                  as String;
          result = sendTxResult(
            base58Encode(sha256Hash(base64Decode(payload))),
          );
        default:
          throw StateError('Unexpected method ${body['method']}');
      }
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': result}),
        );
      await request.response.close();
    });
    client = NearRpcClient(rpcUrl: 'http://127.0.0.1:${server.port}');
    account = Account(
      accountId: AccountId('alice.testnet'),
      keyPair: keyPair,
      client: client,
    );
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  group('Account.transfer', () {
    test('resolves nonce and block hash, signs and sends', () async {
      final result = await account.transfer(
        receiverId: AccountId('bob.testnet'),
        amount: NearToken.fromYocto('1000'),
      );

      expect(result.isSuccess, isTrue);
      expect(requests, hasLength(2));

      // First request: view_access_key for nonce + recent block hash.
      final query = requests[0];
      expect(query['method'], 'query');
      final queryParams = query['params'] as Map<String, dynamic>;
      expect(queryParams['request_type'], 'view_access_key');
      expect(queryParams['account_id'], 'alice.testnet');
      expect(queryParams['public_key'], keyPair.publicKey.value);

      // Second request: send_tx with the exact expected signed payload.
      final sendParams = requests[1]['params'] as Map<String, dynamic>;
      final expectedSigned = await signTransaction(
        Transaction(
          signerId: AccountId('alice.testnet'),
          receiverId: AccountId('bob.testnet'),
          nonce: BigInt.from(accessKeyNonce + 1),
          blockHash: const CryptoHash(blockHashB58),
          actions: [TransferAction(deposit: NearToken.fromYocto('1000'))],
        ),
        keyPair,
      );
      expect(sendParams['signed_tx_base64'], expectedSigned.encodeToBase64());
    });

    test('increments the nonce locally on consecutive sends', () async {
      await account.transfer(
        receiverId: AccountId('bob.testnet'),
        amount: NearToken.fromYocto('1'),
      );
      // The RPC still reports the stale nonce; the account must not reuse it.
      await account.transfer(
        receiverId: AccountId('bob.testnet'),
        amount: NearToken.fromYocto('1'),
      );

      final sends = requests.where((r) => r['method'] == 'send_tx').toList();
      expect(sends, hasLength(2));
      expect(sends[0]['params'], isNot(equals(sends[1]['params'])));
    });
  });

  group('Account.callFunction', () {
    test('sends a FunctionCall action with the given args', () async {
      final result = await account.callFunction(
        contractId: AccountId('wrap.testnet'),
        methodName: 'ft_transfer',
        args: {'receiver_id': 'bob.testnet', 'amount': '1'},
        deposit: NearToken.oneYocto(),
      );

      expect(result.isSuccess, isTrue);
      final sendParams = requests[1]['params'] as Map<String, dynamic>;
      final expectedSigned = await signTransaction(
        Transaction(
          signerId: AccountId('alice.testnet'),
          receiverId: AccountId('wrap.testnet'),
          nonce: BigInt.from(accessKeyNonce + 1),
          blockHash: const CryptoHash(blockHashB58),
          actions: [
            FunctionCallAction(
              methodName: 'ft_transfer',
              args: {'receiver_id': 'bob.testnet', 'amount': '1'},
              deposit: NearToken.oneYocto(),
            ),
          ],
        ),
        keyPair,
      );
      expect(sendParams['signed_tx_base64'], expectedSigned.encodeToBase64());
    });
  });

  group('Account.signAndSendTransaction', () {
    test('sends arbitrary multi-action transactions', () async {
      final result = await account.signAndSendTransaction(
        receiverId: AccountId('bob.testnet'),
        actions: [
          const CreateAccountAction(),
          TransferAction(deposit: NearToken.fromYocto('42')),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(requests.last['method'], 'send_tx');
    });

    test('propagates access key query failures', () async {
      await server.close(force: true);
      final result = await account.transfer(
        receiverId: AccountId('bob.testnet'),
        amount: NearToken.fromYocto('1'),
      );
      expect(result.isFailure, isTrue);
    });
  });
}
