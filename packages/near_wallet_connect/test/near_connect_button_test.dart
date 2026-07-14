import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:near_dart/near_dart.dart'
    show
        AccessKeyView,
        BlockReference,
        InMemoryKeyStore,
        IntearConnectionResult,
        KeyPairEd25519,
        MyNearWalletAdapter,
        MyNearWalletConfig,
        PublicKey,
        RpcResult;
import 'package:near_wallet_connect/near_wallet_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _optionPrefsKey = 'near_wallet_connect_option';
const _hotAccountPrefsKey = 'near_wallet_connect_hot_account';
const _hotPublicKeyPrefsKey = 'near_wallet_connect_hot_public_key';
const _sentinelSecret = 'controller-adapter-sentinel-secret';

void main() {
  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the default disconnected button', (tester) async {
    final controller = NearWalletController(
      network: MyNearWalletNetwork.testnet,
      contractId: AccountId('app.testnet'),
    );

    await tester.pumpWidget(app(NearConnectButton(controller: controller)));

    expect(find.text('Connect NEAR wallet'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('uses custom connect builder', (tester) async {
    final controller = NearWalletController(
      network: MyNearWalletNetwork.testnet,
      contractId: AccountId('app.testnet'),
    );

    await tester.pumpWidget(
      app(
        NearConnectButton(
          controller: controller,
          connectBuilder: (context, controller, onPressed) {
            return OutlinedButton(
              onPressed: onPressed,
              child: const Text('Custom connect'),
            );
          },
        ),
      ),
    );

    expect(find.text('Custom connect'), findsOneWidget);
  });

  testWidgets('wallet picker renders wallet options', (tester) async {
    await tester.pumpWidget(
      app(
        NearWalletPicker(
          wallets: NearWalletOption.available(MyNearWalletNetwork.mainnet),
        ),
      ),
    );

    expect(find.text('MyNearWallet'), findsOneWidget);
    expect(find.text('Intear Wallet'), findsOneWidget);
    expect(find.text('HOT Wallet'), findsOneWidget);
  });

  testWidgets('account badge shortens compact account id', (tester) async {
    await tester.pumpWidget(
      app(
        NearAccountBadge(
          accountId: AccountId('very-long-account-name.near'),
          wallet: NearWalletOption.myNearWallet,
          compact: true,
        ),
      ),
    );

    expect(find.text('very-lon...e.near'), findsOneWidget);
    expect(find.text('MyNearWallet'), findsOneWidget);
  });

  testWidgets('transaction status renders success hash', (tester) async {
    await tester.pumpWidget(
      app(
        const NearTransactionStatusView(
          state: NearTransactionViewState.success,
          transactionHash: '1234567890abcdef',
        ),
      ),
    );

    expect(
      find.text('Transaction confirmed: 1234567890abcdef'),
      findsOneWidget,
    );
  });

  test('controller uses its resolved client for default security', () {
    final client = _CountingNearRpcClient();
    final controller = NearWalletController(
      network: MyNearWalletNetwork.testnet,
      contractId: AccountId('app.testnet'),
      client: client,
    );

    expect(controller.security.client, same(client));
  });

  test('controller passes its logger to the default RPC client', () {
    void logger(NearLogEvent event) {}

    final controller = NearWalletController(
      network: MyNearWalletNetwork.testnet,
      contractId: AccountId('app.testnet'),
      logger: logger,
    );

    expect(controller.logger, same(logger));
    expect(controller.client.logger, same(logger));
  });

  test(
    'default policy does not verify and HOT testnet is wrongNetwork',
    () async {
      final client = _CountingNearRpcClient();
      final controller = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('app.testnet'),
        client: client,
      );

      await controller.connect(wallet: NearWalletOption.hot);

      expect(client.accessKeyCalls, 0);
      expect(controller.error, contains('not available'));
      expect(controller.lastException?.code, NearErrorCode.wrongNetwork);
      expect(controller.error, controller.lastException?.message);
    },
  );

  test('disconnected operations expose typed compatible errors', () async {
    final controller = NearWalletController(
      network: MyNearWalletNetwork.testnet,
      contractId: AccountId('app.testnet'),
    );

    await expectLater(
      controller.sendTransactions(const []),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.notConnected,
        ),
      ),
    );
    expect(controller.lastException?.code, NearErrorCode.notConnected);
    expect(controller.error, controller.lastException?.message);
  });

  group('restored security policy', () {
    test(
      'verifies restored MyNearWallet and Intear function-call scope',
      () async {
        for (final option in [
          NearWalletOption.myNearWallet,
          NearWalletOption.intear,
        ]) {
          SharedPreferences.setMockInitialValues({
            _optionPrefsKey: option.name,
          });
          final keyStore = InMemoryKeyStore();
          final account = await _storeAccount(keyStore, 'restored.testnet');
          final security = _RecordingSecurity();
          final adapter = _FakeMyNearWalletAdapter(
            keyStore: keyStore,
            accounts: [account],
          );
          final controller = _testController(
            network: MyNearWalletNetwork.testnet,
            keyStore: keyStore,
            security: security,
            policy: const NearWalletSecurityPolicy(
              verifyAccessKeyOnConnect: true,
            ),
            myNearWalletAdapterBuilder: (logger) => adapter,
          );

          await controller.init();

          expect(controller.account, account);
          expect(controller.walletOption, option);
          expect(security.verifications, hasLength(1));
          expect(security.verifications.single.account, account);
          expect(
            security.verifications.single.requireFunctionCallScope,
            isTrue,
          );
        }
      },
    );

    test(
      'verifies an authentic restored HOT pair for existence only',
      () async {
        final pair = await KeyPairEd25519.generate();
        final account = WalletAccount(
          accountId: AccountId('restored.near'),
          publicKey: pair.publicKey,
        );
        SharedPreferences.setMockInitialValues({
          _optionPrefsKey: NearWalletOption.hot.name,
          _hotAccountPrefsKey: account.accountId.value,
          _hotPublicKeyPrefsKey: account.publicKey.value,
        });
        late NearWalletController controller;
        var notifications = 0;
        final security = _RecordingSecurity(
          onVerify: (_) {
            expect(controller.account, isNull);
            expect(controller.walletOption, isNull);
            expect(notifications, 0);
          },
        );
        controller = _testController(
          network: MyNearWalletNetwork.mainnet,
          security: security,
          policy: const NearWalletSecurityPolicy(
            verifyAccessKeyOnConnect: true,
          ),
        );
        controller.addListener(() => notifications++);

        await controller.init();

        expect(controller.account, account);
        expect(controller.walletOption, NearWalletOption.hot);
        expect(security.verifications, hasLength(1));
        expect(security.verifications.single.requireFunctionCallScope, isFalse);
        expect(notifications, 1);
      },
    );

    test('definite restored key failure removes key and preferences', () async {
      SharedPreferences.setMockInitialValues({
        _optionPrefsKey: NearWalletOption.intear.name,
      });
      final keyStore = InMemoryKeyStore();
      final account = await _storeAccount(keyStore, 'revoked.testnet');
      final security = _RecordingSecurity(
        verifyError: const NearSdkException(
          code: NearErrorCode.accessKeyNotFound,
          message: 'sanitized missing key',
        ),
      );
      final controller = _testController(
        network: MyNearWalletNetwork.testnet,
        keyStore: keyStore,
        security: security,
        policy: const NearWalletSecurityPolicy(verifyAccessKeyOnConnect: true),
        myNearWalletAdapterBuilder: (logger) => _FakeMyNearWalletAdapter(
          keyStore: keyStore,
          accounts: [account],
          logger: logger,
        ),
      );

      await controller.init();

      final prefs = await SharedPreferences.getInstance();
      expect(controller.account, isNull);
      expect(controller.walletOption, isNull);
      expect(controller.lastException?.code, NearErrorCode.accessKeyNotFound);
      expect(controller.error, controller.lastException?.message);
      expect(await keyStore.getKey(account.accountId), isNull);
      expect(prefs.getString(_optionPrefsKey), isNull);
      expect(prefs.getString(_hotAccountPrefsKey), isNull);
      expect(prefs.getString(_hotPublicKeyPrefsKey), isNull);
    });

    test('definite restored HOT mismatch clears its persisted pair', () async {
      final pair = await KeyPairEd25519.generate();
      SharedPreferences.setMockInitialValues({
        _optionPrefsKey: NearWalletOption.hot.name,
        _hotAccountPrefsKey: 'mismatch.near',
        _hotPublicKeyPrefsKey: pair.publicKey.value,
      });
      final controller = _testController(
        network: MyNearWalletNetwork.mainnet,
        security: _RecordingSecurity(
          verifyError: const NearSdkException(
            code: NearErrorCode.accessKeyMismatch,
            message: 'sanitized mismatch',
          ),
        ),
        policy: const NearWalletSecurityPolicy(verifyAccessKeyOnConnect: true),
      );

      await controller.init();

      final prefs = await SharedPreferences.getInstance();
      expect(controller.account, isNull);
      expect(controller.walletOption, isNull);
      expect(controller.lastException?.code, NearErrorCode.accessKeyMismatch);
      expect(prefs.getString(_optionPrefsKey), isNull);
      expect(prefs.getString(_hotAccountPrefsKey), isNull);
      expect(prefs.getString(_hotPublicKeyPrefsKey), isNull);
    });

    test(
      'retryable restored key failure retains credentials for retry',
      () async {
        SharedPreferences.setMockInitialValues({
          _optionPrefsKey: NearWalletOption.myNearWallet.name,
        });
        final keyStore = InMemoryKeyStore();
        final account = await _storeAccount(keyStore, 'retry.testnet');
        final security = _RecordingSecurity(
          verifyError: const NearSdkException(
            code: NearErrorCode.rpcTimeout,
            message: 'sanitized timeout',
            retryable: true,
          ),
        );
        final controller = _testController(
          network: MyNearWalletNetwork.testnet,
          keyStore: keyStore,
          security: security,
          policy: const NearWalletSecurityPolicy(
            verifyAccessKeyOnConnect: true,
          ),
          myNearWalletAdapterBuilder: (logger) => _FakeMyNearWalletAdapter(
            keyStore: keyStore,
            accounts: [account],
            logger: logger,
          ),
        );

        await controller.init();

        final prefs = await SharedPreferences.getInstance();
        expect(controller.account, isNull);
        expect(controller.walletOption, isNull);
        expect(controller.lastException?.code, NearErrorCode.rpcTimeout);
        expect(await keyStore.getKey(account.accountId), isNotNull);
        expect(
          prefs.getString(_optionPrefsKey),
          NearWalletOption.myNearWallet.name,
        );

        security.verifyError = null;
        await controller.init();

        expect(controller.account, account);
        expect(controller.walletOption, NearWalletOption.myNearWallet);
        expect(security.verifications, hasLength(2));
      },
    );

    test('retryable restored HOT failure retains authentic pair', () async {
      final pair = await KeyPairEd25519.generate();
      SharedPreferences.setMockInitialValues({
        _optionPrefsKey: NearWalletOption.hot.name,
        _hotAccountPrefsKey: 'retry.near',
        _hotPublicKeyPrefsKey: pair.publicKey.value,
      });
      final controller = _testController(
        network: MyNearWalletNetwork.mainnet,
        security: _RecordingSecurity(
          verifyError: const NearSdkException(
            code: NearErrorCode.rpcUnavailable,
            message: 'sanitized unavailable',
            retryable: true,
          ),
        ),
        policy: const NearWalletSecurityPolicy(verifyAccessKeyOnConnect: true),
      );

      await controller.init();

      final prefs = await SharedPreferences.getInstance();
      expect(controller.account, isNull);
      expect(controller.walletOption, isNull);
      expect(controller.lastException?.code, NearErrorCode.rpcUnavailable);
      expect(prefs.getString(_optionPrefsKey), NearWalletOption.hot.name);
      expect(prefs.getString(_hotAccountPrefsKey), 'retry.near');
      expect(prefs.getString(_hotPublicKeyPrefsKey), pair.publicKey.value);
    });
  });

  group('HOT persistence migration', () {
    test(
      'legacy state clears, disconnects, and reconnects authentic pair',
      () async {
        SharedPreferences.setMockInitialValues({
          _optionPrefsKey: NearWalletOption.hot.name,
          _hotAccountPrefsKey: 'legacy.near',
        });
        final pair = await KeyPairEd25519.generate();
        final freshAccount = WalletAccount(
          accountId: AccountId('fresh.near'),
          publicKey: pair.publicKey,
        );
        final controller = _testController(
          network: MyNearWalletNetwork.mainnet,
          hotWalletAdapterBuilder: (logger) =>
              _FakeHotWalletAdapter(account: freshAccount, logger: logger),
        );

        await controller.init();

        var prefs = await SharedPreferences.getInstance();
        expect(controller.account, isNull);
        expect(controller.walletOption, isNull);
        expect(prefs.getString(_optionPrefsKey), isNull);
        expect(prefs.getString(_hotAccountPrefsKey), isNull);
        expect(prefs.getString(_hotPublicKeyPrefsKey), isNull);

        await controller.disconnect();
        await controller.connect(wallet: NearWalletOption.hot);

        prefs = await SharedPreferences.getInstance();
        expect(controller.account, freshAccount);
        expect(controller.walletOption, NearWalletOption.hot);
        expect(
          prefs.getString(_hotAccountPrefsKey),
          freshAccount.accountId.value,
        );
        expect(
          prefs.getString(_hotPublicKeyPrefsKey),
          freshAccount.publicKey.value,
        );
      },
    );

    test('malformed stored HOT account or public key is cleared', () async {
      final pair = await KeyPairEd25519.generate();
      for (final credentials in [
        (accountId: 'INVALID!', publicKey: pair.publicKey.value),
        (accountId: 'valid.near', publicKey: 'ed25519:invalid'),
      ]) {
        SharedPreferences.setMockInitialValues({
          _optionPrefsKey: NearWalletOption.hot.name,
          _hotAccountPrefsKey: credentials.accountId,
          _hotPublicKeyPrefsKey: credentials.publicKey,
        });
        final controller = _testController(
          network: MyNearWalletNetwork.mainnet,
        );

        await controller.init();
        await controller.disconnect();

        final prefs = await SharedPreferences.getInstance();
        expect(controller.account, isNull);
        expect(controller.walletOption, isNull);
        expect(prefs.getString(_optionPrefsKey), isNull);
        expect(prefs.getString(_hotAccountPrefsKey), isNull);
        expect(prefs.getString(_hotPublicKeyPrefsKey), isNull);
      }
    });
  });

  group('fresh wallet security integration', () {
    test(
      'Intear verifies function-call scope and HOT verifies existence',
      () async {
        final intearStore = InMemoryKeyStore();
        final intearKey = await KeyPairEd25519.generate();
        final intearAccount = WalletAccount(
          accountId: AccountId('fresh.testnet'),
          publicKey: intearKey.publicKey,
        );
        final intearSecurity = _RecordingSecurity();
        final intearController = _testController(
          network: MyNearWalletNetwork.testnet,
          keyStore: intearStore,
          security: intearSecurity,
          policy: const NearWalletSecurityPolicy(
            verifyAccessKeyOnConnect: true,
          ),
          intearWalletAdapterBuilder: (logger) => _FakeIntearWalletAdapter(
            keyStore: intearStore,
            account: intearAccount,
            sessionKey: intearKey,
            logger: logger,
          ),
        );

        await intearController.connect(wallet: NearWalletOption.intear);

        expect(intearController.account, intearAccount);
        expect(
          intearSecurity.verifications.single.requireFunctionCallScope,
          isTrue,
        );

        SharedPreferences.setMockInitialValues({});
        final hotPair = await KeyPairEd25519.generate();
        final hotAccount = WalletAccount(
          accountId: AccountId('fresh.near'),
          publicKey: hotPair.publicKey,
        );
        final hotSecurity = _RecordingSecurity();
        final hotController = _testController(
          network: MyNearWalletNetwork.mainnet,
          security: hotSecurity,
          policy: const NearWalletSecurityPolicy(
            verifyAccessKeyOnConnect: true,
          ),
          hotWalletAdapterBuilder: (logger) =>
              _FakeHotWalletAdapter(account: hotAccount, logger: logger),
        );

        await hotController.connect(wallet: NearWalletOption.hot);

        expect(hotController.account, hotAccount);
        expect(
          hotSecurity.verifications.single.requireFunctionCallScope,
          isFalse,
        );
      },
    );

    test(
      'failed fresh Intear verification removes new key and session',
      () async {
        final keyStore = InMemoryKeyStore();
        final sessionKey = await KeyPairEd25519.generate();
        final account = WalletAccount(
          accountId: AccountId('failed.testnet'),
          publicKey: sessionKey.publicKey,
        );
        final controller = _testController(
          network: MyNearWalletNetwork.testnet,
          keyStore: keyStore,
          security: _RecordingSecurity(
            verifyError: const NearSdkException(
              code: NearErrorCode.accessKeyMismatch,
              message: 'sanitized mismatch',
            ),
          ),
          policy: const NearWalletSecurityPolicy(
            verifyAccessKeyOnConnect: true,
          ),
          intearWalletAdapterBuilder: (logger) => _FakeIntearWalletAdapter(
            keyStore: keyStore,
            account: account,
            sessionKey: sessionKey,
            logger: logger,
          ),
        );

        await controller.connect(wallet: NearWalletOption.intear);

        final prefs = await SharedPreferences.getInstance();
        expect(controller.account, isNull);
        expect(controller.walletOption, isNull);
        expect(controller.lastException?.code, NearErrorCode.accessKeyMismatch);
        expect(await keyStore.getKey(account.accountId), isNull);
        expect(prefs.getString(_optionPrefsKey), isNull);

        SharedPreferences.setMockInitialValues({});
        final hotPair = await KeyPairEd25519.generate();
        final hotAccount = WalletAccount(
          accountId: AccountId('failed.near'),
          publicKey: hotPair.publicKey,
        );
        final hotController = _testController(
          network: MyNearWalletNetwork.mainnet,
          security: _RecordingSecurity(
            verifyError: const NearSdkException(
              code: NearErrorCode.accessKeyNotFound,
              message: 'sanitized missing key',
            ),
          ),
          policy: const NearWalletSecurityPolicy(
            verifyAccessKeyOnConnect: true,
          ),
          hotWalletAdapterBuilder: (logger) =>
              _FakeHotWalletAdapter(account: hotAccount, logger: logger),
        );

        await hotController.connect(wallet: NearWalletOption.hot);

        final hotPrefs = await SharedPreferences.getInstance();
        expect(hotController.account, isNull);
        expect(hotController.walletOption, isNull);
        expect(
          hotController.lastException?.code,
          NearErrorCode.accessKeyNotFound,
        );
        expect(hotPrefs.getString(_optionPrefsKey), isNull);
        expect(hotPrefs.getString(_hotAccountPrefsKey), isNull);
        expect(hotPrefs.getString(_hotPublicKeyPrefsKey), isNull);
      },
    );

    test(
      'opt-in confirmation receives exact inputs and preserves list identity',
      () async {
        final pair = await KeyPairEd25519.generate();
        final account = WalletAccount(
          accountId: AccountId('sender.near'),
          publicKey: pair.publicKey,
        );
        final outcomes = <dynamic>[
          {'transactionHash': 'hash-one'},
        ];
        final security = _RecordingSecurity();
        final controller = _testController(
          network: MyNearWalletNetwork.mainnet,
          security: security,
          policy: const NearWalletSecurityPolicy(
            transactionFinality: TxExecutionStatus.final_,
          ),
          hotWalletAdapterBuilder: (logger) => _FakeHotWalletAdapter(
            account: account,
            outcomes: outcomes,
            logger: logger,
          ),
        );
        await controller.connect(wallet: NearWalletOption.hot);

        final result = await controller.sendTransactions(const []);

        expect(identical(result, outcomes), isTrue);
        expect(security.confirmations, hasLength(1));
        expect(
          security.confirmations.single.senderAccountId,
          account.accountId,
        );
        expect(
          security.confirmations.single.waitUntil,
          TxExecutionStatus.final_,
        );
        expect(
          identical(security.confirmations.single.outcomes, outcomes),
          isTrue,
        );
      },
    );

    test('default-off policy issues no verification or confirmation', () async {
      final pair = await KeyPairEd25519.generate();
      final account = WalletAccount(
        accountId: AccountId('default.near'),
        publicKey: pair.publicKey,
      );
      final security = _RecordingSecurity();
      final controller = _testController(
        network: MyNearWalletNetwork.mainnet,
        security: security,
        hotWalletAdapterBuilder: (logger) => _FakeHotWalletAdapter(
          account: account,
          outcomes: <dynamic>[
            {'hash': 'ignored'},
          ],
          logger: logger,
        ),
      );

      await controller.connect(wallet: NearWalletOption.hot);
      await controller.sendTransactions(const []);

      expect(security.verifications, isEmpty);
      expect(security.confirmations, isEmpty);
    });

    test(
      'all adapter builders receive exact logger and logs redact secrets',
      () async {
        final pair = await KeyPairEd25519.generate();
        final account = WalletAccount(
          accountId: AccountId('logger.near'),
          publicKey: pair.publicKey,
        );
        final keyStore = InMemoryKeyStore();
        final events = <NearLogEvent>[];
        void logger(NearLogEvent event) => events.add(event);
        final builderLoggers = <NearLogger?>[];
        final controller = _testController(
          network: MyNearWalletNetwork.mainnet,
          keyStore: keyStore,
          logger: logger,
          myNearWalletAdapterBuilder: (receivedLogger) {
            builderLoggers.add(receivedLogger);
            return _FakeMyNearWalletAdapter(
              keyStore: keyStore,
              logger: receivedLogger,
            );
          },
          intearWalletAdapterBuilder: (receivedLogger) {
            builderLoggers.add(receivedLogger);
            return _FakeIntearWalletAdapter(
              keyStore: keyStore,
              account: account,
              sessionKey: pair,
              logger: receivedLogger,
              emitSentinel: true,
            );
          },
          hotWalletAdapterBuilder: (receivedLogger) {
            builderLoggers.add(receivedLogger);
            return _FakeHotWalletAdapter(
              account: account,
              logger: receivedLogger,
              emitSentinel: true,
            );
          },
        );

        await controller.init();
        await controller.connect(wallet: NearWalletOption.intear);
        await controller.disconnect();
        await controller.connect(wallet: NearWalletOption.hot);

        expect(builderLoggers, hasLength(3));
        expect(
          builderLoggers.every((value) => identical(value, logger)),
          isTrue,
        );
        expect(events, isNotEmpty);
        expect(events.join('\n'), isNot(contains(_sentinelSecret)));
      },
    );
  });
}

