import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('NearRpcClient', () {
    group('configuration', () {
      test('creates client with default testnet URL', () {
        final client = NearRpcClient.testnet();
        expect(client.rpcUrl, equals('https://rpc.testnet.near.org'));
      });

      test('creates client with default mainnet URL', () {
        final client = NearRpcClient.mainnet();
        expect(client.rpcUrl, equals('https://rpc.mainnet.near.org'));
      });

      test('creates client with custom URL', () {
        final client = NearRpcClient(rpcUrl: 'https://custom-rpc.example.com');
        expect(client.rpcUrl, equals('https://custom-rpc.example.com'));
      });
    });

    group('status', () {
      test('returns node status on success', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          // Path is empty string for base URL without trailing slash
          expect(request.url.host, equals('rpc.testnet.near.org'));

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['method'], equals('status'));
          expect(body['jsonrpc'], equals('2.0'));

          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'version': {'version': '1.35.0', 'build': 'stable'},
                'chain_id': 'testnet',
                'protocol_version': 65,
                'latest_protocol_version': 65,
                'rpc_addr': '0.0.0.0:3030',
                'validators': [],
                'sync_info': {
                  'latest_block_hash': '9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f',
                  'latest_block_height': 123456789,
                  'latest_state_root': 'ABC123',
                  'latest_block_time': '2024-01-01T00:00:00Z',
                  'syncing': false,
                },
                'validator_account_id': null,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.status();

        expect(result.isSuccess, isTrue);

        final status = result.getOrNull()!;
        expect(status.chainId, equals('testnet'));
        expect(status.version.version, equals('1.35.0'));
        expect(status.syncInfo.latestBlockHeight, equals(123456789));
        expect(status.syncInfo.syncing, isFalse);
      });

      test('returns error on RPC failure', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'error': {
                'code': -32000,
                'message': 'Server error',
                'data': 'Internal error occurred',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.status();

        expect(result.isFailure, isTrue);
        final error = (result as RpcFailure).error;
        expect(error.kind, equals(RpcErrorKind.rpcError));
        expect(error.code, equals(-32000));
      });

      test('returns network error on HTTP failure', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Service unavailable', 503);
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.status();

        expect(result.isFailure, isTrue);
        final error = (result as RpcFailure).error;
        expect(error.kind, equals(RpcErrorKind.httpError));
        expect(error.code, equals(503));
      });
    });

    group('block', () {
      test('fetches block by finality', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['method'], equals('block'));
          expect(body['params']['finality'], equals('final'));

          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'author': 'test.poolv1.near',
                'header': {
                  'height': 123456789,
                  'epoch_id': 'Epoch123',
                  'next_epoch_id': 'Epoch124',
                  'hash': 'BlockHash123',
                  'prev_hash': 'BlockHash122',
                  'prev_state_root': 'StateRoot123',
                  'chunk_receipts_root': 'ChunkReceiptsRoot',
                  'chunk_headers_root': 'ChunkHeadersRoot',
                  'chunk_tx_root': 'ChunkTxRoot',
                  'outcome_root': 'OutcomeRoot',
                  'chunks_included': 4,
                  'challenges_root': 'ChallengesRoot',
                  'timestamp': 1704067200000000000,
                  'timestamp_nanosec': '1704067200000000000',
                  'random_value': 'RandomValue',
                  'validator_proposals': [],
                  'chunk_mask': [true, true, true, true],
                  'gas_price': '100000000',
                  'block_ordinal': 123456789,
                  'rent_paid': '0',
                  'validator_reward': '0',
                  'total_supply': '1000000000000000000000000000000000',
                  'challenges_result': [],
                  'last_final_block': 'LastFinalBlock',
                  'last_ds_final_block': 'LastDSFinalBlock',
                  'next_bp_hash': 'NextBPHash',
                  'block_merkle_root': 'BlockMerkleRoot',
                  'epoch_sync_data_hash': null,
                  'approvals': [],
                  'signature': 'ed25519:signature',
                  'latest_protocol_version': 65,
                },
                'chunks': [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.block(
          BlockReference.finality(Finality.final_),
        );

        expect(result.isSuccess, isTrue);
        final block = result.getOrNull()!;
        expect(block.header.height, equals(123456789));
        expect(block.author, equals('test.poolv1.near'));
      });

      test('fetches block by height', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['params']['block_id'], equals(100));

          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'author': 'validator.near',
                'header': {
                  'height': 100,
                  'epoch_id': 'Epoch1',
                  'next_epoch_id': 'Epoch2',
                  'hash': 'Hash100',
                  'prev_hash': 'Hash99',
                  'prev_state_root': 'SR100',
                  'chunk_receipts_root': 'CRR',
                  'chunk_headers_root': 'CHR',
                  'chunk_tx_root': 'CTR',
                  'outcome_root': 'OR',
                  'chunks_included': 1,
                  'challenges_root': 'CR',
                  'timestamp': 1704067200000000000,
                  'timestamp_nanosec': '1704067200000000000',
                  'random_value': 'RV',
                  'validator_proposals': [],
                  'chunk_mask': [true],
                  'gas_price': '100000000',
                  'block_ordinal': 100,
                  'rent_paid': '0',
                  'validator_reward': '0',
                  'total_supply': '1000000000000000000000000000000000',
                  'challenges_result': [],
                  'last_final_block': 'LFB',
                  'last_ds_final_block': 'LDSFB',
                  'next_bp_hash': 'NBPH',
                  'block_merkle_root': 'BMR',
                  'epoch_sync_data_hash': null,
                  'approvals': [],
                  'signature': 'ed25519:sig',
                  'latest_protocol_version': 65,
                },
                'chunks': [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.block(BlockReference.blockId(100));

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull()!.header.height, equals(100));
      });
    });

    group('viewAccount', () {
      test('returns account information', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['method'], equals('query'));
          expect(body['params']['request_type'], equals('view_account'));
          expect(body['params']['account_id'], equals('alice.testnet'));

          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'amount': '100000000000000000000000000',
                'locked': '0',
                'code_hash': '11111111111111111111111111111111',
                'storage_usage': 182,
                'storage_paid_at': 0,
                'block_height': 123456789,
                'block_hash': 'BlockHash123',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.viewAccount(
          accountId: AccountId('alice.testnet'),
          blockReference: BlockReference.finality(Finality.final_),
        );

        expect(result.isSuccess, isTrue);
        final account = result.getOrNull()!;
        expect(account.amount.toNear(), closeTo(100.0, 0.001));
        expect(account.storageUsage, equals(182));
      });

      test('returns error for non-existent account', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'error': {
                'code': -32000,
                'message': 'Server error',
                'data': {
                  'cause': {
                    'name': 'UNKNOWN_ACCOUNT',
                    'info': {'account_id': 'nonexistent.testnet'},
                  },
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.viewAccount(
          accountId: AccountId('nonexistent.testnet'),
          blockReference: BlockReference.finality(Finality.final_),
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('gasPrice', () {
      test('returns gas price', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['method'], equals('gas_price'));

          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {'gas_price': '100000000'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = NearRpcClient.testnet(httpClient: mockClient);
        final result = await client.gasPrice();

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull()!.gasPrice, equals(BigInt.from(100000000)));
      });
    });
  });
}
