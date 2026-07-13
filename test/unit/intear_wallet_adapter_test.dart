@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart' hide PublicKey;
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// A real local WebSocket bridge that speaks the Intear session protocol and
/// cryptographically verifies each request signature, so these tests prove
/// our wire format end-to-end without a network.
class FakeBridge {
  FakeBridge._(this._server);

  final HttpServer _server;
  final launchedUris = <Uri>[];

  /// The last request received, decoded.
  Map<String, dynamic>? lastRequest;

  /// Wallet behaviour: given the request, produce the response.
  Map<String, dynamic> Function(Map<String, dynamic> request) respond = (_) => {
    'type': 'error',
    'message': 'no responder configured',
  };

  static Future<FakeBridge> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bridge = FakeBridge._(server);
    server.listen((req) async {
      if (req.uri.path != '/api/session/create') {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      // ignore: close_sinks — closed when the HttpServer force-closes.
      final ws = await WebSocketTransformer.upgrade(req);
      ws.add(jsonEncode({'session_id': 'sess-123'}));
      ws.listen((raw) async {
        final message = jsonDecode(raw as String) as Map<String, dynamic>;
        bridge.lastRequest = message;
        ws.add(jsonEncode(bridge.respond(message)));
      });
    });
    return bridge;
  }

  String get url => 'ws://127.0.0.1:${_server.port}';

  Future<void> close() => _server.close(force: true);
}

/// Verifies an Intear request signature: `ed25519:<base58>` over
/// `sha256(utf8("{nonce}|{payload}"))`.
Future<bool> verifyRequestSignature(Map<String, dynamic> data, String payload) {
  final publicKey = PublicKey(data['publicKey'] as String);
  final signature = (data['signature'] as String).substring('ed25519:'.length);
  final hash = sha256Hash(utf8.encode('${data['nonce']}|$payload'));
  return Ed25519().verify(
    hash,
    signature: Signature(
      base58Decode(signature),
      publicKey: SimplePublicKey(
        base58Decode(publicKey.value.substring('ed25519:'.length)),
        type: KeyPairType.ed25519,
      ),
    ),
  );
}

String corruptSignature(String signature) {
  final bytes = base64Decode(signature);
  bytes[0] ^= 1;
  return base64Encode(bytes);
}

