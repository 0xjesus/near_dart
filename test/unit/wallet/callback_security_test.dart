/// Security-audit driven tests for wallet callback handling:
/// callback-origin validation, required public keys, and cryptographic
/// verification of sign-message results.
library;

import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  late MyNearWalletAdapter adapter;

  setUp(() {
    adapter = MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: AccountId('contract.testnet'),
        successUrl: 'myapp://wallet/success',
        failureUrl: 'myapp://wallet/failure',
        network: MyNearWalletNetwork.testnet,
      ),
      launchUrl: (_) async => true,
    );
  });

  group('completeSignIn callback validation', () {
    test('rejects a callback not on the configured URLs', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));

      // Same params, wrong deep-link path — must not complete the sign-in.
      final account = await adapter.completeSignIn(
        Uri.parse(
          'myapp://evil/path?account_id=attacker.testnet'
          '&public_key=ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(account, isNull);
      // The pending key survives a foreign URI (the real callback can still
      // arrive later).
      expect(await adapter.keyStore.getPendingKey(), isNotNull);
    });

    test('rejects a success callback missing the public key', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));

      final account = await adapter.completeSignIn(
        Uri.parse('myapp://wallet/success?account_id=alice.testnet'),
      );

      expect(account, isNull);
    });

    test('rejects a public key that is not the pending key', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));

      final account = await adapter.completeSignIn(
        Uri.parse(
          'myapp://wallet/success?account_id=alice.testnet'
          '&public_key=ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(account, isNull);
      expect(await adapter.keyStore.getPendingKey(), isNull);
    });

    test('accepts the matching pending key on the configured URL', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await adapter.keyStore.getPendingKey();

      final account = await adapter.completeSignIn(
        Uri.parse(
          'myapp://wallet/success?account_id=alice.testnet'
          '&public_key=${pending!.publicKey.value}',
        ),
      );

      expect(account, isNotNull);
      expect(account!.accountId.value, 'alice.testnet');
    });
  });

  group('handleSignMessageCallback required fields', () {
    test('throws when signature or publicKey is missing', () {
      expect(
        () => adapter.handleSignMessageCallback(
          Uri.parse('myapp://wallet/success#accountId=alice.testnet'),
        ),
        throwsA(
          allOf(
            isA<FormatException>(),
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.walletResponseInvalid,
            ),
          ),
        ),
      );
    });
  });

  group('completeSignMessage verification', () {
    late KeyPairEd25519 walletKey;
    late SignMessageParams request;

    setUp(() async {
      walletKey = await KeyPairEd25519.generate();
      request = SignMessageParams(
        message: 'Sign in to myapp.com',
        recipient: 'myapp.com',
        nonce: List<int>.generate(32, (i) => i),
        state: 'csrf-123',
      );
    });

    /// Signs [request] the way MyNearWallet does on a redirect flow — the
    /// callbackUrl (defaulted to successUrl) is part of the signed payload.
    Future<Uri> walletCallback({
      String? tamperMessage,
      String? state = 'csrf-123',
    }) async {
      final signed = await signNep413Message(
        payload: Nep413Payload(
          message: tamperMessage ?? request.message,
          recipient: request.recipient,
          nonce: request.nonce,
          callbackUrl: 'myapp://wallet/success',
        ),
        keyPair: walletKey,
        accountId: AccountId('alice.testnet'),
      );
      return Uri.parse(
        'myapp://wallet/success'
        '#accountId=alice.testnet'
        '&publicKey=${Uri.encodeComponent(walletKey.publicKey.value)}'
        '&signature=${Uri.encodeComponent(signed.signature)}'
        '${state != null ? '&state=${Uri.encodeComponent(state)}' : ''}',
      );
    }

    test('accepts a genuine wallet signature', () async {
      final signed = await adapter.completeSignMessage(
        await walletCallback(),
        request: request,
      );

      expect(signed.accountId.value, 'alice.testnet');
      expect(signed.publicKey.value, walletKey.publicKey.value);
      expect(base64Decode(signed.signature), hasLength(64));
    });

    test('rejects a signature over a different message', () async {
      final forged = await walletCallback(tamperMessage: 'Sign in to evil.com');

      expect(
        () => adapter.completeSignMessage(forged, request: request),
        throwsA(
          isA<SignatureVerificationException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.signatureVerificationFailed,
          ),
        ),
      );
    });

    test('rejects a state mismatch', () async {
      final wrongState = await walletCallback(state: 'other-state');

      expect(
        () => adapter.completeSignMessage(wrongState, request: request),
        throwsA(
          allOf(
            isA<FormatException>(),
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.walletResponseInvalid,
            ),
          ),
        ),
      );
    });
  });

  group('wallet diagnostics', () {
    test('logs callback receipt without callback values', () async {
      final events = <NearLogEvent>[];
      final loggingAdapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (_) async => true,
        logger: events.add,
      );
      await loggingAdapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await loggingAdapter.keyStore.getPendingKey();
      const callbackSecret = 'callback-secret-value';

      final account = await loggingAdapter.completeSignIn(
        Uri.parse(
          'myapp://wallet/success?account_id=$callbackSecret'
          '&public_key=${pending!.publicKey.value}#fragment-secret',
        ),
      );

      expect(account?.accountId.value, callbackSecret);
      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
        NearLogEventType.walletCallbackReceived,
      ]);
      expect(events.last.operation, 'signIn');
      expect(events.join(), isNot(contains(callbackSecret)));
      expect(events.join(), isNot(contains('fragment-secret')));
      for (final event in events) {
        expect(
          event.metadata.keys,
          everyElement(
            isIn(['walletId', 'durationMs', 'outcome', 'failureCode']),
          ),
        );
      }
    });

    test('types launch failure and ignores logger exceptions', () async {
      final failingAdapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (_) async => false,
        logger: (_) => throw StateError('logger failed'),
      );

      await expectLater(
        failingAdapter.signIn(contractId: AccountId('contract.testnet')),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.deepLinkUnavailable,
          ),
        ),
      );
    });

    test('does not copy callback values into transaction errors', () {
      const callbackCode = 'callback-code-secret';
      const callbackMessage = 'callback-message-secret';

      final result = adapter.handleTransactionCallback(
        Uri.parse(
          'myapp://wallet/failure?errorCode=$callbackCode'
          '&errorMessage=$callbackMessage',
        ),
      );
      final serialized = result.single.outcome.toJson().toString();

      expect(serialized, isNot(contains(callbackCode)));
      expect(serialized, isNot(contains(callbackMessage)));
    });
  });

  group('verifyNep413Signature', () {
    test('round trip verifies and tampering fails', () async {
      final key = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'hello',
        recipient: 'app.com',
        nonce: List<int>.filled(32, 7),
      );
      final signed = await signNep413Message(
        payload: payload,
        keyPair: key,
        accountId: AccountId('bob.testnet'),
      );

      expect(
        await verifyNep413Signature(payload: payload, signed: signed),
        isTrue,
      );

      final tampered = Nep413Payload(
        message: 'hello!',
        recipient: 'app.com',
        nonce: List<int>.filled(32, 7),
      );
      expect(
        await verifyNep413Signature(payload: tampered, signed: signed),
        isFalse,
      );
    });
  });

  group('AccountId protocol rules', () {
    test('rejects separator abuse', () {
      for (final bad in ['a..b', '.ab', 'ab.', '-ab', 'ab-', 'a--b', 'a-.b']) {
        expect(() => AccountId(bad), throwsArgumentError, reason: bad);
      }
    });

    test('accepts implicit and named accounts', () {
      for (final ok in [
        'f'.padRight(64, '0'), // implicit-style 64-char
        'alice.testnet',
        'a-b_c.near',
        '0x1234abc.factory.bridge.near',
      ]) {
        expect(() => AccountId(ok), returnsNormally, reason: ok);
      }
    });
  });
}
