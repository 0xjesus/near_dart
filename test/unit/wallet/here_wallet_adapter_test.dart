import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  late List<Uri> launched;
  late HereWalletAdapter adapter;

  setUp(() {
    launched = <Uri>[];
    adapter = HereWalletAdapter(
      config: const HereWalletConfig(
        returnUrl: 'myapp://callback',
        network: NearNetwork.mainnet,
      ),
      launchUrl: (uri) async {
        launched.add(uri);
        return true;
      },
    );
  });

  Map<String, dynamic> payloadOf(Uri url) {
    expect(url.pathSegments.length, 2);
    return jsonDecode(utf8.decode(base58Decode(url.pathSegments[1])))
        as Map<String, dynamic>;
  }

  test('call URL base58-encodes transactions and network', () {
    final url = adapter.buildCallUrl(
      transactions: [
        {
          'receiverId': 'bob.near',
          'actions': [
            {
              'type': 'FunctionCall',
              'params': {
                'methodName': 'hi',
                'args': '',
                'gas': '30000000000000',
                'deposit': '1',
              },
            },
          ],
        },
      ],
    );
    expect(url.origin, 'https://my.herewallet.app');
    expect(url.pathSegments.first, 'call');
    expect(url.queryParameters['returnUrl'], 'myapp://callback');
    final payload = payloadOf(url);
    expect(payload['network'], 'mainnet');
    expect(payload['transactions'].single['receiverId'], 'bob.near');
  });

  test('sign URL encodes receiver and message', () {
    final url = adapter.buildSignUrl(
      message: 'auth message to sign',
      receiver: 'dapp.name',
    );
    expect(url.pathSegments.first, 'sign');
    final payload = payloadOf(url);
    expect(payload['message'], 'auth message to sign');
    expect(payload['receiver'], 'dapp.name');
  });

  test('empty transactions are rejected', () {
    expect(
      () => adapter.buildCallUrl(transactions: const []),
      throwsA(isA<HereWalletException>()),
    );
  });

  test('completeCallback reads success hashes', () {
    final callback = adapter.completeCallback(
      Uri.parse('myapp://callback?success=hash1,hash2'),
    );
    expect(callback.successValues, ['hash1', 'hash2']);
  });

  test('completeCallback treats failure as rejection', () {
    expect(
      () => adapter.completeCallback(
        Uri.parse('myapp://callback?failure=user_cancelled'),
      ),
      throwsA(
        isA<HereWalletException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.userRejected,
        ),
      ),
    );
  });

  test('requestSignTransactions launches the call URL', () async {
    await adapter.requestSignTransactions([
      {'receiverId': 'bob.near', 'actions': <Map<String, dynamic>>[]},
    ]);
    expect(launched.single.pathSegments.first, 'call');
  });

  test('signIn launches a /sign connect payload', () async {
    await adapter.signIn();
    expect(launched.single.pathSegments.first, 'sign');
    final payload = payloadOf(launched.single);
    expect(payload['message'], 'Connect');
    expect(payload['receiver'], 'callback');
  });

  test('completeConnect reads account_id and public_key', () {
    const publicKey = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
    final account = adapter.completeConnect(
      Uri.parse(
        'myapp://callback?success=sig&account_id=alice.near&public_key=$publicKey',
      ),
    );
    expect(account.accountId.value, 'alice.near');
    expect(account.publicKey.value, publicKey);
  });

  test('completeConnect reads JSON inside success', () {
    const publicKey = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
    final account = adapter.completeConnect(
      Uri.parse(
        'myapp://callback?success=${Uri.encodeComponent(jsonEncode({'accountId': 'alice.near', 'publicKey': publicKey}))}',
      ),
    );
    expect(account.accountId.value, 'alice.near');
    expect(account.publicKey.value, publicKey);
  });

  test('completeConnect rejects a hash-only callback', () {
    expect(
      () => adapter.completeConnect(
        Uri.parse('myapp://callback?success=only-a-signature'),
      ),
      throwsA(
        isA<HereWalletException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.walletResponseInvalid,
        ),
      ),
    );
  });
}
