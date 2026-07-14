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
  securityPolicy: const NearWalletSecurityPolicy(
    verifyAccessKeyOnConnect: true,
    transactionFinality: TxExecutionStatus.final_,
  ),
);

await controller.init();
```

Use explicit `methodNames`. Empty method scope grants the function-call key
access to every method on the contract.

Both security-policy options are opt-in. Access-key verification checks fresh
and restored MyNearWallet/Intear function-call scope; HOT checks only that its
returned account/key pair exists. Transaction finality confirms hashes from
Intear/HOT `sendTransactions` with `txStatus` and then returns the original
wallet outcomes. See the [security model](security.md#optional-on-chain-policy)
for availability and residual metadata-trust tradeoffs.

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
callbacks that match the configured route and per-flow correlation value.
Callbacks are one-shot, replay cannot consume a later flow, and sign-in also
requires the returned public key to match the pending key. Pending
sign-message flows use `completeSignMessage`, which checks the original
request, state, correlation, and Ed25519 signature.

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

Intear verifies wallet-produced NEP-413 signatures, including an optional
message requested during connect, before returning them. Bridge connect and
transaction metadata are not all wallet-signed.

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

HOT verifies wallet-produced NEP-413 signatures before returning them. Relay
connect and transaction metadata remain unsigned; enable `transactionFinality`
and compare on-chain transaction contents for valuable operations.

HOT sessions created before authentic public-key persistence cannot be safely
restored. The controller clears those legacy sessions during `init()` and the
user must reconnect once.

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

## Typed Errors And Diagnostics

`controller.error` remains a display-ready `String?`; use
`controller.lastException` for stable handling:

```dart
switch (controller.lastException?.code) {
  case NearErrorCode.userRejected:
    showRetry();
  case NearErrorCode.rpcTimeout:
    showRetryLater();
  case NearErrorCode.accessKeyNotFound || NearErrorCode.accessKeyMismatch:
    showReconnect();
  case null:
    break;
  default:
    showError(controller.error ?? 'Wallet operation failed');
}
```

Pass a `NearLogger` to the controller for structured lifecycle events. Logger
callbacks must allowlist operational metadata and must never attach callback
URLs, messages, nonces, signatures, request bodies, credentials, or key
material. A complete safe example and recovery table are in
[Troubleshooting](troubleshooting.md#safe-diagnostics-and-typed-errors).
