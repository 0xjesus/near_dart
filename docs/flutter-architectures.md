# Flutter architecture recipes

`NearWalletController` is a `ChangeNotifier`, so it can be adapted to the
state-management library already used by an app. Add `near_wallet_connect` and
only the optional state-management dependency shown for the recipe you choose.
None of those libraries is bundled with `near_wallet_connect`.

The examples use testnet and a public example contract. They require no partner
credentials or API keys. Replace the contract ID and callback scheme with your
app's values, then complete the platform callback setup in the
[`near_wallet_connect` README](../packages/near_wallet_connect/README.md#platform-setup-one-time).

Initialization is asynchronous. Each recipe catches initialization failures and
keeps the controller alive until `init()` settles. For synchronous Flutter
disposal APIs, the state owner disposes itself immediately but defers
`NearWalletController.dispose()` until initialization finishes.

## ChangeNotifier (Flutter only)

This model owns the controller and relays its notifications. Its synchronous
`dispose()` detaches the relay and disposes the model immediately; controller
disposal happens asynchronously after the handled initialization future settles.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

class WalletModel extends ChangeNotifier {
  WalletModel()
    : controller = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('guestbook.near-examples.testnet'),
        callbackScheme: 'myapp',
      ) {
    controller.addListener(_relay);
    _initFuture = _initialize();
  }

  final NearWalletController controller;
  late final Future<void> _initFuture;
  bool _initializing = true;
  bool _disposeRequested = false;
  bool _controllerDisposed = false;
  NearSdkException? _initializationException;

  bool get initializing => _initializing;
  bool get controllerBusy => controller.busy;
  bool get busy => initializing || controllerBusy;
  WalletAccount? get account => controller.account;
  NearSdkException? get initializationException => _initializationException;
  NearSdkException? get controllerException => controller.lastException;

  Future<void> _initialize() async {
    try {
      await controller.init();
    } catch (error) {
      _initializationException = _safeInitializationException(error);
    } finally {
      _initializing = false;
      if (!_disposeRequested) notifyListeners();
    }
  }

  NearSdkException _safeInitializationException(Object error) {
    if (error is NearSdkException) return error;
    return const NearSdkException(
      code: NearErrorCode.unknown,
      message: 'Wallet initialization failed',
    );
  }

  void _relay() {
    if (!_disposeRequested) notifyListeners();
  }

  Future<void> _disposeControllerAfterInit() async {
    await _initFuture;
    if (_controllerDisposed) return;
    _controllerDisposed = true;
    controller.dispose();
  }

  @override
  void dispose() {
    if (_disposeRequested) return;
    _disposeRequested = true;
    controller.removeListener(_relay);
    super.dispose();
    unawaited(_disposeControllerAfterInit());
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletModel wallet;

  @override
  void initState() {
    super.initState();
    wallet = WalletModel();
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
        final initError = wallet.initializationException;
        final controllerError = wallet.controllerException;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wallet.busy) const LinearProgressIndicator(),
            Text(wallet.account?.accountId.value ?? 'Not connected'),
            if (initError != null)
              Text('${initError.code.name}: ${initError.message}'),
            if (controllerError != null)
              Text('${controllerError.code.name}: ${controllerError.message}'),
            NearConnectButton(controller: wallet.controller, showError: false),
          ],
        );
      },
    );
  }
}
```

## Provider

Add Provider separately with `flutter pub add provider`.
`ChangeNotifierProvider.create` owns and synchronously disposes the model. The
model defers only its controller disposal until initialization settles.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';
import 'package:provider/provider.dart';

class ProviderWalletModel extends ChangeNotifier {
  ProviderWalletModel()
    : controller = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('guestbook.near-examples.testnet'),
        callbackScheme: 'myapp',
      ) {
    controller.addListener(_relay);
    _initFuture = _initialize();
  }

  final NearWalletController controller;
  late final Future<void> _initFuture;
  bool _initializing = true;
  bool _disposeRequested = false;
  bool _controllerDisposed = false;
  NearSdkException? _initializationException;

  bool get initializing => _initializing;
  bool get controllerBusy => controller.busy;
  bool get busy => initializing || controllerBusy;
  WalletAccount? get account => controller.account;
  NearSdkException? get initializationException => _initializationException;
  NearSdkException? get controllerException => controller.lastException;

  Future<void> _initialize() async {
    try {
      await controller.init();
    } catch (error) {
      _initializationException = _safeInitializationException(error);
    } finally {
      _initializing = false;
      if (!_disposeRequested) notifyListeners();
    }
  }

  NearSdkException _safeInitializationException(Object error) {
    if (error is NearSdkException) return error;
    return const NearSdkException(
      code: NearErrorCode.unknown,
      message: 'Wallet initialization failed',
    );
  }

  void _relay() {
    if (!_disposeRequested) notifyListeners();
  }

  Future<void> _disposeControllerAfterInit() async {
    await _initFuture;
    if (_controllerDisposed) return;
    _controllerDisposed = true;
    controller.dispose();
  }

  @override
  void dispose() {
    if (_disposeRequested) return;
    _disposeRequested = true;
    controller.removeListener(_relay);
    super.dispose();
    unawaited(_disposeControllerAfterInit());
  }
}

class WalletFeature extends StatelessWidget {
  const WalletFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProviderWalletModel(),
      child: const WalletView(),
    );
  }
}

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<ProviderWalletModel>();
    final initError = wallet.initializationException;
    final controllerError = wallet.controllerException;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wallet.busy) const LinearProgressIndicator(),
        Text(wallet.account?.accountId.value ?? 'Not connected'),
        if (initError != null)
          Text('${initError.code.name}: ${initError.message}'),
        if (controllerError != null)
          Text('${controllerError.code.name}: ${controllerError.message}'),
        NearConnectButton(controller: wallet.controller, showError: false),
      ],
    );
  }
}
```

