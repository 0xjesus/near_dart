import 'package:flutter_test/flutter_test.dart';
import 'package:near_dart/near_dart.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

void main() {
  final account = WalletAccount(
    accountId: AccountId('alice.testnet'),
    publicKey: PublicKey(
      'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
    ),
  );
  final contractId = AccountId('app.testnet');

  group('NearWalletSecurityPolicy', () {
    test('defaults all on-chain checks to disabled', () {
      const policy = NearWalletSecurityPolicy();

      expect(policy.verifyAccessKeyOnConnect, isFalse);
      expect(policy.transactionFinality, isNull);
    });

    test('stores explicit verification and confirmation options', () {
      const policy = NearWalletSecurityPolicy(
        verifyAccessKeyOnConnect: true,
        transactionFinality: TxExecutionStatus.final_,
      );

      expect(policy.verifyAccessKeyOnConnect, isTrue);
      expect(policy.transactionFinality, TxExecutionStatus.final_);
    });
  });

  group('verifyAccessKey', () {
    test('accepts a matching function-call key at finality', () async {
      final client = _FakeNearRpcClient()
        ..accessKeyResult = RpcResult.success(
          _accessKey(
            const FunctionCallPermissionView(
              receiverId: 'app.testnet',
              methodNames: ['read', 'write'],
            ),
          ),
        );

      await NearWalletSecurity(client).verifyAccessKey(
        account: account,
        contractId: contractId,
        methodNames: const ['write'],
        requireFunctionCallScope: true,
      );

      expect(client.accessKeyCalls, hasLength(1));
      expect(client.accessKeyCalls.single.accountId, account.accountId);
      expect(client.accessKeyCalls.single.publicKey, account.publicKey);
      expect(client.accessKeyCalls.single.blockReference.toJson(), {
        'finality': 'final',
      });
    });

    test('accepts an unrestricted on-chain method list', () async {
      final client = _FakeNearRpcClient()
        ..accessKeyResult = RpcResult.success(
          _accessKey(
            const FunctionCallPermissionView(
              receiverId: 'app.testnet',
              methodNames: [],
            ),
          ),
        );

      await NearWalletSecurity(client).verifyAccessKey(
        account: account,
        contractId: contractId,
        methodNames: const ['read', 'write'],
        requireFunctionCallScope: true,
      );
    });

    test('rejects a restricted key when requested methods mean all', () async {
      final client = _FakeNearRpcClient()
        ..accessKeyResult = RpcResult.success(
          _accessKey(
            const FunctionCallPermissionView(
              receiverId: 'app.testnet',
              methodNames: ['read'],
            ),
          ),
        );

      await _expectNearError(
        () => NearWalletSecurity(client).verifyAccessKey(
          account: account,
          contractId: contractId,
          methodNames: const [],
          requireFunctionCallScope: true,
        ),
        NearErrorCode.accessKeyMismatch,
      );
    });

    test('rejects a wrong receiver or insufficient method scope', () async {
      for (final permission in <FunctionCallPermissionView>[
        const FunctionCallPermissionView(
          receiverId: 'other.testnet',
          methodNames: [],
        ),
        const FunctionCallPermissionView(
          receiverId: 'app.testnet',
          methodNames: ['read'],
        ),
      ]) {
        final client = _FakeNearRpcClient()
          ..accessKeyResult = RpcResult.success(_accessKey(permission));

        await _expectNearError(
          () => NearWalletSecurity(client).verifyAccessKey(
            account: account,
            contractId: contractId,
            methodNames: const ['read', 'write'],
            requireFunctionCallScope: true,
          ),
          NearErrorCode.accessKeyMismatch,
        );
      }
    });

    test(
      'rejects full access for scope checks but accepts existence',
      () async {
        final client = _FakeNearRpcClient()
          ..accessKeyResult = RpcResult.success(
            _accessKey(const FullAccessPermissionView()),
          );
        final security = NearWalletSecurity(client);

        await _expectNearError(
          () => security.verifyAccessKey(
            account: account,
            contractId: contractId,
            methodNames: const [],
            requireFunctionCallScope: true,
          ),
          NearErrorCode.accessKeyMismatch,
        );
        await security.verifyAccessKey(
          account: account,
          contractId: contractId,
          methodNames: const [],
          requireFunctionCallScope: false,
        );
      },
    );

    test('maps missing access keys without exposing RPC payloads', () async {
      const secret = 'private-key-material';
      final client = _FakeNearRpcClient()
        ..accessKeyResult = RpcResult.failure(
          const RpcError(
            kind: RpcErrorKind.runtimeError,
            message: 'UNKNOWN_ACCESS_KEY $secret',
            data: {'private_key': secret},
          ),
        );

      final error = await _expectNearError(
        () => NearWalletSecurity(client).verifyAccessKey(
          account: account,
          contractId: contractId,
          methodNames: const [],
          requireFunctionCallScope: false,
        ),
        NearErrorCode.accessKeyNotFound,
      );

      expect(error.message, isNot(contains(secret)));
      expect(error.toString(), isNot(contains(secret)));
    });

    test(
      'preserves transport classification with a sanitized message',
      () async {
        const secret = 'Bearer secret-token';
        final client = _FakeNearRpcClient()
          ..accessKeyResult = RpcResult.failure(RpcError.network(secret));

        final error = await _expectNearError(
          () => NearWalletSecurity(client).verifyAccessKey(
            account: account,
            contractId: contractId,
            methodNames: const [],
            requireFunctionCallScope: false,
          ),
          NearErrorCode.rpcUnavailable,
        );

        expect(error.retryable, isTrue);
        expect(error.message, isNot(contains(secret)));
      },
    );
  });

  group('confirmTransactions', () {
    test(
      'extracts nested and typed hashes in stable deduplicated order',
      () async {
        final client = _FakeNearRpcClient();
        final security = NearWalletSecurity(client);
        final typed = TransactionResult(
          transactionHash: const CryptoHash('sixth'),
          outcome: ExecutionOutcome(
            status: ExecutionStatus.successValue(''),
            gasBurnt: BigInt.zero,
          ),
        );

        await security.confirmTransactions(
          senderAccountId: account.accountId,
          outcomes: <dynamic>[
            'first',
            {'transaction_hash': 'second'},
            {'txHash': 'first'},
            {
              'transaction': {'hash': 'third'},
            },
            {
              'transactionHashes': [
                'fourth',
                {'transactionHash': 'second'},
                {'hash': 'fifth'},
              ],
            },
            typed,
            [
              {'hash': 'seventh'},
            ],
          ],
          waitUntil: TxExecutionStatus.final_,
        );

        expect(client.transactionCalls.map((call) => call.hash), [
          'first',
          'second',
          'third',
          'fourth',
          'fifth',
          'sixth',
          'seventh',
        ]);
        expect(client.transactionCalls.map((call) => call.waitUntil).toSet(), {
          TxExecutionStatus.final_,
        });
        expect(
          client.transactionCalls.map((call) => call.senderAccountId).toSet(),
          {account.accountId},
        );
      },
    );

    test('checks each distinct hash exactly once', () async {
      final client = _FakeNearRpcClient();

      await NearWalletSecurity(client).confirmTransactions(
        senderAccountId: account.accountId,
        outcomes: const [
          {'transactionHash': 'one'},
          {'hash': 'two'},
          {'transaction_hash': 'one'},
        ],
        waitUntil: TxExecutionStatus.final_,
      );

      expect(client.transactionCalls.map((call) => call.hash), ['one', 'two']);
    });

    test('maps failure and insufficient balance statuses safely', () async {
      const secret = 'signed-transaction-payload';
      for (final entry in <MapEntry<Object, NearErrorCode>>[
        const MapEntry({
          'ActionError': {'kind': 'FunctionCallError', 'payload': secret},
        }, NearErrorCode.transactionFailed),
        const MapEntry({
          'ActionError': {'kind': 'LackBalanceForState', 'payload': secret},
        }, NearErrorCode.insufficientBalance),
      ]) {
        final client = _FakeNearRpcClient()
          ..transactionResults['failed'] = RpcResult.success(
            _transactionResponse({'Failure': entry.key}),
          );

        final error = await _expectNearError(
          () => NearWalletSecurity(client).confirmTransactions(
            senderAccountId: account.accountId,
            outcomes: const ['failed'],
            waitUntil: TxExecutionStatus.final_,
          ),
          entry.value,
        );

        expect(error.message, isNot(contains(secret)));
        expect(error.toString(), isNot(contains(secret)));
      }
    });

    test('rejects unknown transaction status', () async {
      final client = _FakeNearRpcClient()
        ..transactionResults['pending'] = RpcResult.success(
          _transactionResponse('Unknown'),
        );

      await _expectNearError(
        () => NearWalletSecurity(client).confirmTransactions(
          senderAccountId: account.accountId,
          outcomes: const ['pending'],
          waitUntil: TxExecutionStatus.included,
        ),
        NearErrorCode.transactionFailed,
      );
    });

    test('preserves transaction RPC failure classification safely', () async {
      const secret = 'authorization-secret';
      final client = _FakeNearRpcClient()
        ..transactionResults['failed'] = RpcResult.failure(
          RpcError.timeout(secret),
        );

      final error = await _expectNearError(
        () => NearWalletSecurity(client).confirmTransactions(
          senderAccountId: account.accountId,
          outcomes: const ['failed'],
          waitUntil: TxExecutionStatus.final_,
        ),
        NearErrorCode.rpcTimeout,
      );

      expect(error.retryable, isTrue);
      expect(error.message, isNot(contains(secret)));
    });

    test('rejects confirmation without an extractable hash', () async {
      final client = _FakeNearRpcClient();

      await _expectNearError(
        () => NearWalletSecurity(client).confirmTransactions(
          senderAccountId: account.accountId,
          outcomes: const [
            {'status': 'submitted'},
          ],
          waitUntil: TxExecutionStatus.final_,
        ),
        NearErrorCode.walletResponseInvalid,
      );

      expect(client.transactionCalls, isEmpty);
    });
  });
}

