import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NearNetwork', () {
    test('mainnet has complete production defaults', () {
      expect(NearNetwork.mainnet.name, 'mainnet');
      expect(NearNetwork.mainnet.index, 0);
      expect(NearNetwork.mainnet.chainId, 'near:mainnet');
      expect(NearNetwork.mainnet.rpcUrl, 'https://free.rpc.fastnear.com');
      expect(NearNetwork.mainnet.fallbackRpcUrls, [
        'https://rpc.mainnet.near.org',
      ]);
      expect(
        NearNetwork.mainnet.myNearWalletUrl,
        'https://app.mynearwallet.com',
      );
      expect(
        NearNetwork.mainnet.transactionUrl('abc').toString(),
        'https://nearblocks.io/txns/abc',
      );
    });

    test('testnet has complete production defaults', () {
      expect(NearNetwork.testnet.name, 'testnet');
      expect(NearNetwork.testnet.index, 1);
      expect(NearNetwork.testnet.chainId, 'near:testnet');
      expect(NearNetwork.testnet.rpcUrl, 'https://test.rpc.fastnear.com');
      expect(NearNetwork.testnet.fallbackRpcUrls, [
        'https://rpc.testnet.near.org',
      ]);
      expect(
        NearNetwork.testnet.myNearWalletUrl,
        'https://testnet.mynearwallet.com',
      );
      expect(NearNetwork.testnet.faucetUrl, 'https://helper.testnet.near.org');
      expect(
        NearNetwork.testnet.accountUrl('alice.testnet').toString(),
        'https://testnet.nearblocks.io/address/alice.testnet',
      );
    });

    test('custom network derives WalletConnect chain id by default', () {
      final network = NearNetwork.custom(
        name: 'localnet',
        rpcUrl: 'http://127.0.0.1:3030',
        fallbackRpcUrls: const ['http://127.0.0.1:3031'],
        explorerUrl: 'http://127.0.0.1:4000',
      );

      expect(network.name, 'localnet');
      expect(network.index, -1);
      expect(network.chainId, 'near:localnet');
      expect(network.fallbackRpcUrls, ['http://127.0.0.1:3031']);
      expect(network.myNearWalletUrl, isNull);
      expect(
        network.transactionUrl('txhash').toString(),
        'http://127.0.0.1:4000/txns/txhash',
      );
    });

    test('custom network accepts explicit wallet and chain URLs', () {
      final network = NearNetwork.custom(
        name: 'sandbox',
        chainId: 'near:sandbox-1',
        rpcUrl: 'https://rpc.example.com',
        explorerUrl: 'https://explorer.example.com',
        myNearWalletUrl: 'https://wallet.example.com',
      );

      expect(network.chainId, 'near:sandbox-1');
      expect(network.myNearWalletUrl, 'https://wallet.example.com');
    });

    test('values preserves enum-style public network lookup', () {
      expect(NearNetwork.values, [NearNetwork.mainnet, NearNetwork.testnet]);
    });
  });
}
