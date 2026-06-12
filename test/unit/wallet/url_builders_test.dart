/// Unit tests for MyNearWallet URL building.
///
/// Tests pure logic - no network calls required.
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('MyNearWalletConfig', () {
    test('mainnet config uses correct wallet URL', () {
      final config = MyNearWalletConfig(
        contractId: AccountId('app.near'),
        successUrl: 'https://myapp.com/success',
        failureUrl: 'https://myapp.com/failure',
        network: MyNearWalletNetwork.mainnet,
      );

      expect(config.walletUrl, equals('https://app.mynearwallet.com'));
    });

    test('testnet config uses correct wallet URL', () {
      final config = MyNearWalletConfig(
        contractId: AccountId('app.testnet'),
        successUrl: 'myapp://success',
        failureUrl: 'myapp://failure',
        network: MyNearWalletNetwork.testnet,
      );

      expect(config.walletUrl, equals('https://testnet.mynearwallet.com'));
    });

    test('default network is mainnet', () {
      final config = MyNearWalletConfig(
        contractId: AccountId('app.near'),
        successUrl: 'https://myapp.com/success',
        failureUrl: 'https://myapp.com/failure',
      );

      expect(config.network, equals(MyNearWalletNetwork.mainnet));
      expect(config.walletUrl, equals('https://app.mynearwallet.com'));
    });
  });

  group('MyNearWalletAdapter URL Building', () {
    late MyNearWalletAdapter mainnetAdapter;
    late MyNearWalletAdapter testnetAdapter;

    setUp(() {
      mainnetAdapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.near'),
          successUrl: 'https://app.com/callback/success',
          failureUrl: 'https://app.com/callback/failure',
          network: MyNearWalletNetwork.mainnet,
        ),
        launchUrl: (_) async => true,
      );

      testnetAdapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (_) async => true,
      );
    });

    group('buildSignInUrl', () {
      // near-api-js requestSignIn semantics: /login with success_url,
      // failure_url, contract_id, the REAL generated public_key (the
      // function-call access key being requested), and methodNames appended
      // as repeated query params. (The old code sent public_key='true',
      // which never provisions a usable key.)
      const fcPublicKey =
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj';

      test('builds mainnet sign-in URL with the real public key', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
          publicKey: PublicKey(fcPublicKey),
        );

        expect(url.scheme, equals('https'));
        expect(url.host, equals('app.mynearwallet.com'));
        expect(url.path, equals('/login'));
        expect(url.queryParameters['contract_id'], equals('dapp.near'));
        expect(url.queryParameters['public_key'], equals(fcPublicKey));
        expect(
          url.queryParameters['success_url'],
          equals('https://app.com/callback/success'),
        );
        expect(
          url.queryParameters['failure_url'],
          equals('https://app.com/callback/failure'),
        );
      });

      test('builds testnet sign-in URL', () {
        final url = testnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.testnet'),
          publicKey: PublicKey(fcPublicKey),
        );

        expect(url.host, equals('testnet.mynearwallet.com'));
        expect(url.queryParameters['contract_id'], equals('dapp.testnet'));
      });

      test('appends methodNames as repeated query params', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
          publicKey: PublicKey(fcPublicKey),
          methodNames: ['view_method', 'another_method'],
        );

        expect(
          url.queryParametersAll['methodNames'],
          equals(['view_method', 'another_method']),
        );
      });

      test('omits methodNames when empty', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
          publicKey: PublicKey(fcPublicKey),
        );

        expect(url.queryParameters.containsKey('methodNames'), isFalse);
        // public_key is always sent — it's the key being provisioned.
        expect(url.queryParameters['public_key'], equals(fcPublicKey));
      });
    });

    group('buildTransactionUrl', () {
      // MyNearWallet's /sign endpoint expects `transactions` to be a
      // comma-separated list of base64-encoded *Borsh-serialized* full
      // Transaction objects (each carrying publicKey, nonce and blockHash),
      // exactly like near-api-js. A JSON encoding cannot be processed.
      Transaction signableTx({
        required String receiver,
        required NearToken amount,
      }) => Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId(receiver),
        publicKey: PublicKey(
          'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
        ),
        nonce: BigInt.from(42),
        blockHash: const CryptoHash(
          '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM',
        ),
        actions: [TransferAction(deposit: amount)],
      );

      test('encodes a single transaction as base64 Borsh', () {
        final tx = signableTx(
          receiver: 'bob.near',
          amount: NearToken.fromNear(1),
        );

        final url = mainnetAdapter.buildTransactionUrl(transactions: [tx]);

        expect(url.scheme, equals('https'));
        expect(url.host, equals('app.mynearwallet.com'));
        expect(url.path, equals('/sign'));
        // Must be base64 of the Borsh bytes — NOT JSON.
        expect(
          url.queryParameters['transactions'],
          equals(base64Encode(serializeTransaction(tx))),
        );
        expect(
          url.queryParameters['callbackUrl'],
          equals('https://app.com/callback/success'),
        );
      });

      test('joins multiple transactions with commas, each base64 Borsh', () {
        final tx1 = signableTx(
          receiver: 'bob.near',
          amount: NearToken.fromNear(1),
        );
        final tx2 = signableTx(
          receiver: 'carol.near',
          amount: NearToken.fromNear(2),
        );

        final url = mainnetAdapter.buildTransactionUrl(
          transactions: [tx1, tx2],
        );

        final parts = url.queryParameters['transactions']!.split(',');
        expect(parts, hasLength(2));
        expect(parts[0], equals(base64Encode(serializeTransaction(tx1))));
        expect(parts[1], equals(base64Encode(serializeTransaction(tx2))));
      });

      test('uses custom callback URL when provided', () {
        final tx = signableTx(
          receiver: 'bob.near',
          amount: NearToken.fromNear(1),
        );

        final url = mainnetAdapter.buildTransactionUrl(
          transactions: [tx],
          callbackUrl: 'https://custom.callback.com/result',
        );

        expect(
          url.queryParameters['callbackUrl'],
          equals('https://custom.callback.com/result'),
        );
      });

      test('throws when a transaction lacks nonce/blockHash', () {
        // Without signing fields the transaction cannot be Borsh-serialized,
        // so the URL would be invalid — fail loudly instead of silently
        // producing something MyNearWallet rejects.
        final incomplete = Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
        );

        expect(
          () => mainnetAdapter.buildTransactionUrl(transactions: [incomplete]),
          throwsStateError,
        );
      });
    });

    group('buildSignMessageUrl', () {
      test('builds sign message URL with all params', () {
        final params = SignMessageParams(
          message: 'Hello, NEAR!',
          recipient: 'myapp.com',
          nonce: List.filled(32, 1),
          callbackUrl: 'https://myapp.com/signed',
          state: 'csrf-token-123',
        );

        final url = mainnetAdapter.buildSignMessageUrl(params);

        expect(url.scheme, equals('https'));
        expect(url.host, equals('app.mynearwallet.com'));
        expect(url.path, equals('/sign-message'));
        expect(url.queryParameters['message'], equals('Hello, NEAR!'));
        expect(url.queryParameters['recipient'], equals('myapp.com'));
        expect(url.queryParameters['nonce'], isNotEmpty);
        expect(
          url.queryParameters['callbackUrl'],
          equals('https://myapp.com/signed'),
        );
        expect(url.queryParameters['state'], equals('csrf-token-123'));
      });

      test('uses default callback when not provided', () {
        final params = SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(32, 0),
        );

        final url = mainnetAdapter.buildSignMessageUrl(params);

        expect(
          url.queryParameters['callbackUrl'],
          equals('https://app.com/callback/success'),
        );
      });

      test('omits state when not provided', () {
        final params = SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(32, 0),
        );

        final url = mainnetAdapter.buildSignMessageUrl(params);

        expect(url.queryParameters.containsKey('state'), isFalse);
      });

      test('nonce is base64 encoded', () {
        final nonce = List.generate(32, (i) => i);
        final params = SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: nonce,
        );

        final url = mainnetAdapter.buildSignMessageUrl(params);
        final encodedNonce = url.queryParameters['nonce']!;

        // Should be valid base64
        expect(() => base64Decode(encodedNonce), returnsNormally);
        expect(base64Decode(encodedNonce), equals(nonce));
      });
    });
  });

  group('MyNearWalletCallback', () {
    test('parses success callback with account info', () {
      final uri = Uri.parse(
        'myapp://callback?account_id=alice.near&public_key=ed25519:abc123&all_keys=key1,key2',
      );

      final callback = MyNearWalletCallback.fromUri(uri);

      expect(callback.isSuccess, isTrue);
      expect(callback.isError, isFalse);
      expect(callback.accountId, equals('alice.near'));
      expect(callback.publicKey, equals('ed25519:abc123'));
      expect(callback.allKeys, equals('key1,key2'));
    });

    test('parses error callback', () {
      final uri = Uri.parse(
        'myapp://callback?errorCode=user_cancelled&errorMessage=User%20cancelled%20the%20request',
      );

      final callback = MyNearWalletCallback.fromUri(uri);

      expect(callback.isSuccess, isFalse);
      expect(callback.isError, isTrue);
      expect(callback.errorCode, equals('user_cancelled'));
      expect(callback.errorMessage, equals('User cancelled the request'));
    });

    test('parses transaction callback with hashes', () {
      final uri = Uri.parse(
        'myapp://callback?transactionHashes=hash1,hash2,hash3',
      );

      final callback = MyNearWalletCallback.fromUri(uri);

      expect(callback.isSuccess, isTrue);
      expect(callback.transactionHashes, equals(['hash1', 'hash2', 'hash3']));
    });

    test('handles missing parameters gracefully', () {
      final uri = Uri.parse('myapp://callback');

      final callback = MyNearWalletCallback.fromUri(uri);

      expect(callback.isSuccess, isTrue);
      expect(callback.accountId, isNull);
      expect(callback.publicKey, isNull);
      expect(callback.transactionHashes, isNull);
    });
  });

  group('WalletAdapter properties', () {
    late MyNearWalletAdapter adapter;

    setUp(() {
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('test.near'),
          successUrl: 'https://test.com/success',
          failureUrl: 'https://test.com/failure',
        ),
        launchUrl: (_) async => true,
      );
    });

    test('has correct id', () {
      expect(adapter.id, equals('my-near-wallet'));
    });

    test('has correct type', () {
      expect(adapter.type, equals(WalletType.browser));
    });

    test('has correct name', () {
      expect(adapter.name, equals('MyNearWallet'));
    });

    test('has icon URL', () {
      expect(adapter.iconUrl, isNotNull);
      expect(adapter.iconUrl, contains('mynearwallet.com'));
    });
  });

  group('SignMessageParams validation', () {
    test('throws for invalid nonce length', () {
      expect(
        () => SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: [1, 2, 3], // Too short
        ),
        throwsArgumentError,
      );
    });

    test('throws for too long nonce', () {
      expect(
        () => SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(33, 0), // Too long
        ),
        throwsArgumentError,
      );
    });

    test('accepts exactly 32-byte nonce', () {
      expect(
        () => SignMessageParams(
          message: 'Test',
          recipient: 'test.com',
          nonce: List.filled(32, 0),
        ),
        returnsNormally,
      );
    });
  });
}
