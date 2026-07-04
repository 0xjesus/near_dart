import 'package:near_dart/near_dart.dart';

/// A NEAR wallet the user can connect with.
///
/// MyNearWallet remains fully supported until its announced sunset
/// (October 31, 2026) — the additional wallets are options, not replacements.
enum NearWalletOption {
  myNearWallet(
    label: 'MyNearWallet',
    description: 'Web wallet — connect via browser redirect',
    supportsTestnet: true,
  ),
  intear(
    label: 'Intear Wallet',
    description: 'Native app — approve in the Intear app',
    supportsTestnet: true,
  ),
  hot(
    label: 'HOT Wallet',
    description: 'Native/Telegram app — mainnet only',
    supportsTestnet: false,
  );

  const NearWalletOption({
    required this.label,
    required this.description,
    required this.supportsTestnet,
  });

  final String label;
  final String description;
  final bool supportsTestnet;

  /// The wallets available on [network].
  static List<NearWalletOption> available(MyNearWalletNetwork network) => [
    for (final w in values)
      if (network == MyNearWalletNetwork.mainnet || w.supportsTestnet) w,
  ];
}
