# near_wallet_connect

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Drop-in **NEAR wallet connection for Flutter** — adaptive connect (web
redirect, mobile deep links), persistent key storage, and a ready-made
`NearConnectButton`. Built on [`near_dart`](https://pub.dev/packages/near_dart).

Connecting provisions a **function-call key** and stores it, so afterward you
sign contract calls **locally — no more redirects**.

## Add it

```yaml
dependencies:
  near_wallet_connect: ^0.1.0
```

## Use it (this is the whole integration)

```dart
import 'package:near_wallet_connect/near_wallet_connect.dart';

final wallet = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('app.testnet'),
  callbackScheme: 'nearsdk', // your mobile deep-link scheme
);

@override
void initState() {
  super.initState();
  wallet.init(); // restores the session + processes the redirect callback
}

// In your build():
NearConnectButton(controller: wallet);

// After connect, sign locally — no redirect:
final signer = await wallet.signer();
await signer!.callFunction(
  contractId: AccountId('app.testnet'),
  methodName: 'add_message',
  args: {'text': 'hello'},
);
```

That's it. See [`example/`](example/) for a complete minimal app.

## Platform setup (one-time)

The mobile callback uses a custom URL scheme (default `nearsdk://`). Register it:

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

**Web** — no setup; the callback returns to your app URL.

## How it works

- **Web**: `connect()` does a full-page redirect to MyNearWallet; on return
  `init()` reads the callback from the app URL.
- **Mobile/desktop**: launches the system browser; the callback arrives via
  the deep-link scheme (`app_links`).
- Keys persist via `SharedPrefsKeyStore` (swap in your own encrypted
  `KeyStore` for production mobile).

> MyNearWallet is the supported wallet today. Its redirect pattern carries to
> successor wallets; adapters for more wallets are planned.

## License

MIT