## Riverpod

Add Riverpod separately with `flutter pub add flutter_riverpod`. In Riverpod 3,
`ChangeNotifierProvider` is in `legacy.dart`. `autoDispose` synchronously
disposes the model after its last listener is removed; the model keeps its
controller alive until initialization settles and then disposes it once.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

class RiverpodWalletModel extends ChangeNotifier {
  RiverpodWalletModel()
    : controller = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('guestbook.near-examples.testnet'),
        callbackScheme: 'myapp',
      ) {
    controller.addListener(_relay);
    _initFuture = _initialize();
  }

  final NearWalletController controller;
  late final Future<void> _initFuture;
  bool _initializing = true;
  bool _disposeRequested = false;
  bool _controllerDisposed = false;
  NearSdkException? _initializationException;

  bool get initializing => _initializing;
  bool get controllerBusy => controller.busy;
  bool get busy => initializing || controllerBusy;
  WalletAccount? get account => controller.account;
  NearSdkException? get initializationException => _initializationException;
  NearSdkException? get controllerException => controller.lastException;

  Future<void> _initialize() async {
    try {
      await controller.init();
    } catch (error) {
      _initializationException = _safeInitializationException(error);
    } finally {
      _initializing = false;
      if (!_disposeRequested) notifyListeners();
    }
  }

  NearSdkException _safeInitializationException(Object error) {
    if (error is NearSdkException) return error;
    return const NearSdkException(
      code: NearErrorCode.unknown,
      message: 'Wallet initialization failed',
    );
  }

  void _relay() {
    if (!_disposeRequested) notifyListeners();
  }

  Future<void> _disposeControllerAfterInit() async {
    await _initFuture;
    if (_controllerDisposed) return;
    _controllerDisposed = true;
    controller.dispose();
  }

  @override
  void dispose() {
    if (_disposeRequested) return;
    _disposeRequested = true;
    controller.removeListener(_relay);
    super.dispose();
    unawaited(_disposeControllerAfterInit());
  }
}

