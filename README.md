# near_flutter

Complete NEAR Protocol SDK for Flutter/Dart.

[![pub package](https://img.shields.io/pub/v/near_flutter.svg)](https://pub.dev/packages/near_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A type-safe, platform-agnostic SDK for building NEAR Protocol applications with Flutter and Dart. Works on iOS, Android, Web, and Desktop.

## Features

- **RPC Client**: Query blockchain state, accounts, contracts, and validators
- **Wallet Integration**: Connect wallets via WalletConnect or deep links
- **Type-Safe Primitives**: `AccountId`, `NearToken`, `PublicKey`, `CryptoHash`
- **Transaction Building**: Construct and sign transactions with multiple actions
- **NEP-413 Support**: Message signing for authentication

## Installation

```yaml
dependencies:
  near_flutter: ^0.1.0
```

## Quick Start

```dart
import 'package:near_flutter/near_flutter.dart';

void main() async {
  // Create client (mainnet or testnet)
  final client = NearRpcClient.mainnet();

  // Get network status
  final status = await client.status();
  switch (status) {
    case RpcSuccess(:final value):
      print('Chain: ${value.chainId}');
      print('Block: ${value.syncInfo.latestBlockHeight}');
    case RpcFailure(:final error):
      print('Error: ${error.message}');
  }

  // Query account
  final result = await client.viewAccount(
    accountId: AccountId('alice.near'),
    blockReference: BlockReference.finality(Finality.final_),
  );

  if (result.isSuccess) {
    final account = result.getOrNull()!;
    print('Balance: ${account.amount.toNear()} NEAR');
  }

  client.close();
}
```

## RPC Client

### Network Status

```dart
final result = await client.status();
```

### Account Information

```dart
final result = await client.viewAccount(
  accountId: AccountId('alice.near'),
  blockReference: BlockReference.finality(Finality.final_),
);
```

### Call Contract View Function

```dart
final result = await client.callFunction(
  accountId: AccountId('token.near'),
  methodName: 'ft_balance_of',
  args: {'account_id': 'alice.near'},
  blockReference: BlockReference.finality(Finality.final_),
);

if (result.isSuccess) {
  final balance = result.getOrNull()!.resultAsJson();
  print('Token balance: $balance');
}
```

### Validators

```dart
final result = await client.validators();
if (result.isSuccess) {
  final validators = result.getOrNull()!;
  print('Current validators: ${validators.currentValidators.length}');
}
```

## Wallet Integration

### Building Transactions

```dart
// Simple transfer
final tx = Transaction(
  signerId: AccountId('alice.near'),
  receiverId: AccountId('bob.near'),
  actions: [
    TransferAction(deposit: NearToken.fromNear(1)),
  ],
);

// Contract function call
final tx = Transaction(
  signerId: AccountId('alice.near'),
  receiverId: AccountId('token.near'),
  actions: [
    FunctionCallAction(
      methodName: 'ft_transfer',
      args: {'receiver_id': 'bob.near', 'amount': '1000000'},
      deposit: NearToken.oneYocto(),
    ),
  ],
);
```

### Action Types

```dart
CreateAccountAction()
DeployContractAction(code: wasmBytes)
FunctionCallAction(methodName: 'method', args: {...}, deposit: NearToken.zero())
TransferAction(deposit: NearToken.fromNear(10))
StakeAction(stake: NearToken.fromNear(100), publicKey: PublicKey('ed25519:...'))
AddKeyAction(publicKey: key, accessKey: FullAccessKey())
DeleteKeyAction(publicKey: key)
DeleteAccountAction(beneficiaryId: AccountId('beneficiary.near'))
```

### MyNearWallet Integration

```dart
final adapter = MyNearWalletAdapter(
  config: MyNearWalletConfig(
    contractId: AccountId('app.near'),
    successUrl: 'myapp://callback/success',
    failureUrl: 'myapp://callback/failure',
    network: MyNearWalletNetwork.mainnet,
  ),
  launchUrl: (uri) async {
    // Use url_launcher package
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  },
);

// Sign in
await adapter.signIn(contractId: AccountId('app.near'));

// Handle callback in your app
final callback = adapter.handleCallback(callbackUri);
if (callback.isSuccess) {
  print('Connected: ${callback.accountId}');
}
```

## Type-Safe Primitives

### AccountId

```dart
final account = AccountId('alice.near');  // Validates format
```

### NearToken

```dart
final amount = NearToken.fromNear(10);     // 10 NEAR
final small = NearToken.oneYocto();        // 1 yoctoNEAR
final zero = NearToken.zero();
print(amount.toNear());  // 10.0
```

### PublicKey

```dart
final key = PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp');
print(key.keyType);  // KeyType.ed25519
```

### BlockReference

```dart
BlockReference.finality(Finality.final_)  // Latest finalized
BlockReference.finality(Finality.optimistic)  // Latest (may reorg)
BlockReference.blockId(123456789)  // Specific height
BlockReference.blockHash(CryptoHash('...'))  // Specific hash
```

## Error Handling

```dart
final result = await client.viewAccount(...);

switch (result) {
  case RpcSuccess(:final value):
    print('Balance: ${value.amount.toNear()}');
  case RpcFailure(:final error):
    switch (error.kind) {
      case RpcErrorKind.rpcError:
        print('RPC error: ${error.message}');
      case RpcErrorKind.networkError:
        print('Network error');
      case RpcErrorKind.timeout:
        print('Request timeout');
      default:
        print('Error: ${error.message}');
    }
}
```

## Example App

See the [example](example/) directory for a complete Flutter app demonstrating network status and account lookup.

## Testing

```bash
dart test
```

111 tests covering unit tests, integration tests against NEAR testnet and mainnet.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [pub.dev](https://pub.dev/packages/near_flutter)
- [GitHub](https://github.com/0xjesus/near_flutter)
- [NEAR Protocol](https://near.org)
