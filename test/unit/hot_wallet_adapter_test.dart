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
        if (queued == null) {
          req.response.statusCode = 404;
        } else {
          req.response.write(queued);
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

  HotWalletAdapter adapter() => HotWalletAdapter(
    config: HotWalletConfig(
      origin: 'https://example.app',
      proxyUrl: relay.url,
      timeUrl: '${relay.url}/time',
      pollInterval: const Duration(milliseconds: 50),
      responseTimeout: const Duration(seconds: 10),
    ),
    launchUrl: (uri) async {
      relay.launchedUris.add(uri);
      return true;
    },
  );

  setUp(() async => relay = await FakeRelay.start());
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

  test('signMessage sends NEP-413 params and returns the signature', () async {
    relay.respond = (req) => {
      'success': true,
      'payload': {
        'accountId': 'alice.near',
        'publicKey': 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        'signature': base64Encode(List.filled(64, 3)),
      },
    };

    final nonce = List<int>.generate(32, (i) => i);
    final signed = await adapter().signMessage(
      payload: Nep413Payload(
        message: 'Sign in to app.com',
        recipient: 'app.com',
        nonce: nonce,
      ),
    );

    expect(signed.accountId.value, 'alice.near');
    final request = relay.lastRequest!['request'] as Map;
    expect(request['message'], 'Sign in to app.com');
    expect(request['nonce'], nonce);
    expect(request['recipient'], 'app.com');
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
        isA<HotWalletException>().having(
          (e) => e.message,
          'message',
          'User rejected',
        ),
      ),
    );
  });
}