AccessKeyView _accessKey(AccessKeyPermissionView permission) => AccessKeyView(
  nonce: 1,
  permission: permission,
  blockHeight: 1,
  blockHash: 'block',
);

TransactionResponse _transactionResponse(Object status) =>
    TransactionResponse.fromJson({
      'status': status,
      'transaction': {
        'signer_id': 'alice.testnet',
        'public_key': 'ed25519:11111111111111111111111111111111',
        'nonce': 1,
        'receiver_id': 'app.testnet',
        'hash': 'hash',
        'actions': <dynamic>[],
      },
      'transaction_outcome': {
        'id': 'outcome',
        'outcome': {
          'logs': <String>[],
          'receipt_ids': <String>[],
          'gas_burnt': 0,
          'tokens_burnt': '0',
          'executor_id': 'app.testnet',
          'status': {'SuccessValue': ''},
        },
      },
      'receipts_outcome': <dynamic>[],
    });

Future<NearSdkException> _expectNearError(
  Future<void> Function() operation,
  NearErrorCode code,
) async {
  try {
    await operation();
    fail('Expected NearSdkException with code $code');
  } on NearSdkException catch (error) {
    expect(error.code, code);
    return error;
  }
}

class _AccessKeyCall {
  const _AccessKeyCall(this.accountId, this.publicKey, this.blockReference);

