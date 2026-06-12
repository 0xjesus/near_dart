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

    test(
      'complete sign-in flow provisions and stores a function-call key',
      () async {
        // Step 1: signIn generates a function-call key and launches /login
        // with the key's REAL public key.
        await adapter.signIn(
          contractId: AccountId('app.near'),
          methodNames: ['view_method'],
        );

        expect(launchedUrls, hasLength(1));
        final loginUrl = launchedUrls.single;
        expect(loginUrl.path, equals('/login'));
        expect(loginUrl.queryParameters['contract_id'], equals('app.near'));
        final provisionedKey = loginUrl.queryParameters['public_key']!;
        expect(provisionedKey, startsWith('ed25519:'));
        expect(provisionedKey, isNot(equals('ed25519:true')));
        expect(
          loginUrl.queryParametersAll['methodNames'],
          equals(['view_method']),
        );

        // Step 2: the wallet redirects back with the account and the key it
        // provisioned.
        final account = await adapter.completeSignIn(
          Uri.parse(
            'https://myapp.com/wallet/success'
            '?account_id=alice.near&public_key=$provisionedKey',
          ),
        );

        // Step 3: the account is connected and its private key is stored, so
        // later calls can be signed locally with no redirect.
        expect(account, isNotNull);
        expect(account!.accountId.value, equals('alice.near'));
        expect(account.publicKey.value, equals(provisionedKey));

        final stored = await adapter.keyFor(AccountId('alice.near'));
        expect(stored, isNotNull);
        expect(stored!.publicKey.value, equals(provisionedKey));

        final accounts = await adapter.getAccounts();
        expect(accounts.single.accountId.value, equals('alice.near'));
        // The pending key was consumed.
        expect(await adapter.keyStore.getPendingKey(), isNull);
      },
    );

    test('completeSignIn rejects a mismatched provisioned key', () async {
      await adapter.signIn(contractId: AccountId('app.near'));

      // Wallet returns a different public key than the one we generated.
      final account = await adapter.completeSignIn(
        Uri.parse(
          'https://myapp.com/wallet/success'
          '?account_id=alice.near&public_key=ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
      );

      expect(account, isNull);
      expect(await adapter.isSignedIn(), isFalse);
    });

    test('completeSignIn returns null on a failure callback', () async {
      await adapter.signIn(contractId: AccountId('app.near'));
      final account = await adapter.completeSignIn(
        Uri.parse('https://myapp.com/wallet/failure?errorCode=user_cancelled'),
      );
      expect(account, isNull);
      expect(await adapter.isSignedIn(), isFalse);
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
      final launchedUrls = <Uri>[];
      final adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('dapp.near'),
          successUrl: 'https://dapp.com/success',
          failureUrl: 'https://dapp.com/failure',
        ),
        launchUrl: (uri) async {
          launchedUrls.add(uri);
          return true;
        },
      );

      // Initially not signed in
      expect(await adapter.isSignedIn(), isFalse);
      expect(await adapter.getAccounts(), isEmpty);

      // Sign in: generate key -> launch -> complete from the callback.
      await adapter.signIn(contractId: AccountId('dapp.near'));
      final key = launchedUrls.single.queryParameters['public_key']!;
      await adapter.completeSignIn(
        Uri.parse(
          'https://dapp.com/success?account_id=user.near&public_key=$key',
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

    test('restores the connection from a persisted key store', () async {
      // Simulate a previous session: the key store already holds the
      // function-call key for an account (what a SecureStorageKeyStore would
      // load on app start).
      final keyStore = InMemoryKeyStore();
      final keyPair = await KeyPairEd25519.fromSeed(List.filled(32, 9));
      await keyStore.setKey(AccountId('restored.near'), keyPair);

      final adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('dapp.near'),
          successUrl: 'https://dapp.com/success',
          failureUrl: 'https://dapp.com/failure',
        ),
        launchUrl: (_) async => true,
        keyStore: keyStore,
      );

      expect(await adapter.isSignedIn(), isTrue);
      final accounts = await adapter.getAccounts();
      expect(accounts.first.accountId.value, equals('restored.near'));
      expect(accounts.first.publicKey, equals(keyPair.publicKey));
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

      final url = adapter.buildSignInUrl(
        contractId: AccountId('app.near'),
        publicKey: PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
      );
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

      final url = adapter.buildSignInUrl(
        contractId: AccountId('app.testnet'),
        publicKey: PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
      );
      expect(url.host, equals('testnet.mynearwallet.com'));
    });
  });
}
