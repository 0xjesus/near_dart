import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
