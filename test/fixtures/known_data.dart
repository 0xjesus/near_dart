/// Known test data for NEAR testnet and mainnet.
///
/// This file contains real accounts, contracts, and data that always exist
/// on the NEAR blockchain. All tests use this real data - NO MOCKS.
library;

import 'package:near_dart/near_dart.dart';

/// Known testnet accounts that always exist.
class TestnetAccounts {
  TestnetAccounts._();

  /// The testnet faucet/root account
  static final AccountId testnet = AccountId('testnet');

  /// The NEAR root account on testnet
  static final AccountId near = AccountId('near');

  /// Wrapped NEAR contract on testnet
  static final AccountId wrapTestnet = AccountId('wrap.testnet');

  /// Aurora contract on testnet
  static final AccountId aurora = AccountId('aurora');

  /// List of all known testnet accounts for iteration
  static final List<AccountId> all = [testnet, near, wrapTestnet];
}

/// Known testnet contracts with their methods.
class TestnetContracts {
  TestnetContracts._();

  /// wrap.testnet - Wrapped NEAR token contract
  static const wrapTestnet = ContractInfo(
    accountId: 'wrap.testnet',
    methods: [
      'ft_metadata',
      'ft_balance_of',
      'storage_balance_of',
      'ft_total_supply',
    ],
  );

  /// List of all known testnet contracts
  static const List<ContractInfo> all = [wrapTestnet];
}

/// Known mainnet accounts that always exist.
class MainnetAccounts {
  MainnetAccounts._();

  /// The NEAR root account on mainnet
  static final AccountId near = AccountId('near');

  /// Aurora contract on mainnet
  static final AccountId aurora = AccountId('aurora');

  /// NearCrowd application
  static final AccountId nearcrowd = AccountId('app.nearcrowd.near');

  /// Wrapped NEAR contract on mainnet
  static final AccountId wrapNear = AccountId('wrap.near');

  /// USDT contract on mainnet
  static final AccountId usdt = AccountId('usdt.tether-token.near');

  /// List of all known mainnet accounts for iteration
  static final List<AccountId> all = [near, aurora, wrapNear, usdt];
}

/// Known mainnet contracts with their methods.
class MainnetContracts {
  MainnetContracts._();

  /// wrap.near - Wrapped NEAR token contract
  static const wrapNear = ContractInfo(
    accountId: 'wrap.near',
    methods: [
      'ft_metadata',
      'ft_balance_of',
      'storage_balance_of',
      'ft_total_supply',
    ],
  );

  /// usdt.tether-token.near - USDT stablecoin contract
  static const usdt = ContractInfo(
    accountId: 'usdt.tether-token.near',
    methods: ['ft_metadata', 'ft_balance_of', 'ft_total_supply'],
  );

  /// List of all known mainnet contracts
  static const List<ContractInfo> all = [wrapNear, usdt];
}

/// Information about a known contract.
class ContractInfo {
  const ContractInfo({required this.accountId, required this.methods});

  /// The contract's account ID
  final String accountId;

  /// Known view methods on this contract
  final List<String> methods;

  /// Get the AccountId object
  AccountId get account => AccountId(accountId);
}

/// Known public keys for testing.
class KnownPublicKeys {
  KnownPublicKeys._();

  /// A valid ed25519 public key format
  static const ed25519Valid =
      'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp';

  /// A valid secp256k1 public key format
  static const secp256k1Valid =
      'secp256k1:5ftgm7wYK5gtVqq1kxMGy7gSudkrfYCbpsjL6sH1nwx2oj5NtSXqg6EYgAAeL';
}

/// Known block hashes for testing (format examples).
class KnownBlockHashes {
  KnownBlockHashes._();

  /// A valid base58 block hash format
  static const validFormat = '9FsxVXBh5p1J7EBP2LXB7j2Z3nVqgDctPCbKxVJkNs7f';

  /// Another valid format example
  static const anotherValidFormat = '11111111111111111111111111111111';
}

/// Accounts that should NOT exist (for error testing).
class NonExistentAccounts {
  NonExistentAccounts._();

  /// A testnet account that definitely doesn't exist
  static final AccountId testnetNonExistent = AccountId(
    'this-account-definitely-does-not-exist-99999.testnet',
  );

  /// A mainnet account that definitely doesn't exist
  static final AccountId mainnetNonExistent = AccountId(
    'this-account-definitely-does-not-exist-99999.near',
  );
}

/// Expected FT metadata from known contracts.
class ExpectedFtMetadata {
  ExpectedFtMetadata._();

  /// wrap.testnet and wrap.near should return this
  static const wrappedNear = FtMetadataExpectation(
    name: 'Wrapped NEAR fungible token',
    symbol: 'wNEAR',
    decimals: 24,
  );

  /// usdt.tether-token.near should return this
  static const usdt = FtMetadataExpectation(
    name: 'Tether USD',
    symbol: 'USDt',
    decimals: 6,
  );
}

/// Expected FT metadata structure for validation.
class FtMetadataExpectation {
  const FtMetadataExpectation({
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  final String name;
  final String symbol;
  final int decimals;
}

/// RPC endpoint URLs.
class RpcEndpoints {
  RpcEndpoints._();

  static const testnet = 'https://test.rpc.fastnear.com';
  static const mainnet = 'https://free.rpc.fastnear.com';
}

/// MyNearWallet URLs for testing.
class WalletUrls {
  WalletUrls._();

  static const mainnetWallet = 'https://app.mynearwallet.com';
  static const testnetWallet = 'https://testnet.mynearwallet.com';
}