void main() {
  late FakeBridge bridge;
  late InMemoryKeyStore keyStore;
  late bool launchResult;

  IntearWalletAdapter adapter({
    AccountId? contractId,
    NearLogger? logger,
    Duration responseTimeout = const Duration(seconds: 10),
  }) => IntearWalletAdapter(
    config: IntearWalletConfig(
      origin: 'https://example.app',
      networkId: 'testnet',
      bridgeUrl: bridge.url,
      contractId: contractId,
      responseTimeout: responseTimeout,
    ),
    keyStore: keyStore,
    launchUrl: (uri) async {
      bridge.launchedUris.add(uri);
      return launchResult;
    },
    logger: logger,
  );

  setUp(() async {
    bridge = await FakeBridge.start();
    keyStore = InMemoryKeyStore();
    launchResult = true;
  });

  tearDown(() => bridge.close());

  group('signIn', () {
    test('connects, launches the deep link and persists the app key', () async {
      bridge.respond = (req) => {
        'type': 'connected',
        'accounts': [
          {
            'accountId': 'alice.testnet',
            'publicKey': 'ed25519:11111111111111111111111111111111',
          },
        ],
        'functionCallKeyAdded': false,
        'useBridge': true,
        'walletUrl': 'https://wallet.intear.tech',
      };

      final result = await adapter().signIn();

      expect(result.account.accountId.value, 'alice.testnet');
      expect(result.functionCallKeyAdded, isFalse);
      expect(
        bridge.launchedUris.single.toString(),
        'intear://connect?session_id=sess-123',
      );
      // The app key is stored so later calls can authenticate.
      final stored = await keyStore.getKey(AccountId('alice.testnet'));
      expect(stored, isNotNull);
      expect(stored!.publicKey, result.account.publicKey);
    });

    test(
      'sends a V3 request whose signature verifies against the app key',
      () async {
        bridge.respond = (req) => {
          'type': 'connected',
          'accounts': [
            {
              'accountId': 'alice.testnet',
              'publicKey': 'ed25519:11111111111111111111111111111111',
            },
          ],
          'useBridge': true,
        };

        await adapter(contractId: AccountId('app.testnet')).signIn();

        final req = bridge.lastRequest!;
        expect(req['type'], 'signIn');
        final data = req['data'] as Map<String, dynamic>;
        expect(data['version'], 'V2');
        expect(data['actualOrigin'], 'https://example.app');
        final msg = jsonDecode(data['message'] as String) as Map;
        expect(msg['origin'], 'https://example.app');
        expect(data['networkId'], 'testnet');
        expect(data['contractId'], 'app.testnet');
        // message carries the function-call public key
        final message = jsonDecode(data['message'] as String) as Map;
        expect(message['functionCallPublicKey'], data['publicKey']);
        expect(
          await verifyRequestSignature(data, data['message'] as String),
          isTrue,
        );
      },
    );

    test('surfaces a wallet error (user rejection)', () async {
      bridge.respond = (_) => {'type': 'error', 'message': 'User rejected'};

      expect(
        () => adapter().signIn(),
        throwsA(
          isA<IntearWalletException>()
              .having((error) => error.code, 'code', NearErrorCode.userRejected)
              .having(
                (error) => error.toString(),
                'safe error',
                isNot(contains('User rejected')),
              ),
        ),
      );
    });

    test('verifies a requested signed message before persisting', () async {
      final walletKey = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'Sign in to example.app',
        recipient: 'example.app',
        nonce: List<int>.generate(32, (i) => i),
      );
      final signed = await signNep413Message(
        payload: payload,
        keyPair: walletKey,
        accountId: AccountId('alice.testnet'),
      );
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {'accountId': 'alice.testnet'},
        ],
        'signedMessage': {
          'accountId': signed.accountId.value,
          'publicKey': signed.publicKey.value,
          'signature': signed.signature,
        },
      };

      final result = await adapter().signIn(messageToSign: payload);

      expect(result.signedMessage?.signature, signed.signature);
      expect(await keyStore.getKey(AccountId('alice.testnet')), isNotNull);
    });

    test('rejects an invalid requested signature without persisting', () async {
      final walletKey = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'Sign in to example.app',
        recipient: 'example.app',
        nonce: List<int>.generate(32, (i) => i),
      );
      final signed = await signNep413Message(
        payload: payload,
        keyPair: walletKey,
        accountId: AccountId('alice.testnet'),
      );
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {'accountId': 'alice.testnet'},
        ],
        'signedMessage': {
          'accountId': signed.accountId.value,
          'publicKey': signed.publicKey.value,
          'signature': corruptSignature(signed.signature),
        },
      };

      await expectLater(
        adapter().signIn(messageToSign: payload),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.signatureVerificationFailed,
          ),
        ),
      );
      expect(await keyStore.getKey(AccountId('alice.testnet')), isNull);
    });

    test('requires a signed response only when one was requested', () async {
      final payload = Nep413Payload(
        message: 'Sign in',
        recipient: 'example.app',
        nonce: List<int>.filled(32, 9),
      );
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {'accountId': 'alice.testnet'},
        ],
      };

      await expectLater(
        adapter().signIn(messageToSign: payload),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.walletResponseInvalid,
          ),
        ),
      );
      expect(await keyStore.getKey(AccountId('alice.testnet')), isNull);
    });

    test(
      'rejects a signed account different from the connected account',
      () async {
        final walletKey = await KeyPairEd25519.generate();
        final payload = Nep413Payload(
          message: 'Sign in',
          recipient: 'example.app',
          nonce: List<int>.filled(32, 8),
        );
        final signed = await signNep413Message(
          payload: payload,
          keyPair: walletKey,
          accountId: AccountId('mallory.testnet'),
        );
        bridge.respond = (_) => {
          'type': 'connected',
          'accounts': [
            {'accountId': 'alice.testnet'},
          ],
          'signedMessage': {
            'accountId': signed.accountId.value,
            'publicKey': signed.publicKey.value,
            'signature': signed.signature,
          },
        };

        await expectLater(
          adapter().signIn(messageToSign: payload),
          throwsA(
            isA<NearSdkException>().having(
              (error) => error.code,
              'code',
              NearErrorCode.accountMismatch,
            ),
          ),
        );
        expect(await keyStore.getKey(AccountId('alice.testnet')), isNull);
      },
    );
  });

  group('signMessage', () {
    setUp(() async {
      // Establish a session first.
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {
            'accountId': 'alice.testnet',
            'publicKey': 'ed25519:11111111111111111111111111111111',
          },
        ],
        'useBridge': true,
      };
      await adapter().signIn();
      bridge.launchedUris.clear();
    });

    test('sends the NEP-413 JSON and verifies the wallet signature', () async {
      final walletKey = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'Sign in to app.com',
        recipient: 'app.com',
        nonce: List<int>.generate(32, (i) => i),
      );
      final walletSignature = await signNep413Message(
        payload: payload,
        keyPair: walletKey,
        accountId: AccountId('alice.testnet'),
      );
      bridge.respond = (req) => {
        'type': 'signed',
        'signature': {
          'accountId': walletSignature.accountId.value,
          'publicKey': walletSignature.publicKey.value,
          'signature': walletSignature.signature,
          'state': null,
        },
      };

      final signed = await adapter().signMessage(
        accountId: AccountId('alice.testnet'),
        payload: payload,
      );

      expect(signed.accountId.value, 'alice.testnet');
      expect(signed.signature, walletSignature.signature);
      expect(
        bridge.launchedUris.single.toString(),
        'intear://sign-message?session_id=sess-123',
      );
      final data = bridge.lastRequest!['data'] as Map<String, dynamic>;
      final nep413 = jsonDecode(data['message'] as String) as Map;
      expect(nep413['message'], 'Sign in to app.com');
      expect(nep413['recipient'], 'app.com');
      expect(nep413['nonce'], payload.nonce);
      expect(nep413['callback_url'], isNull);
      expect(
        await verifyRequestSignature(data, data['message'] as String),
        isTrue,
      );
    });

    test('rejects an invalid wallet signature', () async {
      final walletKey = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'Approve login',
        recipient: 'app.com',
        nonce: List<int>.filled(32, 4),
      );
      final signed = await signNep413Message(
        payload: payload,
        keyPair: walletKey,
        accountId: AccountId('alice.testnet'),
      );
      bridge.respond = (_) => {
        'type': 'signed',
        'signature': {
          'accountId': signed.accountId.value,
          'publicKey': signed.publicKey.value,
          'signature': corruptSignature(signed.signature),
        },
      };

      await expectLater(
        adapter().signMessage(
          accountId: AccountId('alice.testnet'),
          payload: payload,
        ),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.signatureVerificationFailed,
          ),
        ),
      );
    });

    test('rejects a signature returned for another account', () async {
      final walletKey = await KeyPairEd25519.generate();
      final payload = Nep413Payload(
        message: 'Approve login',
        recipient: 'app.com',
        nonce: List<int>.filled(32, 5),
      );
      final signed = await signNep413Message(
        payload: payload,
        keyPair: walletKey,
        accountId: AccountId('mallory.testnet'),
      );
      bridge.respond = (_) => {
        'type': 'signed',
        'signature': {
          'accountId': signed.accountId.value,
          'publicKey': signed.publicKey.value,
          'signature': signed.signature,
        },
      };

      await expectLater(
        adapter().signMessage(
          accountId: AccountId('alice.testnet'),
          payload: payload,
        ),
        throwsA(
          isA<NearSdkException>().having(
            (error) => error.code,
            'code',
            NearErrorCode.accountMismatch,
          ),
        ),
      );
    });

    test('throws without a prior session', () async {
      expect(
        () => adapter().signMessage(
          accountId: AccountId('stranger.testnet'),
          payload: Nep413Payload(
            message: 'm',
            recipient: 'r',
            nonce: List.filled(32, 0),
          ),
        ),
        throwsStateError,
      );
    });
  });

  group('signAndSendTransactions', () {
    setUp(() async {
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {
            'accountId': 'alice.testnet',
            'publicKey': 'ed25519:11111111111111111111111111111111',
          },
        ],
        'useBridge': true,
      };
      await adapter().signIn();
      bridge.launchedUris.clear();
    });

    test('sends wallet-selector JSON and returns outcomes', () async {
      bridge.respond = (req) => {
        'type': 'sent',
        'outcomes': [
          {
            'transaction': {'hash': 'abc123'},
          },
        ],
      };

      final outcomes = await adapter().signAndSendTransactions(
        accountId: AccountId('alice.testnet'),
        transactions: [
          {
            'receiverId': 'jar.testnet',
            'actions': [
              {
                'type': 'FunctionCall',
                'params': {
                  'methodName': 'tip',
                  'args': {'message': 'hi'},
                  'gas': '30000000000000',
                  'deposit': '1000000000000000000000000',
                },
              },
            ],
          },
        ],
      );

      expect(outcomes, hasLength(1));
      expect(
        bridge.launchedUris.single.toString(),
        'intear://send-transactions?session_id=sess-123',
      );
      final data = bridge.lastRequest!['data'] as Map<String, dynamic>;
      expect(data['mode'], 'Send');
      expect(
        await verifyRequestSignature(data, data['transactions'] as String),
        isTrue,
      );
    });
  });

  group('failures and diagnostics', () {
    test('types deep-link failures without exposing the link', () async {
      launchResult = false;
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {'accountId': 'alice.testnet'},
        ],
      };

      await expectLater(
        adapter().signIn(),
        throwsA(
          isA<NearSdkException>()
              .having(
                (error) => error.code,
                'code',
                NearErrorCode.deepLinkUnavailable,
              )
              .having(
                (error) => error.toString(),
                'safe error',
                isNot(contains('intear://')),
              ),
        ),
      );
    });

    test('emits only safe wallet lifecycle metadata', () async {
      final events = <NearLogEvent>[];
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {'accountId': 'alice.testnet'},
        ],
      };

      await adapter(logger: events.add).signIn();

      expect(events.map((event) => event.type), [
        NearLogEventType.walletFlowOpened,
        NearLogEventType.walletCallbackReceived,
      ]);
      for (final event in events) {
        expect(event.operation, 'signIn');
        expect(
          event.metadata.keys,
          everyElement(
            isIn(['walletId', 'durationMs', 'outcome', 'failureCode']),
          ),
        );
        expect(event.toString(), isNot(contains('sess-123')));
      }
      expect(events.last.metadata['outcome'], 'success');
    });

    test('logger exceptions do not alter adapter behavior', () async {
      bridge.respond = (_) => {
        'type': 'connected',
        'accounts': [
          {'accountId': 'alice.testnet'},
        ],
      };

      final result = await adapter(
        logger: (_) => throw StateError('logger'),
      ).signIn();

      expect(result.account.accountId.value, 'alice.testnet');
    });
  });
}