class _CountingNearRpcClient extends NearRpcClient {
  _CountingNearRpcClient() : super(rpcUrl: 'https://rpc.invalid');

  int accessKeyCalls = 0;

  @override
  Future<RpcResult<AccessKeyView>> viewAccessKey({
    required AccountId accountId,
    required PublicKey publicKey,
    required BlockReference blockReference,
  }) async {
    accessKeyCalls++;
    throw StateError('Unexpected verification call');
  }
}

NearWalletController _testController({
  required MyNearWalletNetwork network,
  KeyStore? keyStore,
  NearWalletSecurity? security,
  NearWalletSecurityPolicy policy = const NearWalletSecurityPolicy(),
  NearLogger? logger,
  MyNearWalletAdapter Function(NearLogger? logger)? myNearWalletAdapterBuilder,
  IntearWalletAdapter Function(NearLogger? logger)? intearWalletAdapterBuilder,
  HotWalletAdapter Function(NearLogger? logger)? hotWalletAdapterBuilder,
}) {
  final resolvedKeyStore = keyStore ?? InMemoryKeyStore();
  return NearWalletController(
    network: network,
    contractId: AccountId(
      network == MyNearWalletNetwork.mainnet ? 'app.near' : 'app.testnet',
    ),
    methodNames: const ['call'],
    keyStore: resolvedKeyStore,
    client: _CountingNearRpcClient(),
    security: security ?? _RecordingSecurity(),
    securityPolicy: policy,
    logger: logger,
    myNearWalletAdapterBuilder: myNearWalletAdapterBuilder,
    intearWalletAdapterBuilder: intearWalletAdapterBuilder,
    hotWalletAdapterBuilder: hotWalletAdapterBuilder,
    initialLinkProvider: () async => null,
    linkStream: const Stream<Uri>.empty(),
  );
}

