# near_wallet_connect

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**One button. Every NEAR wallet.** Drop-in wallet connection for Flutter —
`NearConnectButton` opens a wallet picker (**MyNearWallet, Intear, HOT**), and
one controller handles wallet selection, connection, and session state. Signing
capabilities remain wallet-specific, as described below. Built on
[`near_dart`](https://pub.dev/packages/near_dart).

<p align="center">
  <img src="https://raw.githubusercontent.com/0xjesus/near_dart/main/docs/demo/glass-android.gif" alt="NEAR Flutter demo on Android" width="240"/>
</p>

## Add it

```yaml
dependencies:
  near_wallet_connect: ^0.4.0
```

## Use it

Start with the
[lifecycle-safe ChangeNotifier recipe](https://github.com/0xjesus/near_dart/blob/main/docs/flutter-architectures.md#changenotifier-flutter-only),
or select the Provider, Riverpod, or Bloc/Cubit recipe in the same guide. Each
recipe handles and surfaces asynchronous `init()` failures, keeps the controller
alive until initialization settles, and disposes it exactly once so its platform
link subscription is cancelled. Do not drop the `init()` future or dispose the
controller while it is still initializing.

The examples below use `wallet` for the recipe-owned
`NearWalletController`. Tapping this button opens the wallet picker:

```dart
NearConnectButton(controller: wallet);
```

Connected. `signer()` is available for MyNearWallet and Intear sessions that
provision a function-call key. The controller's `signMessage` and
`sendTransactions` methods are available for **Intear and HOT only**; they
return `NearErrorCode.unsupportedOperation` when MyNearWallet is selected.

```dart
// MyNearWallet or Intear: gas-only calls signed with a function-call key.
final signer = await wallet.signer();
await signer!.callFunction(
  contractId: AccountId('app.testnet'),
  methodName: 'add_message',
  args: {'text': 'hello'},
);

// Intear or HOT: NEP-413 signing resolves through the wallet bridge/relay.
final signed = await wallet.signMessage(Nep413Payload(
  message: 'Sign in to app.com',
  recipient: 'app.com',
  nonce: generateNep413Nonce(),
));

// Intear or HOT: payments and deposits approved in the user's wallet.
await wallet.sendTransactions([
  {
    'receiverId': 'app.testnet',
    'actions': [
      {
        'type': 'FunctionCall',
        'params': {
          'methodName': 'tip',
          'args': {'message': 'gm'},
          'gas': '30000000000000',
          'deposit': '1000000000000000000000000', // 1 NEAR
        },
      },
    ],
  },
]);
```

For MyNearWallet message and transaction signing, use the secure redirect
starter/completion pairs from `near_dart`; do not use the URL-only builders for
new flows:

```dart
import 'package:near_dart/near_dart.dart';

final myNearWallet = MyNearWalletAdapter(
  config: MyNearWalletConfig(
    contractId: AccountId('app.testnet'),
    successUrl: 'myapp://wallet/success',
    failureUrl: 'myapp://wallet/failure',
    network: MyNearWalletNetwork.testnet,
  ),
  keyStore: wallet.keyStore,
  launchUrl: openExternalWalletUrl,
);

final request = SignMessageParams(
  message: 'Sign in to app.com',
  recipient: 'app.com',
  nonce: generateNep413Nonce(),
  state: createAndStoreCsrfState(),
);

// Starter: opens a correlated, one-shot flow and launches the wallet.
try {
  await myNearWallet.signMessage(request);
} on NearSdkException catch (error) {
  if (error.code != NearErrorCode.missingCallback) rethrow;
}

// Completion: pass the wallet-emitted callback URI through unchanged.
final signed = await myNearWallet.completeSignMessage(
  signMessageCallbackUri,
  request: request,
);

// Transaction starter/completion use the same correlated callback lifecycle.
try {
  await myNearWallet.signAndSendTransactions(transactions: transactions);
} on NearSdkException catch (error) {
  if (error.code != NearErrorCode.missingCallback) rethrow;
}
final outcomes = myNearWallet.handleTransactionCallback(
  transactionCallbackUri,
);
```

Keep the original request until completion. Never reconstruct a callback URI
from a configured base URL: the callback embedded in each launched wallet URL
contains correlation data that must survive unchanged. Completion checks the
exact route and correlation value and consumes the flow once, so replay is
rejected. `completeSignMessage` also checks `state` and verifies the Ed25519
signature over the exact emitted NEP-413 payload, including its callback URL.
For authentication, also enforce nonce freshness and recipient server-side and
verify that the returned key is authorized for the claimed account.

See [`example/`](example/) for a complete minimal app.

For lifecycle-safe ChangeNotifier, Provider, Riverpod, and Bloc/Cubit setups,
see the
[Flutter architecture recipes](https://github.com/0xjesus/near_dart/blob/main/docs/flutter-architectures.md).

Both security options above are opt-in. The first verifies fresh and restored
account/key pairs on chain; the second confirms returned transaction hashes
with `txStatus`. Confirmation does not authenticate unsigned relay metadata.
See the
[security model](https://github.com/0xjesus/near_dart/blob/main/docs/security.md)
for wallet-specific scope and residual trust.

## Diagnostics And Typed Errors

Pass an allowlisting logger to the controller. Never add callback URLs,
messages, nonces, signatures, request bodies, credentials, or key material.

```dart
void nearLogger(NearLogEvent event) {
  final safe = <String, Object?>{
    if (event.metadata['durationMs'] case final value?) 'durationMs': value,
    if (event.metadata['failureCode'] case final value?) 'failureCode': value,
    if (event.metadata['networkId'] case final value?) 'networkId': value,
  };
  print('${event.type.name} ${event.operation} $safe');
}

final wallet = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('app.testnet'),
  logger: nearLogger,
);

switch (wallet.lastException?.code) {
  case NearErrorCode.userRejected:
    showRetry();
  case NearErrorCode.rpcTimeout:
    showRetryLater();
  case NearErrorCode.accessKeyNotFound || NearErrorCode.accessKeyMismatch:
    showReconnect();
  case null:
    break;
  default:
    showError(wallet.error ?? 'Wallet operation failed');
}
```

`wallet.error` remains the compatible `String?` display message;
`wallet.lastException` is the typed `NearSdkException?`. See
[Troubleshooting](https://github.com/0xjesus/near_dart/blob/main/docs/troubleshooting.md#safe-diagnostics-and-typed-errors)
for recovery guidance by error code.

## Customize the UI

Use the default button for fast integration:

```dart
NearConnectButton(controller: wallet, compact: true);
```

Or keep the controller/picker logic and replace the visual states:

```dart
NearConnectButton(
  controller: wallet,
  connectBuilder: (context, controller, onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.account_balance_wallet_outlined),
      label: const Text('Connect'),
    );
  },
  connectedBuilder: (context, controller, onDisconnect) {
    return NearAccountBadge(
      accountId: controller.account!.accountId,
      wallet: controller.walletOption,
      onDisconnect: onDisconnect,
      compact: true,
    );
  },
);
```

Reusable pieces:

- `NearWalletPicker`
- `NearAccountBadge`
- `NearBalanceText`
- `NearTransactionStatusView`

## Supported wallets

| Wallet | Networks | Connect flow | `signer()` | `signMessage` | `sendTransactions` |
|---|---|---|---|---|---|
| **MyNearWallet** | testnet + mainnet | browser redirect | yes | secure adapter redirect² | secure adapter redirect² |
| **Intear** | testnet + mainnet | native app + WebSocket bridge¹ | yes | controller | controller |
| **HOT** | mainnet | native/Telegram app + relay¹ | no | controller | controller |

¹ Resolves in place — no inbound deep link needed.
² Use `signMessage` / `completeSignMessage` and
`signAndSendTransaction(s)` / `handleTransactionCallback`. URL-only builders
do not open the pending correlated flow required by the secure completion APIs.

> MyNearWallet remains fully supported until its announced sunset
> (October 31, 2026). Intear and HOT are additional options, not replacements —
> pick per user, at runtime.

## Platform setup (one-time)

The MyNearWallet callback uses a custom URL scheme (default `nearsdk://`).
Register it:

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<activity>`:

```xml
<intent-filter android:autoVerify="false">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="nearsdk"/>
</intent-filter>
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>nearsdk</string></array>
  </dict>
</array>
```

**Web** — no setup; the callback returns to your app URL. Intear and HOT need
no callback setup on any platform (responses arrive over their bridges).

## How it works

- **MyNearWallet**: full-page redirect (web) or system browser + deep-link
  callback (mobile). Connecting provisions a **function-call key**, stored so
  gas-only calls sign locally afterwards.
- **Intear**: a per-request WebSocket bridge session + `intear://` deep link;
  the wallet's response arrives over the socket. Connecting can also add a
  function-call key, so `signer()` works here too.
- **HOT**: requests are queued on HOT's relay and opened via `hotwallet://`;
  the app polls the relay for the response.
- Intear and HOT wallet-produced NEP-413 signatures are verified locally.
  Connect and transaction metadata are not all signed; relays remain
  availability dependencies.
- Keys persist via **`SecureKeyStore`** by default (Android Keystore /
  Apple Keychain / Windows DPAPI / Linux libsecret); on web — where no OS
  secret storage exists — a plain `SharedPrefsKeyStore` is used. Sessions
  from older versions migrate to secure storage automatically. Details:
  [docs/security.md](https://github.com/0xjesus/near_dart/blob/main/docs/security.md).
- Legacy HOT sessions that predate authentic public-key persistence are
  cleared during `init()` and require one reconnect.

## License

MIT
