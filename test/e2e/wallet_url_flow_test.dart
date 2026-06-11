/// End-to-end tests for wallet URL flow.
///
/// Tests the complete flow of URL building, launching, and callback handling.
/// NO MOCKS - Uses real URL building and parsing logic.
@Tags(['e2e'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('E2E: MyNearWallet Sign-In Flow', () {
    late MyNearWalletAdapter adapter;
    late List<Uri> launchedUrls;

    setUp(() {
      launchedUrls = [];
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('dapp.near'),
          successUrl: 'https://myapp.com/wallet/success',
          failureUrl: 'https://myapp.com/wallet/failure',
          network: MyNearWalletNetwork.mainnet,
        ),
        launchUrl: (uri) async {
          launchedUrls.add(uri);
          return true;
        },
      );
    });

    test('complete sign-in URL flow', () async {
      // Step 1: Build sign-in URL
      final signInUrl = adapter.buildSignInUrl(
        contractId: AccountId('app.near'),
        methodNames: ['view_method'],
      );

      // Verify URL structure
      expect(signInUrl.scheme, equals('https'));
      expect(signInUrl.host, equals('app.mynearwallet.com'));
      expect(signInUrl.path, equals('/login'));
      expect(signInUrl.queryParameters['contract_id'], equals('app.near'));
      expect(
        signInUrl.queryParameters['success_url'],
        equals('https://myapp.com/wallet/success'),
      );
      expect(
        signInUrl.queryParameters['failure_url'],
        equals('https://myapp.com/wallet/failure'),
      );

      // Step 2: Simulate wallet callback (success)
      final successCallback = Uri.parse(
        'https://myapp.com/wallet/success?account_id=alice.near&public_key=ed25519:abc123',
      );
      final callback = adapter.handleCallback(successCallback);

      // Step 3: Verify callback parsing
      expect(callback.isSuccess, isTrue);
      expect(callback.accountId, equals('alice.near'));
      expect(callback.publicKey, equals('ed25519:abc123'));

      // Step 4: Verify adapter state
      final accounts = await adapter.getAccounts();
      expect(accounts.length, equals(1));
      expect(accounts.first.accountId.value, equals('alice.near'));
    });

    test('sign-in error callback handling', () {
      // Simulate error callback
      final errorCallback = Uri.parse(
        'https://myapp.com/wallet/failure?errorCode=user_cancelled&errorMessage=User%20rejected%20the%20request',
      );
      final callback = adapter.handleCallback(errorCallback);

      expect(callback.isError, isTrue);
      expect(callback.errorCode, equals('user_cancelled'));
      expect(callback.errorMessage, equals('User rejected the request'));
    });
  });

  group('E2E: MyNearWallet Transaction Flow', () {
    late MyNearWalletAdapter adapter;
    late List<Uri> launchedUrls;

    setUp(() {
      launchedUrls = [];
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('app.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedUrls.add(uri);
          return true;
        },
      );
    });

    test('complete transfer transaction URL flow', () {
      // Step 1: Create a fully-formed transfer transaction (MyNearWallet
      // signs it, so it must carry publicKey, nonce and blockHash).
      final transaction = Transaction(
        signerId: AccountId('alice.testnet'),
        receiverId: AccountId('bob.testnet'),
        publicKey: PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
        nonce: BigInt.from(7),
        blockHash: const CryptoHash(
          '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM',
        ),
        actions: [TransferAction(deposit: NearToken.fromNear(5))],
      );

      // Step 2: Build transaction URL
      final txUrl = adapter.buildTransactionUrl(
        transactions: [transaction],
        callbackUrl: 'myapp://tx/result',
      );

      // Verify URL structure
      expect(txUrl.scheme, equals('https'));
      expect(txUrl.host, equals('testnet.mynearwallet.com'));
      expect(txUrl.path, equals('/sign'));
      expect(txUrl.queryParameters['callbackUrl'], equals('myapp://tx/result'));

      // Step 3: The transactions param is base64 Borsh (what MyNearWallet
      // actually consumes), not JSON.
      expect(
        txUrl.queryParameters['transactions'],
        equals(base64Encode(serializeTransaction(transaction))),
      );

      // Step 4: Simulate success callback with transaction hash
      final successCallback = Uri.parse(
        'myapp://tx/result?transactionHashes=hash123abc',
      );
      final results = adapter.handleTransactionCallback(successCallback);

      expect(results.length, equals(1));
      expect(results.first.transactionHash.value, equals('hash123abc'));
    });

    test('multiple transactions URL flow', () {
      const publicKey = 'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj';
      const blockHash = '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM';
      Transaction tx(String receiver, List<Action> actions) => Transaction(
        signerId: AccountId('alice.testnet'),
        receiverId: AccountId(receiver),
        publicKey: PublicKey(publicKey),
        nonce: BigInt.from(7),
        blockHash: const CryptoHash(blockHash),
        actions: actions,
      );

      final transactions = [
        tx('bob.testnet', [TransferAction(deposit: NearToken.fromNear(1))]),
        tx('carol.testnet', [TransferAction(deposit: NearToken.fromNear(2))]),
        tx('contract.testnet', [
          FunctionCallAction(
            methodName: 'do_something',
            args: {'param': 'value'},
            deposit: NearToken.zero(),
          ),
        ]),
      ];

      final txUrl = adapter.buildTransactionUrl(transactions: transactions);

      // Comma-separated base64 Borsh, one entry per transaction.
      final parts = txUrl.queryParameters['transactions']!.split(',');
      expect(parts, hasLength(3));
      for (var i = 0; i < transactions.length; i++) {
        expect(
          parts[i],
          equals(base64Encode(serializeTransaction(transactions[i]))),
        );
      }

      // Simulate callback with multiple hashes
      final callback = Uri.parse(
        'myapp://wallet/success?transactionHashes=hash1,hash2,hash3',
      );
      final results = adapter.handleTransactionCallback(callback);

      expect(results.length, equals(3));
      expect(results[0].transactionHash.value, equals('hash1'));
      expect(results[1].transactionHash.value, equals('hash2'));
      expect(results[2].transactionHash.value, equals('hash3'));
    });

    test('transaction error callback handling', () {
      final errorCallback = Uri.parse(
        'myapp://wallet/failure?errorCode=rejected&errorMessage=Transaction%20rejected',
      );
      final results = adapter.handleTransactionCallback(errorCallback);

      expect(results.length, equals(1));
      // Error result has empty hash
      expect(results.first.transactionHash.value, equals(''));
    });
  });

  group('E2E: MyNearWallet Sign Message Flow', () {
    late MyNearWalletAdapter adapter;

    setUp(() {
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('app.near'),
          successUrl: 'https://myapp.com/signed',
          failureUrl: 'https://myapp.com/failed',
        ),
        launchUrl: (_) async => true,
      );
    });

    test('complete sign message URL flow', () {
      // Create sign message params
      final nonce = List.generate(32, (i) => i);
      final params = SignMessageParams(
        message: 'Please sign this message to authenticate',
        recipient: 'myapp.com',
        nonce: nonce,
        callbackUrl: 'https://myapp.com/auth/callback',
        state: 'csrf-token-12345',
      );

      // Build sign message URL
      final url = adapter.buildSignMessageUrl(params);

      expect(url.path, equals('/sign-message'));
      expect(
        url.queryParameters['message'],
        equals('Please sign this message to authenticate'),
      );
      expect(url.queryParameters['recipient'], equals('myapp.com'));
      expect(url.queryParameters['state'], equals('csrf-token-12345'));

      // Verify nonce is base64 encoded correctly
      final encodedNonce = url.queryParameters['nonce']!;
      final decodedNonce = base64Decode(encodedNonce);
      expect(decodedNonce, equals(nonce));

      // Simulate callback
      final callbackUri = Uri.parse(
        'https://myapp.com/auth/callback?accountId=alice.near&publicKey=ed25519:abc&signature=sig123&state=csrf-token-12345',
      );
      final signedMessage = adapter.handleSignMessageCallback(callbackUri);

      expect(signedMessage.accountId.value, equals('alice.near'));
      expect(signedMessage.publicKey.value, equals('ed25519:abc'));
      expect(signedMessage.signature, equals('sig123'));
      expect(signedMessage.state, equals('csrf-token-12345'));
    });
  });

  group('E2E: Full Wallet Session Flow', () {
    test('sign in -> get accounts -> sign out flow', () async {
      final adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('dapp.near'),
          successUrl: 'https://dapp.com/success',
          failureUrl: 'https://dapp.com/failure',
        ),
        launchUrl: (_) async => true,
      );

      // Initially not signed in
      expect(await adapter.isSignedIn(), isFalse);
      expect(await adapter.getAccounts(), isEmpty);

      // Simulate sign-in callback
      adapter.handleCallback(
        Uri.parse(
          'https://dapp.com/success?account_id=user.near&public_key=ed25519:xyz',
        ),
      );

      // Now signed in
      expect(await adapter.isSignedIn(), isTrue);
      final accounts = await adapter.getAccounts();
      expect(accounts.length, equals(1));
      expect(accounts.first.accountId.value, equals('user.near'));

      // Sign out
      await adapter.signOut();

      // No longer signed in
      expect(await adapter.isSignedIn(), isFalse);
      expect(await adapter.getAccounts(), isEmpty);
    });

    test('set account directly', () async {
      final adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('dapp.near'),
          successUrl: 'https://dapp.com/success',
          failureUrl: 'https://dapp.com/failure',
        ),
        launchUrl: (_) async => true,
      );

      // Set account directly (e.g., restoring from storage)
      adapter.setAccount(
        WalletAccount(
          accountId: AccountId('restored.near'),
          publicKey: PublicKey('ed25519:restoredKey'),
        ),
      );

      expect(await adapter.isSignedIn(), isTrue);
      final accounts = await adapter.getAccounts();
      expect(accounts.first.accountId.value, equals('restored.near'));
    });
  });

  group('E2E: Network Configuration', () {
    test('mainnet uses correct URLs', () {
      final adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('app.near'),
          successUrl: 'https://app.com/success',
          failureUrl: 'https://app.com/failure',
          network: MyNearWalletNetwork.mainnet,
        ),
        launchUrl: (_) async => true,
      );

      final url = adapter.buildSignInUrl(contractId: AccountId('app.near'));
      expect(url.host, equals('app.mynearwallet.com'));
    });

    test('testnet uses correct URLs', () {
      final adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('app.testnet'),
          successUrl: 'https://app.com/success',
          failureUrl: 'https://app.com/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (_) async => true,
      );

      final url = adapter.buildSignInUrl(contractId: AccountId('app.testnet'));
      expect(url.host, equals('testnet.mynearwallet.com'));
    });
  });
}
