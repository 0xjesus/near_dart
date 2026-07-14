@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  const blockHash = '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM';
  const accessKeyNonce = 100;

  Map<String, dynamic> callFunctionResult(Object? json) {
    final result = json == null ? <int>[] : utf8.encode(jsonEncode(json));
    return {
      'jsonrpc': '2.0',
      'id': 'test',
      'result': {
        'result': result,
        'logs': <String>[],
        'block_height': 1,
        'block_hash': blockHash,
      },
    };
  }

  group('NEP view helpers', () {
    test('viewFunction decodes typed JSON at final block finality', () async {
      late Map<String, dynamic> rpc;
      final client = NearRpcClient(
        rpcUrl: 'https://rpc.example.com',
        httpClient: MockClient((request) async {
          rpc = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(callFunctionResult({'count': 7})),
            200,
          );
        }),
      );

      final result = await client.viewFunction<int>(
        contractId: AccountId('counter.near'),
        methodName: 'get_count',
        args: const {'owner_id': 'alice.near'},
        decode: (json) => (json as Map<String, dynamic>)['count'] as int,
      );

      expect(result.getOrThrow(), 7);
      final params = rpc['params'] as Map<String, dynamic>;
      expect(params['account_id'], 'counter.near');
      expect(params['method_name'], 'get_count');
      expect(params['finality'], 'final');
    });

    test(
      'viewFunction returns a parse failure when typed decoding fails',
      () async {
        final client = NearRpcClient(
          rpcUrl: 'https://rpc.example.com',
          httpClient: MockClient((_) async {
            return http.Response(
              jsonEncode(callFunctionResult('invalid')),
              200,
            );
          }),
        );

        final result = await client.viewFunction<int>(
          contractId: AccountId('counter.near'),
          methodName: 'get_count',
          decode: (json) => (json as Map<String, dynamic>)['count'] as int,
        );

        expect(result, isA<RpcFailure<int>>());
        expect((result as RpcFailure<int>).error.kind, RpcErrorKind.parseError);
      },
    );

    test('ftBalanceOf calls ft_balance_of and parses a BigInt', () async {
      late Map<String, dynamic> rpc;
      final client = NearRpcClient(
        rpcUrl: 'https://rpc.example.com',
        httpClient: MockClient((request) async {
          rpc = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(callFunctionResult('42')), 200);
        }),
      );

      final balance = await client.ftBalanceOf(
        tokenId: AccountId('token.near'),
        accountId: AccountId('alice.near'),
      );

      expect(balance.getOrThrow(), BigInt.from(42));
      final params = rpc['params'] as Map<String, dynamic>;
      expect(params['request_type'], 'call_function');
      expect(params['account_id'], 'token.near');
      expect(params['method_name'], 'ft_balance_of');
      final args = jsonDecode(
        utf8.decode(base64Decode(params['args_base64'] as String)),
      );
      expect(args, {'account_id': 'alice.near'});
    });

    test('storageBalanceOf parses null and object responses', () async {
      var registered = false;
      final client = NearRpcClient(
        rpcUrl: 'https://rpc.example.com',
        httpClient: MockClient((_) async {
          final response = registered
              ? {'total': '1250000000000000000000', 'available': '0'}
              : null;
          registered = true;
          return http.Response(jsonEncode(callFunctionResult(response)), 200);
        }),
      );

      final missing = await client.storageBalanceOf(
        contractId: AccountId('token.near'),
        accountId: AccountId('alice.near'),
      );
      final existing = await client.storageBalanceOf(
        contractId: AccountId('token.near'),
        accountId: AccountId('alice.near'),
      );

      expect(missing.getOrThrow(), isNull);
      expect(
        existing.getOrThrow()!.total.yoctoNear,
        BigInt.parse('1250000000000000000000'),
      );
    });

    test('nftToken parses token metadata', () async {
      final client = NearRpcClient(
        rpcUrl: 'https://rpc.example.com',
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode(
              callFunctionResult({
                'token_id': 'coffee-1',
                'owner_id': 'alice.near',
                'metadata': {'title': 'Coffee NFT'},
              }),
            ),
            200,
          );
        }),
      );

      final token = await client.nftToken(
        contractId: AccountId('nft.near'),
        tokenId: 'coffee-1',
      );

      expect(token.getOrThrow()!.ownerId, AccountId('alice.near'));
      expect(token.getOrThrow()!.metadata!.title, 'Coffee NFT');
    });
  });

  group('NEP transaction helpers', () {
    late HttpServer server;
    late NearRpcClient client;
    late KeyPairEd25519 keyPair;
    late Account account;
    late List<Map<String, dynamic>> requests;

    Map<String, dynamic> accessKeyResult() => {
      'nonce': accessKeyNonce,
      'permission': 'FullAccess',
      'block_height': 1234,
      'block_hash': blockHash,
    };

    Map<String, dynamic> sendTxResult(String hash) => {
      'status': {'SuccessValue': ''},
      'transaction': {
        'signer_id': 'alice.near',
        'public_key': keyPair.publicKey.value,
        'nonce': accessKeyNonce + 1,
        'receiver_id': 'token.near',
        'hash': hash,
        'actions': <dynamic>[],
      },
      'transaction_outcome': {
        'id': hash,
        'block_hash': blockHash,
        'outcome': {
          'logs': <String>[],
          'receipt_ids': <String>[],
          'gas_burnt': 0,
          'tokens_burnt': '0',
          'executor_id': 'alice.near',
          'status': {'SuccessValue': ''},
        },
      },
      'receipts_outcome': <Map<String, dynamic>>[],
    };

    setUp(() async {
      requests = [];
      keyPair = await KeyPairEd25519.fromSeed(List.filled(32, 8));
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
        accountId: AccountId('alice.near'),
        keyPair: keyPair,
        client: client,
      );
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test('ftTransfer signs ft_transfer with one yoctoNEAR', () async {
      await account.ftTransfer(
        tokenId: AccountId('token.near'),
        receiverId: AccountId('bob.near'),
        amount: BigInt.from(7),
        memo: 'coffee',
      );

      final expected = await signTransaction(
        Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('token.near'),
          nonce: BigInt.from(accessKeyNonce + 1),
          blockHash: const CryptoHash(blockHash),
          actions: [
            FunctionCallAction(
              methodName: 'ft_transfer',
              args: {
                'receiver_id': 'bob.near',
                'amount': '7',
                'memo': 'coffee',
              },
              deposit: NearToken.oneYocto(),
            ),
          ],
        ),
        keyPair,
      );

      final sendParams = requests[1]['params'] as Map<String, dynamic>;
      expect(sendParams['signed_tx_base64'], expected.encodeToBase64());
    });

    test(
      'storageDeposit signs storage_deposit with the chosen deposit',
      () async {
        await account.storageDeposit(
          contractId: AccountId('token.near'),
          accountId: AccountId('bob.near'),
          registrationOnly: true,
          deposit: NearToken.fromYocto('1250000000000000000000'),
        );

        final expected = await signTransaction(
          Transaction(
            signerId: AccountId('alice.near'),
            receiverId: AccountId('token.near'),
            nonce: BigInt.from(accessKeyNonce + 1),
            blockHash: const CryptoHash(blockHash),
            actions: [
              FunctionCallAction(
                methodName: 'storage_deposit',
                args: {'account_id': 'bob.near', 'registration_only': true},
                deposit: NearToken.fromYocto('1250000000000000000000'),
              ),
            ],
          ),
          keyPair,
        );

        final sendParams = requests[1]['params'] as Map<String, dynamic>;
        expect(sendParams['signed_tx_base64'], expected.encodeToBase64());
      },
    );

    test('nftTransfer signs nft_transfer with one yoctoNEAR', () async {
      await account.nftTransfer(
        contractId: AccountId('token.near'),
        receiverId: AccountId('bob.near'),
        tokenId: 'coffee-1',
        approvalId: 3,
        memo: 'gift',
      );

      final expected = await signTransaction(
        Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('token.near'),
          nonce: BigInt.from(accessKeyNonce + 1),
          blockHash: const CryptoHash(blockHash),
          actions: [
            FunctionCallAction(
              methodName: 'nft_transfer',
              args: {
                'receiver_id': 'bob.near',
                'token_id': 'coffee-1',
                'approval_id': 3,
                'memo': 'gift',
              },
              deposit: NearToken.oneYocto(),
            ),
          ],
        ),
        keyPair,
      );

      final sendParams = requests[1]['params'] as Map<String, dynamic>;
      expect(sendParams['signed_tx_base64'], expected.encodeToBase64());
    });
  });
}
