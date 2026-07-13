@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha1;
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

/// A real local HOT relay (h4n.app stand-in). Validates that the request id
/// is sha1(query) and that the queued query base58-decodes to the request,
/// then serves the configured wallet response on the first poll.
class FakeRelay {
  FakeRelay._(this._server);

  final HttpServer _server;
  final launchedUris = <Uri>[];
  int requestStatus = 200;
  String requestErrorBody = '';
  bool serveResponse = true;
  int responseStatus = 200;
  String? rawResponseBody;

  /// The decoded request queued by the adapter.
  Map<String, dynamic>? lastRequest;

  /// Wallet behaviour.
  Map<String, dynamic> Function(Map<String, dynamic> request) respond = (_) => {
    'success': false,
    'payload': 'no responder',
  };

  final _responses = <String, String>{};

  static Future<FakeRelay> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = FakeRelay._(server);
    server.listen((req) async {
      final parts = req.uri.pathSegments;
      if (req.uri.path == '/time') {
        req.response.write(
          jsonEncode({
            'ts':
                (BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000) *
                        BigInt.from(10).pow(12))
                    .toString(),
          }),
        );
      } else if (parts.length == 2 && parts[1] == 'request') {
        if (relay.requestStatus >= 300) {
          req.response.statusCode = relay.requestStatus;
          req.response.write(relay.requestErrorBody);
          await req.response.close();
          return;
        }
        final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
        final query = body['data'] as String;
        // The id in the URL must be the sha1 of the queued query.
        expect(sha1.convert(utf8.encode(query)).toString(), parts[0]);
        final request =
            jsonDecode(utf8.decode(base58Decode(query)))
                as Map<String, dynamic>;
        relay.lastRequest = request;
        relay._responses[parts[0]] = jsonEncode({
          'data': jsonEncode(relay.respond(request)),
        });
      } else if (parts.length == 2 && parts[1] == 'response') {
        final queued = relay._responses[parts[0]];
        if (!relay.serveResponse || queued == null) {
          req.response.statusCode = 404;
        } else {
          req.response.statusCode = relay.responseStatus;
          req.response.write(relay.rawResponseBody ?? queued);
        }
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
    return relay;
  }

  String get url => 'http://127.0.0.1:${_server.port}';

  Future<void> close() => _server.close(force: true);
}

void main() {
  late FakeRelay relay;
  late bool launchResult;

  HotWalletAdapter adapter({
    NearLogger? logger,
    Duration pollInterval = const Duration(milliseconds: 50),
    Duration responseTimeout = const Duration(seconds: 10),
  }) => HotWalletAdapter(
    config: HotWalletConfig(
      origin: 'https://example.app',
      proxyUrl: relay.url,
      timeUrl: '${relay.url}/time',
      pollInterval: pollInterval,
      responseTimeout: responseTimeout,
    ),
    launchUrl: (uri) async {
      relay.launchedUris.add(uri);
      return launchResult;
    },
    logger: logger,
  );

  setUp(() async {
    relay = await FakeRelay.start();
    launchResult = true;
  });
  tearDown(() => relay.close());

  test('signIn queues a valid \$hot request and returns the account', () async {
    relay.respond = (req) => {
      'success': true,
      'payload': {
        'accountId': 'alice.near',
        'publicKey': 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
      },
    };

    final account = await adapter().signIn();

    expect(account.accountId.value, 'alice.near');
    final req = relay.lastRequest!;
    expect(req['method'], 'near:signIn');
    expect(req[r'$hot'], isTrue);
    expect(req['origin'], 'https://example.app');
    expect(req['deadline'], greaterThan(0));
    expect(
      relay.launchedUris.single.toString(),
      startsWith('hotwallet://hotcall-'),
    );
  });

  test(
    'signIn rejects a missing public key instead of substituting one',
    () async {
      relay.respond = (_) => {
        'success': true,
        'payload': {'accountId': 'alice.near'},
      };

      await expectLater(
        adapter().signIn(),
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

  test('signIn rejects an explicit zero public key', () async {
    relay.respond = (_) => {
      'success': true,
      'payload': {
        'accountId': 'alice.near',
        'publicKey': 'ed25519:11111111111111111111111111111111',
      },
    };

    await expectLater(
      adapter().signIn(),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.walletResponseInvalid,
        ),
      ),
    );
  });

  test('signMessage sends NEP-413 params and verifies the signature', () async {
    final walletKey = await KeyPairEd25519.generate();
    final payload = Nep413Payload(
      message: 'Sign in to app.com',
      recipient: 'app.com',
      nonce: List<int>.generate(32, (i) => i),
    );
    final walletSignature = await signNep413Message(
      payload: payload,
      keyPair: walletKey,
      accountId: AccountId('alice.near'),
    );
    relay.respond = (req) => {
      'success': true,
      'payload': {
        'accountId': walletSignature.accountId.value,
        'publicKey': walletSignature.publicKey.value,
        'signature': walletSignature.signature,
      },
    };

    final signed = await adapter().signMessage(payload: payload);

    expect(signed.accountId.value, 'alice.near');
    expect(signed.signature, walletSignature.signature);
    final request = relay.lastRequest!['request'] as Map;
    expect(request['message'], 'Sign in to app.com');
    expect(request['nonce'], payload.nonce);
    expect(request['recipient'], 'app.com');
  });

  test('signMessage rejects a one-byte signature mutation', () async {
    final walletKey = await KeyPairEd25519.generate();
    final payload = Nep413Payload(
      message: 'Sign in to app.com',
      recipient: 'app.com',
      nonce: List<int>.filled(32, 3),
    );
    final walletSignature = await signNep413Message(
      payload: payload,
      keyPair: walletKey,
      accountId: AccountId('alice.near'),
    );
    final signatureBytes = base64Decode(walletSignature.signature);
    signatureBytes[0] ^= 1;
    relay.respond = (_) => {
      'success': true,
      'payload': {
        'accountId': walletSignature.accountId.value,
        'publicKey': walletSignature.publicKey.value,
        'signature': base64Encode(signatureBytes),
      },
    };

    await expectLater(
      adapter().signMessage(payload: payload),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.signatureVerificationFailed,
        ),
      ),
    );
  });