Future<WalletAccount> _storeAccount(KeyStore keyStore, String accountId) async {
  final pair = await KeyPairEd25519.generate();
  final id = AccountId(accountId);
  await keyStore.setKey(id, pair);
  return WalletAccount(accountId: id, publicKey: pair.publicKey);
}

class _VerificationCall {
  const _VerificationCall({
    required this.account,
    required this.contractId,
    required this.methodNames,
    required this.requireFunctionCallScope,
  });

  final WalletAccount account;
  final AccountId contractId;
  final List<String> methodNames;
  final bool requireFunctionCallScope;
}

class _ConfirmationCall {
  const _ConfirmationCall({
    required this.senderAccountId,
    required this.outcomes,
    required this.waitUntil,
  });

  final AccountId senderAccountId;
  final List<dynamic> outcomes;
  final TxExecutionStatus waitUntil;
}

class _RecordingSecurity extends NearWalletSecurity {
  _RecordingSecurity({this.verifyError, this.onVerify})
    : super(_CountingNearRpcClient());

  Object? verifyError;
  final void Function(_VerificationCall call)? onVerify;
  final List<_VerificationCall> verifications = [];
  final List<_ConfirmationCall> confirmations = [];

  @override
  Future<void> verifyAccessKey({
    required WalletAccount account,
    required AccountId contractId,
    required List<String> methodNames,
    required bool requireFunctionCallScope,
  }) async {
    final call = _VerificationCall(
      account: account,
      contractId: contractId,
      methodNames: methodNames,
      requireFunctionCallScope: requireFunctionCallScope,
    );
    verifications.add(call);
    onVerify?.call(call);
    final error = verifyError;
    if (error != null) throw error;
  }

