# First NEAR Transaction In 5 Minutes

This is a copy-paste path from a funded testnet account to a view call and a
real transaction submitted with `near_dart`.

## 1. Create And Fund A Testnet Account

Install the current NEAR CLI and ask the testnet faucet to create an account:

```bash
npm install -g near-cli-rs@latest
near create-account <your-account.testnet> --useFaucet --networkId testnet
```

Replace `<your-account.testnet>` with a unique name ending in `.testnet`.
The CLI stores the generated key in its keychain. See the official
[Create an Account](https://docs.near.org/getting-started/create-account)
and [NEAR CLI](https://docs.near.org/tools/cli) guides if the faucet is rate
limited or the platform keychain needs a different setup.

Export only this disposable testnet account when the CLI prompts you:

```bash
near account export-account <your-account.testnet>
```

Never use a mainnet key in this guide. Do not paste a seed phrase or private
key into source files, issue comments, logs, screenshots, or AI chats.

## 2. Create The Dart Project

```bash
dart create -t console-simple first_near_tx
cd first_near_tx
dart pub add near_dart
```

Set the account ID and enter the exported testnet private key without placing
the key in shell history:

```bash
export NEAR_ACCOUNT_ID=<your-account.testnet>
read -s NEAR_PRIVATE_KEY
export NEAR_PRIVATE_KEY
```

## 3. Query, View, Sign, And Open The Explorer

Replace `bin/first_near_tx.dart` with:

```dart
import 'dart:io';

import 'package:near_dart/near_dart.dart';

Future<void> main() async {
  final accountIdValue = Platform.environment['NEAR_ACCOUNT_ID'];
  final privateKeyValue = Platform.environment['NEAR_PRIVATE_KEY'];
  if (accountIdValue == null || privateKeyValue == null) {
    throw StateError('Set NEAR_ACCOUNT_ID and NEAR_PRIVATE_KEY first');
  }

  final client = NearRpcClient.testnet();
  try {
    final accountId = AccountId(accountIdValue);

    final state = await client.viewAccount(
      accountId: accountId,
      blockReference: BlockReference.finality(Finality.final_),
    );
    print('Balance: ${state.getOrThrow().amount.toNearString()} NEAR');

    final metadata = await client.viewFunction<Map<String, dynamic>>(
      contractId: AccountId('wrap.testnet'),
      methodName: 'ft_metadata',
      decode: (json) => (json as Map).cast<String, dynamic>(),
    );
    print('View call: ${metadata.getOrThrow()['symbol']}');

    final signer = Account(
      accountId: accountId,
      keyPair: await KeyPairEd25519.fromString(privateKeyValue),
      client: client,
    );
    final sent = await signer.transfer(
      receiverId: AccountId('testnet'),
      amount: NearToken.oneYocto(),
      waitUntil: TxExecutionStatus.final_,
    );

    final hash = sent.getOrThrow().transaction.hash;
    print('Explorer: https://testnet.nearblocks.io/txns/$hash');
  } finally {
    client.close();
  }
}
```

Run it:

```bash
dart run
unset NEAR_PRIVATE_KEY
```

Expected output includes the funded balance, `wNEAR`, and a testnet explorer
URL. Open the URL to inspect the finalized one-yocto transaction.

## 4. Use Typed Token Helpers

The same client exposes NEP-141, NEP-145, and NEP-171 helpers:

```dart
final wnear = AccountId('wrap.testnet');
final metadata = await client.ftMetadata(tokenId: wnear);
final balance = await client.ftBalanceOf(
  tokenId: wnear,
  accountId: AccountId('your-account.testnet'),
);
print('${metadata.getOrThrow().symbol}: ${balance.getOrThrow()}');
```

Use `NearGas.teraGas(30)` for an explicit 30 TGas limit and
`NearToken.oneYocto()` for methods that require proof of full-access-key
intent.

## 5. Flutter Wallet UI

Add `near_wallet_connect` when the user, rather than the application, should
approve wallet actions:

```dart
final controller = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('your-contract.testnet'),
  methodNames: const ['your_method'],
  callbackScheme: 'myapp',
);

await controller.init();

// In the widget tree:
NearConnectButton(controller: controller);
```

Complete Android, iOS, and web callback setup in
[Wallet Recipes](wallet-recipes.md) before testing a redirect wallet.
Function-call keys cannot attach deposits; use the wallet transaction flow for
payments.
