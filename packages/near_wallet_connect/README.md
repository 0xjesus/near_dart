# near_wallet_connect

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**One button. Every NEAR wallet.** Drop-in wallet connection for Flutter —
`NearConnectButton` opens a wallet picker (**MyNearWallet, Intear, HOT**), and
one controller gives you the same API whatever the user picked. Built on
[`near_dart`](https://pub.dev/packages/near_dart).

<p align="center">
  <img src="https://raw.githubusercontent.com/0xjesus/near_dart/main/docs/demo/glass-android.gif" alt="NEAR Flutter demo on Android" width="240"/>
</p>

## Add it

```yaml
dependencies:
  near_wallet_connect: ^0.2.0
```

## Use it (this is the whole integration)

```dart
import 'package:near_wallet_connect/near_wallet_connect.dart';

final wallet = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('app.testnet'),
  callbackScheme: 'myapp', // your mobile deep-link scheme
);

@override
void initState() {
  super.initState();
  wallet.init(); // restores the session + processes redirect callbacks
}

// In your build() — tapping it opens the wallet picker:
NearConnectButton(controller: wallet);
```

Connected. Now **one API, whatever the wallet**:

```dart
// 1. Gas-only contract calls, signed locally (function-call key — no popups):
final signer = await wallet.signer();
await signer!.callFunction(
  contractId: AccountId('app.testnet'),
  methodName: 'add_message',
  args: {'text': 'hello'},
);

// 2. "Sign in with NEAR" (NEP-413) — e.g. against a better-near-auth API:
final signed = await wallet.signMessage(Nep413Payload(
  message: 'Sign in to app.com',
  recipient: 'app.com',
  nonce: generateNep413Nonce(),
));

// 3. Payments & deposits, approved in the user's wallet:
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

That's it. See [`example/`](example/) for a complete minimal app.

## Supported wallets

| Wallet | Networks | Connect flow | `signer()` | `signMessage` | `sendTransactions` |
|---|---|---|---|---|---|
| **MyNearWallet** | testnet + mainnet | browser redirect | ✅ | via redirect² | via redirect² |
| **Intear** | testnet + mainnet | native app + WebSocket bridge¹ | ✅ | ✅ | ✅ |
| **HOT** | mainnet | native/Telegram app + relay¹ | — | ✅ | ✅ |

¹ Resolves in place — no inbound deep link needed.
² MyNearWallet signs per-transaction in the browser; use
`MyNearWalletAdapter.buildTransactionUrl` / `buildSignMessageUrl` from
`near_dart` for those flows.

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
- Keys persist via `SharedPrefsKeyStore` (swap in your own encrypted
  `KeyStore` for production mobile).

## License

MIT