  final AccountId accountId;
  final PublicKey publicKey;
  final BlockReference blockReference;
}

class _TransactionCall {
  const _TransactionCall(this.hash, this.senderAccountId, this.waitUntil);

  final String hash;
  final AccountId senderAccountId;
  final TxExecutionStatus waitUntil;
}

class _FakeNearRpcClient extends NearRpcClient {
  _FakeNearRpcClient() : super(rpcUrl: 'https://rpc.invalid');

  RpcResult<AccessKeyView> accessKeyResult = RpcResult.success(
    _accessKey(
      const FunctionCallPermissionView(
        receiverId: 'app.testnet',
        methodNames: [],
      ),
    ),
  );
  final List<_AccessKeyCall> accessKeyCalls = [];
  final Map<String, RpcResult<TransactionResponse>> transactionResults = {};
  final List<_TransactionCall> transactionCalls = [];

  @override
  Future<RpcResult<AccessKeyView>> viewAccessKey({
    required AccountId accountId,
    required PublicKey publicKey,
    required BlockReference blockReference,
  }) async {
    accessKeyCalls.add(_AccessKeyCall(accountId, publicKey, blockReference));
    return accessKeyResult;
  }

  @override
  Future<RpcResult<TransactionResponse>> txStatus({
    required String transactionHash,
    required AccountId senderAccountId,
    TxExecutionStatus waitUntil = TxExecutionStatus.executed,
  }) async {
    transactionCalls.add(
      _TransactionCall(transactionHash, senderAccountId, waitUntil),
    );
    return transactionResults[transactionHash] ??
        RpcResult.success(_transactionResponse({'SuccessValue': ''}));
  }
}