  @override
  Future<void> confirmTransactions({
    required AccountId senderAccountId,
    required List<dynamic> outcomes,
    required TxExecutionStatus waitUntil,
  }) async {
    confirmations.add(
      _ConfirmationCall(
        senderAccountId: senderAccountId,
        outcomes: outcomes,
        waitUntil: waitUntil,
      ),
    );
  }
}

class _FakeMyNearWalletAdapter extends MyNearWalletAdapter {
  _FakeMyNearWalletAdapter({
    required KeyStore keyStore,
    this.accounts = const [],
    NearLogger? logger,
  }) : super(
         config: MyNearWalletConfig(
           contractId: AccountId('app.testnet'),
           successUrl: 'test://success',
           failureUrl: 'test://failure',
           network: MyNearWalletNetwork.testnet,
         ),
         keyStore: keyStore,
         launchUrl: (_) async => true,
         logger: logger,
       );

  final List<WalletAccount> accounts;

  @override
  Future<List<WalletAccount>> getAccounts() async => accounts;
}

class _FakeIntearWalletAdapter extends IntearWalletAdapter {
  _FakeIntearWalletAdapter({
    required KeyStore keyStore,
    required this.account,
    this.sessionKey,
    this.emitSentinel = false,
    NearLogger? logger,
  }) : super(
         config: const IntearWalletConfig(
           networkId: 'testnet',
           origin: 'test://app',
         ),
         keyStore: keyStore,
         launchUrl: (_) async => true,
         logger: logger,
       );

