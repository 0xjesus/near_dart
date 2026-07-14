/// Security-audit driven tests for wallet callback handling:
/// callback-origin validation, required public keys, and cryptographic
/// verification of sign-message results.
library;

import 'dart:async';
import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  late MyNearWalletAdapter adapter;
  late List<Uri> launchedWalletUrls;

  setUp(() {
    launchedWalletUrls = <Uri>[];
    adapter = MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: AccountId('contract.testnet'),
        successUrl: 'myapp://wallet/success',
        failureUrl: 'myapp://wallet/failure',
        network: MyNearWalletNetwork.testnet,
      ),
      launchUrl: (uri) async {
        launchedWalletUrls.add(uri);
        return true;
      },
    );
  });

  Uri launchedCallback(String parameter) {
    return Uri.parse(launchedWalletUrls.last.queryParameters[parameter]!);
  }

  Uri withQuery(Uri callback, Map<String, String> values) {
    return callback.replace(
      queryParameters: <String, Object>{
        ...callback.queryParametersAll,
        ...values,
      },
    );
  }

  Uri withFragment(Uri callback, Map<String, String> values) {
    final configured = callback.fragment.isEmpty
        ? const <String, String>{}
        : Uri.splitQueryString(callback.fragment);
    return callback.replace(
      fragment: Uri(
        queryParameters: <String, String>{...configured, ...values},
      ).query,
    );
  }

  Future<void> beginSignMessage(SignMessageParams request) async {
    await expectLater(
      adapter.signMessage(request),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.missingCallback,
        ),
      ),
    );
  }

  Future<void> beginTransactions({String? callbackUrl}) async {
    await expectLater(
      adapter.signAndSendTransactions(
        transactions: const <Transaction>[],
        callbackUrl: callbackUrl,
      ),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.missingCallback,
        ),
      ),
    );
  }

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
        withQuery(launchedCallback('success_url'), {
          'account_id': 'alice.testnet',
        }),
      );

      expect(account, isNull);
    });

    test('rejects a public key that is not the pending key', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));

      final account = await adapter.completeSignIn(
        withQuery(launchedCallback('success_url'), {
          'account_id': 'alice.testnet',
          'public_key': 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        }),
      );

      expect(account, isNull);
      expect(await adapter.keyStore.getPendingKey(), isNull);
    });

    test('accepts the matching pending key on the configured URL', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await adapter.keyStore.getPendingKey();

      final account = await adapter.completeSignIn(
        withQuery(launchedCallback('success_url'), {
          'account_id': 'alice.testnet',
          'public_key': pending!.publicKey.value,
        }),
      );

      expect(account, isNotNull);
      expect(account!.accountId.value, 'alice.testnet');
    });

    test('foreign callback does not consume the pending sign-in', () async {
      final events = <NearLogEvent>[];
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
        logger: events.add,
      );
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await adapter.keyStore.getPendingKey();

      expect(
        await adapter.completeSignIn(
          withQuery(launchedCallback('success_url').replace(host: 'foreign'), {
            'account_id': 'alice.testnet',
            'public_key': pending!.publicKey.value,
          }),
        ),
        isNull,
      );
      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
      ]);

      final account = await adapter.completeSignIn(
        withQuery(launchedCallback('success_url'), {
          'account_id': 'alice.testnet',
          'public_key': pending.publicKey.value,
        }),
      );
      expect(account?.accountId.value, 'alice.testnet');
      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
        NearLogEventType.walletCallbackReceived,
        NearLogEventType.walletFlowSucceeded,
      ]);
    });

    test('failure route cannot be accepted as a successful sign-in', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await adapter.keyStore.getPendingKey();

      final account = await adapter.completeSignIn(
        withQuery(launchedCallback('failure_url'), {
          'account_id': 'alice.testnet',
          'public_key': pending!.publicKey.value,
        }),
      );

      expect(account, isNull);
      expect(await adapter.keyStore.getPendingKey(), isNull);
    });

    test('rejects replay and a second concurrent sign-in', () async {
      final firstResult = await adapter.signIn(
        contractId: AccountId('contract.testnet'),
      );
      expect(
        () => firstResult.add(
          WalletAccount(
            accountId: AccountId('alice.testnet'),
            publicKey: PublicKey(
              'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
            ),
          ),
        ),
        returnsNormally,
      );

      await expectLater(
        adapter.signIn(contractId: AccountId('contract.testnet')),
        throwsA(isA<NearSdkException>()),
      );
      final pending = await adapter.keyStore.getPendingKey();
      final callback = withQuery(launchedCallback('success_url'), {
        'account_id': 'alice.testnet',
        'public_key': pending!.publicKey.value,
      });
      expect(await adapter.completeSignIn(callback), isNotNull);
      expect(await adapter.completeSignIn(callback), isNull);
    });

    test(
      'simultaneous sign-ins preserve the accepted flow pending key',
      () async {
        final keyStore = _BarrierKeyStore();
        adapter = MyNearWalletAdapter(
          config: MyNearWalletConfig(
            contractId: AccountId('contract.testnet'),
            successUrl: 'myapp://wallet/success',
            failureUrl: 'myapp://wallet/failure',
            network: MyNearWalletNetwork.testnet,
          ),
          keyStore: keyStore,
          launchUrl: (uri) async {
            launchedWalletUrls.add(uri);
            return true;
          },
        );

        Future<Object> outcome(Future<List<WalletAccount>> future) async {
          try {
            return await future;
          } catch (error) {
            return error;
          }
        }

        final first = outcome(
          adapter.signIn(contractId: AccountId('contract.testnet')),
        );
        final second = outcome(
          adapter.signIn(contractId: AccountId('contract.testnet')),
        );
        keyStore.releaseInitialReads();
        final outcomes = await Future.wait([first, second]);

        expect(outcomes.whereType<List<WalletAccount>>(), hasLength(1));
        expect(outcomes.whereType<NearSdkException>(), hasLength(1));
        expect(launchedWalletUrls, hasLength(1));
        final launch = launchedWalletUrls.single;
        final callback =
            withQuery(Uri.parse(launch.queryParameters['success_url']!), {
              'account_id': 'alice.testnet',
              'public_key': launch.queryParameters['public_key']!,
            });

        expect(
          (await adapter.completeSignIn(callback))?.accountId.value,
          'alice.testnet',
        );
      },
    );

    test('cancellation invalidates a callback during key promotion', () async {
      final keyStore = _BlockingPromotionKeyStore();
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        keyStore: keyStore,
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
      );
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await keyStore.getPendingKey();
      final accountId = AccountId('cancelled.testnet');
      final callback = withQuery(launchedCallback('success_url'), {
        'account_id': accountId.value,
        'public_key': pending!.publicKey.value,
      });

      final completion = adapter.completeSignIn(callback);
      await keyStore.promotionStarted.future;
      final cancellation = adapter.cancelPendingSignIn();
      keyStore.releasePromotion.complete();

      expect(await completion, isNull);
      await cancellation;
      expect(await keyStore.getPendingKey(), isNull);
      expect(await keyStore.getKey(accountId), isNull);
    });

    test(
      'signOut cannot let later cancellation restore a replaced key',
      () async {
        final accountId = AccountId('alice.testnet');
        final previousKey = await KeyPairEd25519.generate();
        await adapter.keyStore.setKey(accountId, previousKey);
        await adapter.signIn(contractId: AccountId('contract.testnet'));
        final pending = await adapter.keyStore.getPendingKey();
        final callback = withQuery(launchedCallback('success_url'), {
          'account_id': accountId.value,
          'public_key': pending!.publicKey.value,
        });
        expect(await adapter.completeSignIn(callback), isNotNull);

        await adapter.signOut();
        await adapter.cancelPendingSignIn();

        expect(await adapter.keyStore.getKey(accountId), isNull);
      },
    );

    test('uses one secure correlation value for both sign-in routes', () async {
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/result?outcome=success',
          failureUrl: 'myapp://wallet/result?outcome=failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
      );

      await adapter.signIn(contractId: AccountId('contract.testnet'));
      final success = launchedCallback('success_url');
      final failure = launchedCallback('failure_url');
      final successKeys = success.queryParameters.keys
          .where((key) => key != 'outcome')
          .toList();
      final failureKeys = failure.queryParameters.keys
          .where((key) => key != 'outcome')
          .toList();

      expect(successKeys.length == 1, isTrue);
      expect(failureKeys.length == 1, isTrue);
      expect(successKeys.single == failureKeys.single, isTrue);
      expect(
        success.queryParameters[successKeys.single] ==
            failure.queryParameters[failureKeys.single],
        isTrue,
      );
      expect(success.queryParameters[successKeys.single]!.isNotEmpty, isTrue);
    });

    test('adds correlation to every callback URL sent to the wallet', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      expect(
        launchedCallback('success_url').queryParameters.length == 1,
        isTrue,
      );
      expect(
        launchedCallback('failure_url').queryParameters.length == 1,
        isTrue,
      );

      await adapter.signOut();
      await beginTransactions();
      expect(
        launchedCallback('callbackUrl').queryParameters.length == 1,
        isTrue,
      );

      await adapter.signOut();
      await beginSignMessage(
        SignMessageParams(
          message: 'Sign in',
          recipient: 'example.app',
          nonce: List<int>.filled(32, 3),
        ),
      );
      expect(
        launchedCallback('callbackUrl').queryParameters.length == 1,
        isTrue,
      );
    });

    test('distinguishes same-path success and failure query routes', () async {
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/result?outcome=success',
          failureUrl: 'myapp://wallet/result?outcome=failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
      );

      await adapter.signIn(contractId: AccountId('contract.testnet'));
      var pending = await adapter.keyStore.getPendingKey();
      final success = await adapter.completeSignIn(
        withQuery(launchedCallback('success_url'), {
          'account_id': 'alice.testnet',
          'public_key': pending!.publicKey.value,
        }),
      );
      expect(success?.accountId.value, 'alice.testnet');

      await adapter.signOut();
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      pending = await adapter.keyStore.getPendingKey();
      final failure = await adapter.completeSignIn(
        withQuery(launchedCallback('failure_url'), {
          'account_id': 'alice.testnet',
          'public_key': pending!.publicKey.value,
        }),
      );
      expect(failure, isNull);
      expect(await adapter.keyStore.getPendingKey(), isNull);
    });

    test('replayed sign-in cannot consume the next sign-in flow', () async {
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      var pending = await adapter.keyStore.getPendingKey();
      final firstCallback = withQuery(launchedCallback('success_url'), {
        'account_id': 'alice.testnet',
        'public_key': pending!.publicKey.value,
      });
      expect(await adapter.completeSignIn(firstCallback), isNotNull);

      await adapter.signOut();
      await adapter.signIn(contractId: AccountId('contract.testnet'));
      pending = await adapter.keyStore.getPendingKey();
      final secondCallback = withQuery(launchedCallback('success_url'), {
        'account_id': 'bob.testnet',
        'public_key': pending!.publicKey.value,
      });

      expect(await adapter.completeSignIn(firstCallback), isNull);
      final stillPending = await adapter.keyStore.getPendingKey();
      expect(
        stillPending != null &&
            stillPending.publicKey.value == pending.publicKey.value,
        isTrue,
      );
      expect(
        (await adapter.completeSignIn(secondCallback))?.accountId.value,
        'bob.testnet',
      );
    });
  });

  group('callback URL opening failures', () {
    const querySecret = 'query-sentinel-secret';
    const fragmentSecret = 'fragment-sentinel-secret';
    const malformed =
        'myapp://[invalid-host?credential=$querySecret'
        '#token=$fragmentSecret';

    Future<void> expectSanitized(
      Future<Object?> Function(NearLogger logger) action,
    ) async {
      final events = <NearLogEvent>[];
      late Object error;
      try {
        await action(events.add);
        fail('expected malformed callback URL to throw');
      } catch (caught) {
        error = caught;
      }

      expect(
        error,
        isA<MyNearWalletCallbackException>().having(
          (exception) => exception.code,
          'code',
          NearErrorCode.walletResponseInvalid,
        ),
      );
      final exposed = '$error ${events.join()}';
      expect(exposed, isNot(contains(querySecret)));
      expect(exposed, isNot(contains(fragmentSecret)));
    }

    test(
      'normalizes malformed configured sign-in routes on every call',
      () async {
        NearLogger? activeLogger;
        final malformedAdapter = MyNearWalletAdapter(
          config: MyNearWalletConfig(
            contractId: AccountId('contract.testnet'),
            successUrl: 'myapp://wallet/success',
            failureUrl: malformed,
            network: MyNearWalletNetwork.testnet,
          ),
          launchUrl: (_) async => true,
          logger: (event) => activeLogger?.call(event),
        );

        for (var attempt = 0; attempt < 2; attempt++) {
          await expectSanitized((logger) {
            activeLogger = logger;
            return malformedAdapter.signIn(
              contractId: AccountId('contract.testnet'),
            );
          });
        }
      },
    );

    test('normalizes malformed transaction callback routes', () async {
      await expectSanitized((logger) {
        final malformedAdapter = MyNearWalletAdapter(
          config: adapter.config,
          launchUrl: (_) async => true,
          logger: logger,
        );
        return malformedAdapter.signAndSendTransaction(
          transaction: Transaction(
            signerId: AccountId('alice.testnet'),
            receiverId: AccountId('contract.testnet'),
            actions: const [],
          ),
          callbackUrl: malformed,
        );
      });
      await expectSanitized((logger) {
        final malformedAdapter = MyNearWalletAdapter(
          config: adapter.config,
          launchUrl: (_) async => true,
          logger: logger,
        );
        return malformedAdapter.signAndSendTransactions(
          transactions: const [],
          callbackUrl: malformed,
        );
      });
    });

    test('normalizes malformed sign-message callback routes', () async {
      await expectSanitized((logger) {
        final malformedAdapter = MyNearWalletAdapter(
          config: adapter.config,
          launchUrl: (_) async => true,
          logger: logger,
        );
        return malformedAdapter.signMessage(
          SignMessageParams(
            message: 'Sign in',
            recipient: 'example.app',
            nonce: List<int>.filled(32, 4),
            callbackUrl: malformed,
          ),
        );
      });
    });

    test('normalizes malformed verify-owner callback routes', () async {
      await expectSanitized((logger) {
        final malformedAdapter = MyNearWalletAdapter(
          config: adapter.config,
          launchUrl: (_) async => true,
          logger: logger,
        );
        return malformedAdapter.verifyOwner(
          message: 'verify',
          callbackUrl: malformed,
        );
      });
    });
  });

  group('handleSignMessageCallback required fields', () {
    test('remains callable when no secure flow is pending', () {
      final signed = adapter.handleSignMessageCallback(
        Uri.parse(
          'myapp://wallet/success#accountId=alice.testnet'
          '&publicKey='
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'
          '&signature=legacy-signature',
        ),
      );

      expect(signed.accountId.value, 'alice.testnet');
      expect(signed.signature, 'legacy-signature');
    });

    test('throws when signature or publicKey is missing', () async {
      await beginSignMessage(
        SignMessageParams(
          message: 'Sign in',
          recipient: 'example.app',
          nonce: List<int>.filled(32, 1),
        ),
      );
      expect(
        () => adapter.handleSignMessageCallback(
          withFragment(launchedCallback('callbackUrl'), {
            'accountId': 'alice.testnet',
          }),
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
      await beginSignMessage(request);
    });

    /// Signs [request] the way MyNearWallet does on a redirect flow — the
    /// callbackUrl (defaulted to successUrl) is part of the signed payload.
    Future<Uri> walletCallback({
      String? tamperMessage,
      String? state = 'csrf-123',
    }) async {
      final callbackUrl = launchedCallback('callbackUrl');
      final signed = await signNep413Message(
        payload: Nep413Payload(
          message: tamperMessage ?? request.message,
          recipient: request.recipient,
          nonce: request.nonce,
          callbackUrl: callbackUrl.toString(),
        ),
        keyPair: walletKey,
        accountId: AccountId('alice.testnet'),
      );
      return withFragment(callbackUrl, {
        'accountId': 'alice.testnet',
        'publicKey': walletKey.publicKey.value,
        'signature': signed.signature,
        if (state != null) 'state': state,
      });
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

    test(
      'sync parser cannot consume a pending secure sign-message flow',
      () async {
        final unauthenticated = withFragment(launchedCallback('callbackUrl'), {
          'accountId': 'alice.testnet',
          'publicKey': walletKey.publicKey.value,
          'signature': 'not-authenticated',
          'state': request.state!,
        });

        expect(
          () => adapter.handleSignMessageCallback(unauthenticated),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.walletResponseInvalid,
            ),
          ),
        );
        expect(
          (await adapter.completeSignMessage(
            await walletCallback(),
            request: request,
          )).accountId.value,
          'alice.testnet',
        );
      },
    );

    test('compares returned null state exactly', () async {
      final noStateRequest = SignMessageParams(
        message: request.message,
        recipient: request.recipient,
        nonce: request.nonce,
      );
      // Finish the flow opened by setUp before opening the no-state request.
      await expectLater(
        adapter.completeSignMessage(await walletCallback(), request: request),
        completes,
      );
      await beginSignMessage(noStateRequest);
      final callback = await walletCallback(state: 'injected-state');

      await expectLater(
        adapter.completeSignMessage(callback, request: noStateRequest),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.walletResponseInvalid,
          ),
        ),
      );
    });

    test(
      'requires the exact pending callback route and rejects replay',
      () async {
        final callback = await walletCallback();
        final foreign = callback.replace(host: 'foreign');

        await expectLater(
          adapter.completeSignMessage(foreign, request: request),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.walletResponseInvalid,
            ),
          ),
        );
        expect(
          (await adapter.completeSignMessage(
            callback,
            request: request,
          )).accountId.value,
          'alice.testnet',
        );
        await expectLater(
          adapter.completeSignMessage(callback, request: request),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.missingCallback,
            ),
          ),
        );
      },
    );

    test(
      'requires explicit accountId even when an account is connected',
      () async {
        // Finish the sign-message flow opened by setUp.
        await adapter.completeSignMessage(
          await walletCallback(),
          request: request,
        );
        await adapter.signIn(contractId: AccountId('contract.testnet'));
        final pendingKey = await adapter.keyStore.getPendingKey();
        await adapter.completeSignIn(
          withQuery(launchedCallback('success_url'), {
            'account_id': 'alice.testnet',
            'public_key': pendingKey!.publicKey.value,
          }),
        );
        await beginSignMessage(request);
        final signed = await signNep413Message(
          payload: Nep413Payload(
            message: request.message,
            recipient: request.recipient,
            nonce: request.nonce,
            callbackUrl: launchedCallback('callbackUrl').toString(),
          ),
          keyPair: walletKey,
          accountId: AccountId('alice.testnet'),
        );
        final callback = withFragment(launchedCallback('callbackUrl'), {
          'publicKey': walletKey.publicKey.value,
          'signature': signed.signature,
          'state': request.state!,
        });

        await expectLater(
          adapter.completeSignMessage(callback, request: request),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.walletResponseInvalid,
            ),
          ),
        );
      },
    );
  });

  group('transaction callback correlation', () {
    final validHash = base58Encode(List<int>.filled(32, 1));

    test(
      'requires pending exact route and permits foreign then valid',
      () async {
        await beginTransactions(callbackUrl: 'myapp://custom/result');

        expect(
          () => adapter.handleTransactionCallback(
            withQuery(
              launchedCallback('callbackUrl').replace(host: 'foreign'),
              {'transactionHashes': validHash},
            ),
          ),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.walletResponseInvalid,
            ),
          ),
        );

        final results = adapter.handleTransactionCallback(
          withQuery(launchedCallback('callbackUrl'), {
            'transactionHashes': validHash,
          }),
        );
        expect(results.single.transactionHash.value, validHash);
        expect(
          results.single.outcome.status,
          isA<ExecutionStatusSuccessValue>(),
        );
      },
    );

    test(
      'rejects missing and wrong correlation without consuming flow',
      () async {
        await beginTransactions();
        final callback = launchedCallback('callbackUrl');
        final correlationKey = callback.queryParameters.keys.single;
        final missing = callback.replace(queryParameters: const {});
        final wrong = callback.replace(
          queryParameters: {correlationKey: 'wrong-correlation'},
        );

        for (final invalid in [missing, wrong]) {
          expect(
            () => adapter.handleTransactionCallback(
              withQuery(invalid, {'transactionHashes': validHash}),
            ),
            throwsA(
              isA<NearSdkException>().having(
                (error) => error.code,
                'code',
                NearErrorCode.walletResponseInvalid,
              ),
            ),
          );
        }

        expect(
          adapter.handleTransactionCallback(
            withQuery(callback, {'transactionHashes': validHash}),
          ),
          hasLength(1),
        );
      },
    );

    test('replayed transaction cannot consume the next flow', () async {
      await beginTransactions();
      final firstCallback = withQuery(launchedCallback('callbackUrl'), {
        'transactionHashes': validHash,
      });
      expect(adapter.handleTransactionCallback(firstCallback), hasLength(1));

      await beginTransactions();
      final secondHash = base58Encode(List<int>.filled(32, 2));
      final secondCallback = withQuery(launchedCallback('callbackUrl'), {
        'transactionHashes': secondHash,
      });

      expect(
        () => adapter.handleTransactionCallback(firstCallback),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.walletResponseInvalid,
          ),
        ),
      );
      expect(
        adapter
            .handleTransactionCallback(secondCallback)
            .single
            .transactionHash
            .value,
        secondHash,
      );
    });

    test(
      'retains fixed query and fragment while allowing wallet fields',
      () async {
        const callbackUrl = 'myapp://custom/result?tenant=alpha#screen=wallet';
        await beginTransactions(callbackUrl: callbackUrl);
        final callback = launchedCallback('callbackUrl');
        final correlationKey = callback.queryParameters.keys
            .where((key) => key != 'tenant')
            .single;
        final missingTenant = callback.replace(
          queryParameters: {
            correlationKey: callback.queryParameters[correlationKey]!,
          },
        );
        final wrongFragment = callback.replace(fragment: 'screen=other');

        for (final invalid in [missingTenant, wrongFragment]) {
          expect(
            () => adapter.handleTransactionCallback(
              withQuery(invalid, {'transactionHashes': validHash}),
            ),
            throwsA(isA<NearSdkException>()),
          );
        }

        expect(
          adapter.handleTransactionCallback(
            withQuery(callback, {'transactionHashes': validHash}),
          ),
          hasLength(1),
        );
      },
    );

    test('does not overwrite a configured correlation-key collision', () async {
      const callbackUrl =
          'myapp://custom/result?_nearWalletFlow=configured-value';
      await beginTransactions(callbackUrl: callbackUrl);
      final callback = launchedCallback('callbackUrl');

      expect(
        callback.queryParameters['_nearWalletFlow'] == 'configured-value',
        isTrue,
      );
      expect(callback.queryParameters.length == 2, isTrue);
      expect(
        adapter.handleTransactionCallback(
          withQuery(callback, {'transactionHashes': validHash}),
        ),
        hasLength(1),
      );
    });

    test(
      'rejects a concurrent operation without replacing the first',
      () async {
        final request = SignMessageParams(
          message: 'Sign in',
          recipient: 'example.app',
          nonce: List<int>.filled(32, 2),
        );
        await beginSignMessage(request);

        await expectLater(
          adapter.signAndSendTransactions(transactions: const <Transaction>[]),
          throwsA(isA<NearSdkException>()),
        );
        expect(
          () => adapter.handleSignMessageCallback(
            Uri.parse(
              'myapp://wallet/success#accountId=alice.testnet'
              '&publicKey='
              'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'
              '&signature=invalid-but-present',
            ),
          ),
          throwsA(isA<NearSdkException>()),
        );
      },
    );

    test(
      'rejects replay, missing pending flow, and malformed hashes',
      () async {
        expect(
          () => adapter.handleTransactionCallback(
            Uri.parse('myapp://wallet/success?transactionHashes=$validHash'),
          ),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.missingCallback,
            ),
          ),
        );

        for (final invalidHash in <String>[
          'not-base58-0',
          base58Encode([1, 2]),
        ]) {
          await beginTransactions();
          expect(
            () => adapter.handleTransactionCallback(
              withQuery(launchedCallback('callbackUrl'), {
                'transactionHashes': invalidHash,
              }),
            ),
            throwsA(
              isA<NearSdkException>().having(
                (error) => error.code,
                'code',
                NearErrorCode.walletResponseInvalid,
              ),
            ),
          );
        }

        await beginTransactions();
        final callback = withQuery(launchedCallback('callbackUrl'), {
          'transactionHashes': validHash,
        });
        expect(adapter.handleTransactionCallback(callback), hasLength(1));
        expect(
          () => adapter.handleTransactionCallback(callback),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.missingCallback,
            ),
          ),
        );
      },
    );
  });

  group('wallet diagnostics', () {
    test('classifies a correlated generic callback rejection once', () async {
      final events = <NearLogEvent>[];
      final loggingAdapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
        logger: events.add,
      );
      await expectLater(
        loggingAdapter.verifyOwner(message: 'verify'),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.missingCallback,
          ),
        ),
      );

      final callback = loggingAdapter.handleCallback(
        withQuery(launchedCallback('callbackUrl'), {
          'errorCode': 'rejected',
          'errorMessage': 'private-wallet-reason',
        }),
      );

      expect(callback.isError, isTrue);
      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
        NearLogEventType.walletCallbackReceived,
        NearLogEventType.walletFlowFailed,
      ]);
      expect(events.join(), isNot(contains('private-wallet-reason')));
    });

    test('signOut emits one cancelled terminal for a pending flow', () async {
      final events = <NearLogEvent>[];
      adapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
        logger: events.add,
      );
      await beginTransactions();

      await adapter.signOut();
      await adapter.signOut();

      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
        NearLogEventType.walletFlowFailed,
      ]);
      expect(events.last.metadata['failureCode'], NearErrorCode.cancelled.name);
    });

    test('logs callback receipt without callback values', () async {
      final events = <NearLogEvent>[];
      final loggingAdapter = MyNearWalletAdapter(
        config: MyNearWalletConfig(
          contractId: AccountId('contract.testnet'),
          successUrl: 'myapp://wallet/success',
          failureUrl: 'myapp://wallet/failure',
          network: MyNearWalletNetwork.testnet,
        ),
        launchUrl: (uri) async {
          launchedWalletUrls.add(uri);
          return true;
        },
        logger: events.add,
      );
      await loggingAdapter.signIn(contractId: AccountId('contract.testnet'));
      final pending = await loggingAdapter.keyStore.getPendingKey();
      const callbackSecret = 'callback-secret-value';

      final account = await loggingAdapter.completeSignIn(
        withQuery(launchedCallback('success_url'), {
          'account_id': callbackSecret,
          'public_key': pending!.publicKey.value,
        }),
      );

      expect(account?.accountId.value, callbackSecret);
      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
        NearLogEventType.walletCallbackReceived,
        NearLogEventType.walletFlowSucceeded,
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

    test('does not copy callback values into transaction errors', () async {
      const callbackCode = 'callback-code-secret';
      const callbackMessage = 'callback-message-secret';
      await beginTransactions();

      final result = adapter.handleTransactionCallback(
        withQuery(launchedCallback('callbackUrl'), {
          'errorCode': callbackCode,
          'errorMessage': callbackMessage,
        }),
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

class _BarrierKeyStore implements KeyStore {
  final InMemoryKeyStore _delegate = InMemoryKeyStore();
  final Completer<void> _initialReadBarrier = Completer<void>();
  var _initialReadCount = 0;

  void releaseInitialReads() => _initialReadBarrier.complete();

  @override
  Future<void> clearPendingKey() => _delegate.clearPendingKey();

  @override
  Future<List<AccountId>> accounts() => _delegate.accounts();

  @override
  Future<KeyPairEd25519?> getKey(AccountId accountId) =>
      _delegate.getKey(accountId);

  @override
  Future<KeyPairEd25519?> getPendingKey() async {
    _initialReadCount++;
    if (_initialReadCount <= 2) await _initialReadBarrier.future;
    return _delegate.getPendingKey();
  }

  @override
  Future<void> removeKey(AccountId accountId) => _delegate.removeKey(accountId);

  @override
  Future<void> setKey(AccountId accountId, KeyPairEd25519 keyPair) =>
      _delegate.setKey(accountId, keyPair);

  @override
  Future<void> setPendingKey(KeyPairEd25519 keyPair) async {
    await _delegate.setPendingKey(keyPair);
    if (_initialReadCount > 1) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

class _BlockingPromotionKeyStore implements KeyStore {
  final InMemoryKeyStore _delegate = InMemoryKeyStore();
  final promotionStarted = Completer<void>();
  final releasePromotion = Completer<void>();

  @override
  Future<void> clearPendingKey() => _delegate.clearPendingKey();

  @override
  Future<List<AccountId>> accounts() => _delegate.accounts();

  @override
  Future<KeyPairEd25519?> getKey(AccountId accountId) =>
      _delegate.getKey(accountId);

  @override
  Future<KeyPairEd25519?> getPendingKey() => _delegate.getPendingKey();

  @override
  Future<void> removeKey(AccountId accountId) => _delegate.removeKey(accountId);

  @override
  Future<void> setKey(AccountId accountId, KeyPairEd25519 keyPair) async {
    promotionStarted.complete();
    await releasePromotion.future;
    await _delegate.setKey(accountId, keyPair);
  }

  @override
  Future<void> setPendingKey(KeyPairEd25519 keyPair) =>
      _delegate.setPendingKey(keyPair);
}
