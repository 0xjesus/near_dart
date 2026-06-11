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
      test('builds mainnet sign-in URL', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
        );

        expect(url.scheme, equals('https'));
        expect(url.host, equals('app.mynearwallet.com'));
        expect(url.path, equals('/login'));
        expect(url.queryParameters['contract_id'], equals('dapp.near'));
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
        );

        expect(url.host, equals('testnet.mynearwallet.com'));
        expect(url.queryParameters['contract_id'], equals('dapp.testnet'));
      });

      test('includes public_key when methodNames provided', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
          methodNames: ['view_method', 'another_method'],
        );

        expect(url.queryParameters['public_key'], equals('true'));
      });

      test('omits public_key when methodNames is empty', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
          methodNames: [],
        );

        expect(url.queryParameters.containsKey('public_key'), isFalse);
      });

      test('omits public_key when methodNames is null', () {
        final url = mainnetAdapter.buildSignInUrl(
          contractId: AccountId('dapp.near'),
        );

        expect(url.queryParameters.containsKey('public_key'), isFalse);
      });
    });

    group('buildTransactionUrl', () {
      test('builds single transaction URL', () {
        final tx = Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
        );

        final url = mainnetAdapter.buildTransactionUrl(transactions: [tx]);

        expect(url.scheme, equals('https'));
        expect(url.host, equals('app.mynearwallet.com'));
        expect(url.path, equals('/sign'));
        expect(url.queryParameters.containsKey('transactions'), isTrue);
        expect(
          url.queryParameters['callbackUrl'],
          equals('https://app.com/callback/success'),
        );
      });

      test('builds multiple transactions URL', () {
        final tx1 = Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
        );
        final tx2 = Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('carol.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(2))],
        );

        final url = mainnetAdapter.buildTransactionUrl(
          transactions: [tx1, tx2],
        );

        final txData = jsonDecode(url.queryParameters['transactions']!) as List;
        expect(txData.length, equals(2));
        expect(txData[0]['receiverId'], equals('bob.near'));
        expect(txData[1]['receiverId'], equals('carol.near'));
      });

      test('uses custom callback URL when provided', () {
        final tx = Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
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

      test('encodes function call action correctly', () {
        final tx = Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('contract.near'),
          actions: [
            FunctionCallAction(
              methodName: 'my_method',
              args: {'key': 'value'},
              deposit: NearToken.zero(),
            ),
          ],
        );

        final url = mainnetAdapter.buildTransactionUrl(transactions: [tx]);
        final txData = jsonDecode(url.queryParameters['transactions']!) as List;

        expect(txData[0]['receiverId'], equals('contract.near'));
        expect(txData[0]['actions'], isA<List>());
        expect(txData[0]['actions'].length, equals(1));
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
