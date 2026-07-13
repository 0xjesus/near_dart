import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:near_dart/near_dart.dart'
    show AccessKeyView, BlockReference, PublicKey, RpcResult;
import 'package:near_wallet_connect/near_wallet_connect.dart';

void main() {
  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

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
