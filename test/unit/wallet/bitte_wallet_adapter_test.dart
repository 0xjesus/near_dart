import 'dart:convert';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  late List<Uri> launched;
  late BitteWalletAdapter adapter;

  setUp(() {
    launched = <Uri>[];
    adapter = BitteWalletAdapter(
      config: const BitteWalletConfig(
        successUrl: 'myapp://callback/success',
        failureUrl: 'myapp://callback/failure',
        network: NearNetwork.testnet,
      ),
      launchUrl: (uri) async {
        launched.add(uri);
        return true;
      },
    );
  });

  test('connect URL uses the testnet Bitte origin', () {
    final url = adapter.buildConnectUrl();
    expect(url.origin, 'https://testnet.wallet.bitte.ai');
    expect(url.path, '/connect');
    expect(url.queryParameters['success_url'], 'myapp://callback/success');
    expect(url.queryParameters['failure_url'], 'myapp://callback/failure');
  });

  test('mainnet connect URL uses wallet.bitte.ai', () {
    final mainnet = BitteWalletAdapter(
      config: const BitteWalletConfig(
        successUrl: 'https://app.example/success',
        failureUrl: 'https://app.example/failure',
      ),
      launchUrl: (_) async => true,
    );
    expect(mainnet.buildConnectUrl().origin, 'https://wallet.bitte.ai');
  });

  test('sign-transaction URL encodes wallet-selector JSON', () {
    final url = adapter.buildSignTransactionUrl(
      transactions: [
        {
          'receiverId': 'alice.testnet',
          'actions': [
            {
              'type': 'FunctionCall',
              'params': {
                'methodName': 'ping',
                'args': {},
                'gas': '30000000000000',
                'deposit': '0',
              },
            },
          ],
        },
      ],
    );
    expect(url.path, '/sign-transaction');
    final decoded =
        jsonDecode(url.queryParameters['transactions_data']!) as List;
    expect(decoded.single['receiverId'], 'alice.testnet');
    expect(url.queryParameters['callback_url'], 'myapp://callback/success');
  });

  test('sign-transaction URL rejects an empty list', () {
    expect(
      () => adapter.buildSignTransactionUrl(transactions: const []),
      throwsA(isA<BitteWalletException>()),
    );
  });

  test('completeConnect reads account_id and public_key', () {
    const publicKey = 'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';
    final account = adapter.completeConnect(
      Uri.parse(
        'myapp://callback/success?account_id=alice.testnet&public_key=$publicKey',
      ),
    );
    expect(account.accountId.value, 'alice.testnet');
    expect(account.publicKey.value, publicKey);
  });

  test('completeConnect treats errorCode as rejection', () {
    expect(
      () => adapter.completeConnect(
        Uri.parse('myapp://callback/failure?errorCode=userRejected'),
      ),
      throwsA(
        isA<BitteWalletException>().having(
          (error) => error.code,
          'code',
          NearErrorCode.userRejected,
        ),
      ),
    );
  });

  test('completeSignTransactions splits hashes', () {
    expect(
      adapter.completeSignTransactions(
        Uri.parse('myapp://callback/success?transactionHashes=aaa,bbb'),
      ),
      ['aaa', 'bbb'],
    );
  });

  test('signIn launches the connect URL', () async {
    await adapter.signIn();
    expect(launched, hasLength(1));
    expect(launched.single.path, '/connect');
  });

  test('signIn throws when the launcher fails', () async {
    final failing = BitteWalletAdapter(
      config: adapter.config,
      launchUrl: (_) async => false,
    );
    expect(failing.signIn(), throwsA(isA<BitteWalletException>()));
  });
}
