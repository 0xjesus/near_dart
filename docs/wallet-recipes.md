# Wallet Recipes

Use `near_wallet_connect` when a Flutter app needs wallet UX. It provides
`NearWalletController` plus `NearConnectButton`, and keeps storage secure by
default on Android, iOS, macOS, Windows, and Linux.

## Controller Setup

```dart
final controller = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('your-contract.testnet'),
  methodNames: const ['method_one', 'method_two'],
  callbackScheme: 'yourapp',
);

await controller.init();
```

Use explicit `methodNames`. Empty method scope grants the function-call key
access to every method on the contract.

## Android Deep Link

`android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="yourapp" android:host="callback" />
</intent-filter>
```

Release builds also need internet access in the main manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## iOS URL Scheme

`ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>yourapp</string>
    </array>
  </dict>
</array>
```

## MyNearWallet

Networks: testnet and mainnet.

Flow: browser redirect to `/login`, then deep link/web redirect back to your
configured callback URL.

```dart
await controller.connect(wallet: NearWalletOption.myNearWallet);
```

Result handling is automatic after `controller.init()`. The SDK only accepts
callbacks that match the configured success/failure URLs and whose returned
public key matches the pending key.

Payments require wallet signing. Function-call keys cannot attach deposits.

## Intear

Networks: testnet and mainnet.

Flow: native-app deep link plus bridge session.

```dart
await controller.connect(wallet: NearWalletOption.intear);

final signed = await controller.signMessage(
  Nep413Payload(
    message: 'Sign in',
    nonce: generateNep413Nonce(),
    recipient: 'yourapp.com',
  ),
);
```

Android may suspend background sockets while the wallet is open. Short approval
flows work best; long on-chain flows should be tested on real devices.

## HOT Wallet

Networks: mainnet only.

Flow: relay plus `hotwallet://` deep link.

```dart
final controller = NearWalletController(
  network: MyNearWalletNetwork.mainnet,
  contractId: AccountId('your-contract.near'),
  appOrigin: 'https://yourapp.com',
);

await controller.connect(wallet: NearWalletOption.hot);
```

Treat relay transaction responses as hints. Confirm valuable settlement through
RPC before showing final success UX.

## Sign-In With NEAR

Use NEP-413 for authentication:

```dart
final payload = Nep413Payload(
  message: 'Sign in to Example',
  nonce: generateNep413Nonce(),
  recipient: 'example.com',
);

final signed = await controller.signMessage(payload);
final ok = await verifyNep413Signature(payload: payload, signed: signed);
```

Signature verification proves key possession. Servers should also check nonce
freshness, recipient, and whether the returned key belongs to the account.