  final WalletAccount account;
  final KeyPairEd25519? sessionKey;
  final bool emitSentinel;

  @override
  Future<IntearConnectionResult> signIn({
    Nep413Payload? messageToSign,
    String? state,
  }) async {
    final key = sessionKey;
    if (key != null) await keyStore.setKey(account.accountId, key);
    if (emitSentinel) _emitSentinel(logger);
    return IntearConnectionResult(
      account: account,
      functionCallKeyAdded: true,
      walletUrl: 'https://wallet.invalid',
    );
  }

  @override
  Future<List<dynamic>> signAndSendTransactions({
    required AccountId accountId,
    required List<Map<String, dynamic>> transactions,
  }) async => const <dynamic>[];
}

class _FakeHotWalletAdapter extends HotWalletAdapter {
  _FakeHotWalletAdapter({
    required this.account,
    this.outcomes = const <dynamic>[],
    this.emitSentinel = false,
    NearLogger? logger,
  }) : super(
         config: const HotWalletConfig(origin: 'test://app'),
         launchUrl: (_) async => true,
         logger: logger,
       );

  final WalletAccount account;
  final List<dynamic> outcomes;
  final bool emitSentinel;

  @override
  Future<WalletAccount> signIn() async {
    if (emitSentinel) _emitSentinel(logger);
    return account;
  }

  @override
  Future<List<dynamic>> signAndSendTransactions({
    required List<Map<String, dynamic>> transactions,
  }) async => outcomes;
}

void _emitSentinel(NearLogger? logger) {
  logger?.call(
    NearLogEvent(
      level: NearLogLevel.info,
      type: NearLogEventType.walletFlowOpened,
      operation: 'fakeAdapter',
      metadata: const {
        'authorization': _sentinelSecret,
        'payload': _sentinelSecret,
        'wallet': 'fake',
      },
    ),
  );
}
