# near_dart

Complete NEAR Protocol SDK for Flutter/Dart.

[![pub package](https://img.shields.io/pub/v/near_dart.svg)](https://pub.dev/packages/near_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A type-safe, platform-agnostic SDK for building NEAR Protocol applications with Flutter and Dart. Works on iOS, Android, Web, and Desktop.

<p align="center">
  <img src="https://raw.githubusercontent.com/0xjesus/near_dart/main/docs/demo/glass-android.gif" alt="NEAR Flutter SDK demo on Android" width="240"/>
</p>

<p align="center"><em>The example app — local Sign &amp; Send and wallet connect — running on Android.</em></p>

## Features

- **Local Signing & Sending**: ed25519 key pairs, Borsh serialization, `send_tx` broadcasting — byte-for-byte compatible with near-api-js
- **High-Level `Account` API**: `transfer()` / `callFunction()` in one call (nonce + block hash resolved automatically)
- **RPC Client**: Query blockchain state, accounts, contracts, and validators — FastNear endpoints by default, automatic failover
- **Wallet Integration**: Connect wallets via WalletConnect or deep links
- **NEAR Intents**: 1Click asset discovery, quote builder, swap lifecycle
  polling, Explorer history, signed-intent helpers, and Message Bus JSON-RPC
  for partner solver integrations
- **Typed Network Config**: `NearNetwork.mainnet`, `NearNetwork.testnet`, and
  `NearNetwork.custom(...)` with RPC, wallet, explorer, and chain metadata
- **Type-Safe Primitives**: `AccountId`, `NearToken`, `PublicKey`, `CryptoHash`
- **Transaction Building**: All NEAR actions, including NEP-591 Global Contracts
- **NEP-413 Support**: Message signing for authentication
- **Tested against the real chain**: every release runs a real sign-and-send E2E on testnet

## Platform support

| Feature | Android | iOS | Web | macOS | Windows | Linux |
|---|---|---|---|---|---|---|
| RPC queries | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Local signing (Borsh + ed25519) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| NEP-413 sign / verify | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| MyNearWallet redirect | ✅ | ✅ | ✅ | ⚠️ untested | ⚠️ untested | ⚠️ untested |
| Intear Wallet (bridge + deep link) | ✅ | ✅ | ⚠️ needs the native app | ⚠️ untested | ⚠️ untested | ⚠️ untested |
| HOT Wallet (relay) | ✅ mainnet only | ✅ mainnet only | ✅ mainnet only | ⚠️ untested | ⚠️ untested | ⚠️ untested |
| Secure key storage | ✅ Keystore | ✅ Keychain | ⚠️ plain storage (no OS secrets on web) | ✅ Keychain | ✅ DPAPI | ✅ libsecret |

Rows marked *untested* should work (pure Dart + url_launcher) but have no
verified end-to-end run yet. Security details:
[docs/security.md](https://github.com/0xjesus/near_dart/blob/main/docs/security.md).
NEAR Intents guide:
[docs/intents.md](https://github.com/0xjesus/near_dart/blob/main/docs/intents.md).
Reference app evidence:
[NearCoffee SDK + Intents tutorial](https://raw.githubusercontent.com/0xjesus/near-coffee/main/docs/demo/nearcoffee-sdk-intents-tutorial.mp4).

## Guides

- [First transaction in 5 minutes](https://github.com/0xjesus/near_dart/blob/main/docs/5-minute-guide.md)
- [Wallet recipes](https://github.com/0xjesus/near_dart/blob/main/docs/wallet-recipes.md)
- [Flutter architecture recipes](https://github.com/0xjesus/near_dart/blob/main/docs/flutter-architectures.md)
- [NEAR Intents](https://github.com/0xjesus/near_dart/blob/main/docs/intents.md)
- [NEAR AI](https://github.com/0xjesus/near_dart/blob/main/docs/near-ai.md)
- [Security model](https://github.com/0xjesus/near_dart/blob/main/docs/security.md)
- [Troubleshooting](https://github.com/0xjesus/near_dart/blob/main/docs/troubleshooting.md)
- [Release checklist](https://github.com/0xjesus/near_dart/blob/main/docs/release.md)

## Installation

```yaml
dependencies:
  near_dart: ^0.5.0
```

## Quick Start

```dart
import 'package:near_dart/near_dart.dart';

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


## Sign & Send Transactions (local keys)

The fastest way to execute transactions — no wallet redirect needed:

```dart
import 'package:near_dart/near_dart.dart';

void main() async {
  final client = NearRpcClient.testnet();

  final account = Account(
    accountId: AccountId('alice.testnet'),
    keyPair: await KeyPairEd25519.fromString('ed25519:<your secret key>'),
    client: client,
  );

  // Transfer NEAR
  final result = await account.transfer(
    receiverId: AccountId('bob.testnet'),
    amount: NearToken.fromNear(1),
  );

  switch (result) {
    case RpcSuccess(:final value):
      print('Executed! https://testnet.nearblocks.io/txns/${value.transaction.hash}');
    case RpcFailure(:final error):
      print('Failed: ${error.message}');
  }

  // Call a contract method that changes state
  await account.callFunction(
    contractId: AccountId('wrap.testnet'),
    methodName: 'near_deposit',
    deposit: NearToken.fromNear(1),
  );

  client.close();
}
```

Need lower-level control? Sign and broadcast manually:

```dart
final signed = await signTransaction(
  Transaction(
    signerId: AccountId('alice.testnet'),
    receiverId: AccountId('bob.testnet'),
    nonce: nonce,                 // access key nonce + 1
    blockHash: recentBlockHash,   // from viewAccessKey or block()
    actions: [TransferAction(deposit: NearToken.fromNear(1))],
  ),
  keyPair,
);
print(signed.hash);               // transaction hash (base58)
await client.sendTransaction(signed, waitUntil: TxExecutionStatus.final_);
```

Serialization and signatures are validated byte-for-byte against
canonical near-api-js vectors, and the full pipeline runs end-to-end
against real testnet in CI.

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

### Typed Network Configuration

```dart
final network = NearNetwork.custom(
  name: 'localnet',
  rpcUrl: 'http://127.0.0.1:3030',
  explorerUrl: 'http://127.0.0.1:4000',
);

final client = NearRpcClient.forNetwork(network);
print(network.transactionUrl('tx-hash'));
```

## NEAR Intents

Build cross-chain swap UX with the 1Click API without hand-routing solver
transactions:

```dart
final intents = OneClickClient();
final catalog = OneClickAssetCatalog(client: intents);
final builder = OneClickQuoteBuilder();

final wnear = await catalog.requireByAssetId('nep141:wrap.near');
final usdc = await catalog.requireByAssetId('nep141:usdc.near');

final request = builder.exactInput(
  originToken: wnear,
  destinationToken: usdc,
  amount: '0.1', // converted exactly from decimals, no float math
  refundTo: 'alice.near',
  recipient: 'alice.near',
);

final swap = OneClickSwapController(client: intents);
final quote = await swap.quote(request);

print(quote.quote.amountOutFormatted);
```

For live swaps set `dry: false`, send funds to the returned deposit address,
then use `submitDeposit()` and `pollStatus()` until `success`, `refunded`, or
`failed`. Historical 1Click activity is available through
`OneClickExplorerClient` for dashboards and support tooling.

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

### MyNearWallet Integration (connect once, then sign locally)

`signIn()` generates a **function-call key**, redirects to MyNearWallet to
provision it, and `completeSignIn()` stores the private key — so afterward
you call contracts **locally, with no more redirects**.

```dart
final adapter = MyNearWalletAdapter(
  config: MyNearWalletConfig(
    contractId: AccountId('app.near'),
    successUrl: 'myapp://callback/success',   // https URL on web
    failureUrl: 'myapp://callback/failure',
    network: MyNearWalletNetwork.mainnet,
  ),
  // Persist keys across the redirect/restarts (see the example app's
  // SharedPrefsKeyStore). Defaults to InMemoryKeyStore.
  keyStore: myPersistentKeyStore,
  launchUrl: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

// 1. Connect: generates a key and redirects to the wallet.
await adapter.signIn(contractId: AccountId('app.near'));

// 2. When the wallet redirects back (deep link on mobile, app URL on web):
final account = await adapter.completeSignIn(callbackUri);
print('Connected: ${account?.accountId}');

// 3. From now on, sign contract calls locally — no redirect:
final near = Account(
  accountId: account!.accountId,
  keyPair: (await adapter.keyFor(account.accountId))!,
  client: NearRpcClient.mainnet(),
);
await near.callFunction(
  contractId: AccountId('app.near'),
  methodName: 'set_greeting',
  args: {'greeting': 'hola'},
);
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
    switch (error.nearErrorCode) {
      case NearErrorCode.rpcTimeout:
        scheduleRetry();
      case NearErrorCode.rateLimited:
        useBackoff();
      default:
        showError(error.message);
    }
}
```

## Diagnostics And Wallet Security

Register a `NearLogger` at construction time and copy only explicitly safe
operational fields into telemetry:

```dart
void nearLogger(NearLogEvent event) {
  final safe = <String, Object?>{
    if (event.metadata['durationMs'] case final value?) 'durationMs': value,
    if (event.metadata['statusCode'] case final value?) 'statusCode': value,
    if (event.metadata['failureCode'] case final value?) 'failureCode': value,
  };
  print('${event.type.name} ${event.operation} $safe');
}

final client = NearRpcClient.mainnet(logger: nearLogger);
```

Do not add payloads, callback URLs, messages, nonces, signatures,
authorization values, or key material in a logger callback. For Flutter wallet
flows, `near_wallet_connect` provides opt-in on-chain policy:

```dart
import 'package:near_wallet_connect/near_wallet_connect.dart';

final wallet = NearWalletController(
  network: MyNearWalletNetwork.mainnet,
  contractId: AccountId('app.near'),
  logger: nearLogger,
  securityPolicy: const NearWalletSecurityPolicy(
    verifyAccessKeyOnConnect: true,
    transactionFinality: TxExecutionStatus.final_,
  ),
);
```

The defaults preserve existing behavior and perform neither check. Read the
[security model](https://github.com/0xjesus/near_dart/blob/main/docs/security.md)
and [troubleshooting guide](https://github.com/0xjesus/near_dart/blob/main/docs/troubleshooting.md)
for exact guarantees, relay caveats, and typed error handling.

## Example App

See the [example](example/) directory for a complete Flutter app demonstrating
every SDK feature: local Sign & Send, wallet connect (redirect + deep link),
and all RPC queries — with network switching between testnet and mainnet.

## Verified on real devices & chains

Recorded evidence from the example app running against **real NEAR testnet**
(no mocks at any layer):

| Demo | Evidence | On-chain proof |
|---|---|---|
| Android: generate key -> faucet -> **sign & send on-chain** | [video](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-sign-and-send-onchain.mp4) / [gif](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-sign-and-send-onchain.gif) | [`JByxPfTt...34cZG`](https://testnet.nearblocks.io/txns/JByxPfTtJwhEatZhU8FimkbkazygFajvg5ygnTH34cZG) |
| Android: wallet connect -> browser -> `nearsdk://` deep link -> connected | [video](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-wallet-connect-roundtrip.mp4) / [gif](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-wallet-connect-roundtrip.gif) | function-call key provisioning flow |

Additionally verified: web (Chrome, dart2js **and** dart2wasm — byte-identical
signatures vs near-api-js), real on-chain transfers from the browser, and a
scheduled CI E2E that signs and sends a real testnet transaction. iOS builds
are verified on every push via a macOS CI job.

## Testing

```bash
dart test --exclude-tags integration   # offline tests (no network)
dart test test/integration/testnet/    # live testnet RPC tests
dart test test/e2e/                    # incl. a REAL sign+send on testnet
```

Serialization and signatures are validated **byte-for-byte** against canonical
near-api-js@7.2.0 vectors (`test/fixtures/near_api_js_vectors.json`).

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [pub.dev](https://pub.dev/packages/near_dart)
- [GitHub](https://github.com/0xjesus/near_dart)
- [NEAR Protocol](https://near.org)