  test('signAndSendTransactions returns the outcomes', () async {
    relay.respond = (req) => {
      'success': true,
      'payload': {
        'transactions': [
          {
            'transaction': {'hash': 'abc'},
          },
        ],
      },
    };

    final outcomes = await adapter().signAndSendTransactions(
      transactions: [
        {
          'receiverId': 'jar.near',
          'actions': [
            {
              'type': 'Transfer',
              'params': {'deposit': '1'},
            },
          ],
        },
      ],
    );

    expect(outcomes, hasLength(1));
    final request = relay.lastRequest!['request'] as Map;
    expect(request['transactions'], hasLength(1));
  });

  test('surfaces a wallet rejection', () async {
    relay.respond = (_) => {'success': false, 'payload': 'User rejected'};

    expect(
      () => adapter().signIn(),
      throwsA(
        isA<HotWalletException>()
            .having((error) => error.code, 'code', NearErrorCode.userRejected)
            .having(
              (error) => error.toString(),
              'safe error',
              isNot(contains('User rejected')),
            ),
      ),
    );
  });

  test('types relay HTTP failures without exposing the body', () async {
    relay.requestStatus = 503;
    relay.requestErrorBody = 'secret relay response body';

    await expectLater(
      adapter().signIn(),
      throwsA(
        isA<NearSdkException>()
            .having((error) => error.code, 'code', NearErrorCode.rpcUnavailable)
            .having(
              (error) => error.toString(),
              'safe error',
              isNot(contains('secret relay response body')),
            ),
      ),
    );
  });

  test('types deep-link failures', () async {
    launchResult = false;
    relay.respond = (_) => {
      'success': true,
      'payload': {
        'accountId': 'alice.near',
        'publicKey': 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
      },
    };

    await expectLater(
      adapter().signIn(),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.deepLinkUnavailable,
        ),
      ),
    );
  });

  test('types wallet response timeouts', () async {
    relay.serveResponse = false;

    await expectLater(
      adapter(
        pollInterval: const Duration(milliseconds: 5),
        responseTimeout: const Duration(milliseconds: 30),
      ).signIn(),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.rpcTimeout,
        ),
      ),
    );
  });

  test('types malformed relay responses', () async {
    relay.rawResponseBody = '{not-json';

    await expectLater(
      adapter().signIn(),
      throwsA(
        isA<NearSdkException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.walletResponseInvalid,
        ),
      ),
    );
  });

  test('emits safe lifecycle events and ignores logger failures', () async {
    final events = <NearLogEvent>[];
    relay.respond = (_) => {
      'success': true,
      'payload': {
        'accountId': 'alice.near',
        'publicKey': 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
      },
    };

    final account = await adapter(logger: events.add).signIn();
    final secondAccount = await adapter(
      logger: (_) => throw StateError('logger failed'),
    ).signIn();

    expect(account.accountId.value, 'alice.near');
    expect(secondAccount.accountId.value, 'alice.near');
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
      expect(event.toString(), isNot(contains(relay.url)));
    }
  });
}
