# First NEAR Transaction In 5 Minutes

This guide is the shortest happy path for a Flutter or Dart developer who wants
to prove the SDK works before reading the rest of the docs.

## 1. Install

For a pure Dart app, CLI, server, or Flutter app with local signing:

```yaml
dependencies:
  near_dart: ^0.5.0
```

For a Flutter app that needs wallet UI:

```yaml
dependencies:
  near_wallet_connect: ^0.4.0
```

`near_wallet_connect` re-exports the most common `near_dart` types.

## 2. Query Chain State

```dart
import 'package:near_dart/near_dart.dart';

Future<void> main() async {
  final client = NearRpcClient.testnet();

  final status = await client.status();
  print(status.getOrThrow().chainId);

  final account = await client.viewAccount(
    accountId: AccountId('nearcoffee-jar.testnet'),
    blockReference: BlockReference.finality(Finality.final_),
  );
  print(account.getOrThrow().amount.toNearString(fractionDigits: 2));

  client.close();
}
```

## 3. Call A View Method

```dart
final supporters = await client.callFunction(
  accountId: AccountId('nearcoffee-jar.testnet'),
  methodName: 'total_tips',
  args: const {},
  blockReference: BlockReference.finality(Finality.final_),
);

print(supporters.getOrThrow().resultAsJson());
```

## 4. Use Typed NEP Helpers

```dart
final wnear = AccountId('wrap.testnet');

final metadata = await client.ftMetadata(tokenId: wnear);
print(metadata.getOrThrow().symbol);

final balance = await client.ftBalanceOf(
  tokenId: wnear,
  accountId: AccountId('alice.testnet'),
);
print(balance.getOrThrow());
```

## 5. Sign A Transaction Locally

Only do this with a testnet key you control. Do not paste seed phrases into
examples, issue comments, or AI chats.

```dart
final account = Account(
  accountId: AccountId('alice.testnet'),
  keyPair: await KeyPairEd25519.fromString('ed25519:<testnet-secret-key>'),
  client: client,
);

final result = await account.transfer(
  receiverId: AccountId('bob.testnet'),
  amount: NearToken.fromYocto('1'),
  waitUntil: TxExecutionStatus.final_,
);

final tx = result.getOrThrow();
print('https://testnet.nearblocks.io/txns/${tx.transaction.hash}');
```

## 6. Flutter Wallet UI

```dart
final controller = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('nearcoffee-jar.testnet'),
  methodNames: const ['tip'],
  callbackScheme: 'myapp',
);

await controller.init();

// In your widget tree:
NearConnectButton(controller: controller);
```

After the user connects, a function-call key is available for gas-only calls:

```dart
final signer = await controller.signer();
await signer?.callFunction(
  contractId: AccountId('nearcoffee-jar.testnet'),
  methodName: 'tip',
  args: {'message': 'hello'},
);
```

Function-call keys cannot attach deposits. For payments, ask the wallet to sign
the transaction.
