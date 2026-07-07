/// Typed NEAR network configuration.
///
/// Use [NearNetwork.mainnet] or [NearNetwork.testnet] for public networks, or
/// [NearNetwork.custom] when an app runs against a private RPC/localnet.
class NearNetwork {
  /// Creates a complete network configuration.
  const NearNetwork({
    required this.name,
    required this.chainId,
    required this.rpcUrl,
    this.fallbackRpcUrls = const [],
    required this.explorerUrl,
    this.myNearWalletUrl,
    this.faucetUrl,
  });

  /// NEAR mainnet defaults.
  static const mainnet = NearNetwork(
    name: 'mainnet',
    chainId: 'near:mainnet',
    rpcUrl: 'https://free.rpc.fastnear.com',
    fallbackRpcUrls: ['https://rpc.mainnet.near.org'],
    explorerUrl: 'https://nearblocks.io',
    myNearWalletUrl: 'https://app.mynearwallet.com',
  );

  /// NEAR testnet defaults.
  static const testnet = NearNetwork(
    name: 'testnet',
    chainId: 'near:testnet',
    rpcUrl: 'https://test.rpc.fastnear.com',
    fallbackRpcUrls: ['https://rpc.testnet.near.org'],
    explorerUrl: 'https://testnet.nearblocks.io',
    myNearWalletUrl: 'https://testnet.mynearwallet.com',
    faucetUrl: 'https://helper.testnet.near.org',
  );

  /// Public networks, matching the old enum-style API order.
  static const values = [mainnet, testnet];

  /// Creates a custom NEAR-like network configuration.
  ///
  /// [chainId] should use the WalletConnect namespace form, for example
  /// `near:localnet`. The RPC status `chain_id` is usually [name].
  factory NearNetwork.custom({
    required String name,
    required String rpcUrl,
    String? chainId,
    List<String> fallbackRpcUrls = const [],
    required String explorerUrl,
    String? myNearWalletUrl,
    String? faucetUrl,
  }) {
    return NearNetwork(
      name: name,
      chainId: chainId ?? 'near:$name',
      rpcUrl: rpcUrl,
      fallbackRpcUrls: List.unmodifiable(fallbackRpcUrls),
      explorerUrl: explorerUrl,
      myNearWalletUrl: myNearWalletUrl,
      faucetUrl: faucetUrl,
    );
  }

  /// Human-readable NEAR network id, such as `mainnet` or `testnet`.
  final String name;

  /// WalletConnect chain id, such as `near:mainnet`.
  final String chainId;

  /// Primary JSON-RPC endpoint.
  final String rpcUrl;

  /// Fallback RPC endpoints, tried after [rpcUrl] on transport failures.
  final List<String> fallbackRpcUrls;

  /// Base block-explorer URL.
  final String explorerUrl;

  /// MyNearWallet base URL, when that wallet supports this network.
  final String? myNearWalletUrl;

  /// Faucet/helper URL, when the network exposes one.
  final String? faucetUrl;

  /// Enum-style index for [mainnet] and [testnet], or `-1` for custom networks.
  int get index => values.indexOf(this);

  /// Explorer URL for a transaction hash.
  Uri transactionUrl(String hash) => Uri.parse('$explorerUrl/txns/$hash');

  /// Explorer URL for an account.
  Uri accountUrl(String accountId) =>
      Uri.parse('$explorerUrl/address/$accountId');

  @override
  String toString() => 'NearNetwork($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearNetwork &&
          other.name == name &&
          other.chainId == chainId &&
          other.rpcUrl == rpcUrl &&
          _sameList(other.fallbackRpcUrls, fallbackRpcUrls) &&
          other.explorerUrl == explorerUrl &&
          other.myNearWalletUrl == myNearWalletUrl &&
          other.faucetUrl == faucetUrl;

  @override
  int get hashCode => Object.hash(
    name,
    chainId,
    rpcUrl,
    Object.hashAll(fallbackRpcUrls),
    explorerUrl,
    myNearWalletUrl,
    faucetUrl,
  );

  static bool _sameList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