final walletProvider = ChangeNotifierProvider.autoDispose<RiverpodWalletModel>(
  (ref) => RiverpodWalletModel(),
);

void main() => runApp(const ProviderScope(child: WalletApp()));

class WalletApp extends ConsumerWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final initError = wallet.initializationException;
    final controllerError = wallet.controllerException;
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wallet.busy) const LinearProgressIndicator(),
            Text(wallet.account?.accountId.value ?? 'Not connected'),
            if (initError != null)
              Text('${initError.code.name}: ${initError.message}'),
            if (controllerError != null)
              Text('${controllerError.code.name}: ${controllerError.message}'),
            NearConnectButton(controller: wallet.controller, showError: false),
          ],
        ),
      ),
    );
  }
}
```

## Bloc/Cubit

Add Bloc separately with `flutter pub add flutter_bloc`. The Cubit converts
controller notifications into immutable snapshots. `close()` becomes closing
immediately, detaches the relay, waits for the handled initialization future,
then disposes the controller exactly once before closing the Cubit.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

class WalletState {
  const WalletState({
    required this.initializing,
    required this.controllerBusy,
    this.account,
    this.initializationException,
    this.controllerException,
  });

  const WalletState.initial()
    : initializing = true,
      controllerBusy = false,
      account = null,
      initializationException = null,
      controllerException = null;

  final bool initializing;
  final bool controllerBusy;
  final WalletAccount? account;
  final NearSdkException? initializationException;
  final NearSdkException? controllerException;

  bool get busy => initializing || controllerBusy;
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit()
    : controller = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: AccountId('guestbook.near-examples.testnet'),
        callbackScheme: 'myapp',
      ),
      super(const WalletState.initial()) {
    controller.addListener(_publish);
    _initFuture = _initialize();
  }

  final NearWalletController controller;
  late final Future<void> _initFuture;
  Future<void>? _closeFuture;
  bool _initializing = true;
  bool _closing = false;
  bool _controllerDisposed = false;
  NearSdkException? _initializationException;

  Future<void> _initialize() async {
    try {
      await controller.init();
    } catch (error) {
      _initializationException = _safeInitializationException(error);
    } finally {
      _initializing = false;
      _publish();
    }
  }

  NearSdkException _safeInitializationException(Object error) {
    if (error is NearSdkException) return error;
    return const NearSdkException(
      code: NearErrorCode.unknown,
      message: 'Wallet initialization failed',
    );
  }

  void _publish() {
    if (_closing || isClosed) return;
    emit(
      WalletState(
        initializing: _initializing,
        controllerBusy: controller.busy,
        account: controller.account,
        initializationException: _initializationException,
        controllerException: controller.lastException,
      ),
    );
  }

  void _disposeControllerOnce() {
    if (_controllerDisposed) return;
    _controllerDisposed = true;
    controller.dispose();
  }

  @override
  Future<void> close() async {
    final activeClose = _closeFuture;
    if (activeClose != null) {
      await activeClose;
      return;
    }
    final completer = Completer<void>();
    _closeFuture = completer.future;
    _closing = true;
    controller.removeListener(_publish);
    try {
      try {
        await _initFuture;
        _disposeControllerOnce();
      } finally {
        await super.close();
      }
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
    await completer.future;
  }
}

class WalletFeature extends StatelessWidget {
  const WalletFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(),
      child: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          final cubit = context.read<WalletCubit>();
          final initError = state.initializationException;
          final controllerError = state.controllerException;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.busy) const LinearProgressIndicator(),
              Text(state.account?.accountId.value ?? 'Not connected'),
              if (initError != null)
                Text('${initError.code.name}: ${initError.message}'),
              if (controllerError != null)
                Text(
                  '${controllerError.code.name}: ${controllerError.message}',
                ),
              NearConnectButton(controller: cubit.controller, showError: false),
            ],
          );
        },
      ),
    );
  }
}
```
