# Flutter architecture recipes

`NearWalletController` is a `ChangeNotifier`, so it can be used directly or
adapted to the state-management library already used by an app. Add
`near_wallet_connect` and only the optional state-management dependency shown
for the recipe you choose. None of those libraries is bundled with
`near_wallet_connect`.

The examples use testnet and a public example contract. They require no partner
credentials or API keys. Replace the contract ID and callback scheme with your
app's values, then complete the platform callback setup in the
[`near_wallet_connect` README](../packages/near_wallet_connect/README.md#platform-setup-one-time).

## ChangeNotifier (Flutter only)

`NearWalletController` already implements `ChangeNotifier`. A stateful widget
can own it directly, initialize it once, and dispose it with the widget.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final NearWalletController wallet;

  @override
  void initState() {
    super.initState();
    wallet = NearWalletController(
      network: MyNearWalletNetwork.testnet,
      contractId: AccountId('guestbook.near-examples.testnet'),
      callbackScheme: 'myapp',
    );
    unawaited(wallet.init());
  }

  @override
  void dispose() {
    wallet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        final exception = wallet.lastException;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wallet.busy) const LinearProgressIndicator(),
            Text(wallet.account?.accountId.value ?? 'Not connected'),
            if (exception != null)
              Text('${exception.code.name}: ${exception.message}'),
            NearConnectButton(controller: wallet, showError: false),
          ],
        );
      },
    );
  }
}
```

## Provider

Add Provider separately with `flutter pub add provider`. Creating the controller
inside `ChangeNotifierProvider.create` makes Provider responsible for disposing
it when the subtree is removed.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';
import 'package:provider/provider.dart';

class WalletFeature extends StatelessWidget {
  const WalletFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final wallet = NearWalletController(
          network: MyNearWalletNetwork.testnet,
          contractId: AccountId('guestbook.near-examples.testnet'),
          callbackScheme: 'myapp',
        );
        unawaited(wallet.init());
        return wallet;
      },
      child: const WalletView(),
    );
  }
}

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<NearWalletController>();
    final exception = wallet.lastException;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wallet.busy) const LinearProgressIndicator(),
        Text(wallet.account?.accountId.value ?? 'Not connected'),
        if (exception != null)
          Text('${exception.code.name}: ${exception.message}'),
        NearConnectButton(controller: wallet, showError: false),
      ],
    );
  }
}
```

## Riverpod

Add Riverpod separately with `flutter pub add flutter_riverpod`. In Riverpod 3,
`ChangeNotifierProvider` is in `legacy.dart`; it remains the direct adapter for
an existing `ChangeNotifier`. `autoDispose` disposes the controller when its
last listener is removed.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

final walletProvider =
    ChangeNotifierProvider.autoDispose<NearWalletController>((ref) {
      final wallet = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('guestbook.near-examples.testnet'),
        callbackScheme: 'myapp',
      );
      unawaited(wallet.init());
      return wallet;
    });

void main() => runApp(const ProviderScope(child: WalletApp()));

class WalletApp extends ConsumerWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final exception = wallet.lastException;
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wallet.busy) const LinearProgressIndicator(),
            Text(wallet.account?.accountId.value ?? 'Not connected'),
            if (exception != null)
              Text('${exception.code.name}: ${exception.message}'),
            NearConnectButton(controller: wallet, showError: false),
          ],
        ),
      ),
    );
  }
}
```

## Bloc/Cubit

Add Bloc separately with `flutter pub add flutter_bloc`. The Cubit below owns
the controller, converts notifications into immutable snapshots, and disposes
the controller from `close()`. `BlocProvider.create` closes the Cubit with its
subtree.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

class WalletState {
  const WalletState({
    required this.busy,
    this.account,
    this.exception,
  });

  final bool busy;
  final WalletAccount? account;
  final NearSdkException? exception;
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit()
    : controller = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('guestbook.near-examples.testnet'),
        callbackScheme: 'myapp',
      ),
      super(const WalletState(busy: true));

  final NearWalletController controller;

  Future<void> init() async {
    controller.addListener(_publish);
    try {
      await controller.init();
      _publish();
    } catch (error) {
      final exception = error is NearSdkException
          ? error
          : const NearSdkException(
              code: NearErrorCode.unknown,
              message: 'Wallet initialization failed',
            );
      if (!isClosed) {
        emit(WalletState(busy: false, exception: exception));
      }
    }
  }

  void _publish() {
    if (isClosed) return;
    emit(
      WalletState(
        busy: controller.busy,
        account: controller.account,
        exception: controller.lastException,
      ),
    );
  }

  @override
  Future<void> close() {
    controller.removeListener(_publish);
    controller.dispose();
    return super.close();
  }
}

class WalletFeature extends StatelessWidget {
  const WalletFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit()..init(),
      child: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          final cubit = context.read<WalletCubit>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.busy) const LinearProgressIndicator(),
              Text(state.account?.accountId.value ?? 'Not connected'),
              if (state.exception case final exception?)
                Text('${exception.code.name}: ${exception.message}'),
              NearConnectButton(
                controller: cubit.controller,
                showError: false,
              ),
            ],
          );
        },
      ),
    );
  }
}
```
