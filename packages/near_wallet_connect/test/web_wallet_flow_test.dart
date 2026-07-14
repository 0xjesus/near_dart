@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';

@JS('window.history.replaceState')
external void _replaceHistoryState(JSAny? state, JSString title, JSString url);

void _replaceBrowserUrl(Uri uri) {
  _replaceHistoryState(null, ''.toJS, uri.toString().toJS);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesPlugin.registerWith(null);

  setUp(() async {
    await (await SharedPreferences.getInstance()).clear();
  });

  test(
    'completes a redirect after reload and restores the persisted session',
    () async {
      const namespace = 'web_redirect_test';
      final testRunnerUri = Uri.base;
      final origin = Uri(
        scheme: testRunnerUri.scheme,
        host: testRunnerUri.host,
        port: testRunnerUri.hasPort ? testRunnerUri.port : null,
      );
      final successUri = origin.resolve('/wallet/success');
      addTearDown(() {
        _replaceBrowserUrl(testRunnerUri);
        SharedPreferences.resetStatic();
      });

      final config = MyNearWalletConfig(
        contractId: AccountId('app.testnet'),
        successUrl: successUri.toString(),
        failureUrl: origin.resolve('/wallet/failure').toString(),
        network: MyNearWalletNetwork.testnet,
      );
      late Uri launched;
      final starter = MyNearWalletAdapter(
        config: config,
        keyStore: SharedPrefsKeyStore(namespace: namespace),
        launchUrl: (uri) async {
          launched = uri;
          return true;
        },
      );

      await starter.signIn(contractId: config.contractId);
      final successUrl = launched.queryParameters['success_url'];
      final publicKey = launched.queryParameters['public_key'];
      expect(successUrl, isNotNull);
      expect(publicKey, isNotNull);

      final callbackBase = Uri.parse(successUrl!);
      final callback = callbackBase.replace(
        queryParameters: {
          ...callbackBase.queryParameters,
          'account_id': 'alice.testnet',
          'public_key': publicKey!,
        },
      );

      // A reload creates a fresh SharedPreferences cache. The pending key must
      // be rehydrated from browser localStorage before the callback can pass.
      SharedPreferences.resetStatic();
      expect(
        await SharedPrefsKeyStore(namespace: namespace).getPendingKey(),
        isNotNull,
      );
      SharedPreferences.resetStatic();
      _replaceBrowserUrl(callback);
      expect(Uri.base.queryParameters['account_id'], 'alice.testnet');

      final callbackStore = SharedPrefsKeyStore(namespace: namespace);
      final callbackController = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: config.contractId,
        keyStore: callbackStore,
        myNearWalletAdapterBuilder: (_) => MyNearWalletAdapter(
          config: config,
          keyStore: callbackStore,
          launchUrl: (_) async => true,
        ),
      );
      await callbackController.init();
      final account = callbackController.account;
      expect(account?.accountId, AccountId('alice.testnet'));
      callbackController.dispose();

      // A second reload must recover both controller metadata and key material
      // from localStorage, without either previous in-memory cache.
      SharedPreferences.resetStatic();
      _replaceBrowserUrl(origin.resolve('/app'));
      final restoredStore = SharedPrefsKeyStore(namespace: namespace);
      final restoredController = NearWalletController(
        network: MyNearWalletNetwork.testnet,
        contractId: config.contractId,
        keyStore: restoredStore,
        myNearWalletAdapterBuilder: (_) => MyNearWalletAdapter(
          config: config,
          keyStore: restoredStore,
          launchUrl: (_) async => true,
        ),
      );
      await restoredController.init();
      expect(restoredController.account, account);
      expect(restoredController.walletOption, NearWalletOption.myNearWallet);
      restoredController.dispose();
    },
  );
}
