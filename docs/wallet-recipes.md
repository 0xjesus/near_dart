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

## Feature And Platform Matrix

| Flow | Android | iOS | Web | macOS | Windows | Linux |
|---|---|---|---|---|---|---|
| MyNearWallet redirect | Verified | Verified | Verified | Needs device verification | Needs device verification | Needs device verification |
| Intear bridge + native app | Verified | Verified | Native wallet app required | Needs device verification | Needs device verification | Needs device verification |
| HOT relay + wallet app | Mainnet only | Mainnet only | Mainnet only | Needs device verification | Needs device verification | Needs device verification |
| Default key persistence | Encrypted | Encrypted | Plain origin storage | Encrypted | Encrypted | Encrypted where Secret Service is available |

RPC reads and local signing are supported on all six platforms. Wallet support
in the table means the complete launch/approval/return flow, not only that the
package compiles. Web storage is readable by same-origin JavaScript; treat XSS
as key compromise and use a restrictive Content Security Policy.

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

Mobile callback routes are `<scheme>://callback/success` and
`<scheme>://callback/failure`; with `callbackScheme: 'yourapp'` they become
`yourapp://callback/success` and `yourapp://callback/failure`. The SDK adds a
one-shot `_nearWalletFlow` query value (or a suffixed key if that name already
exists) and requires the exact value on return.

Sign-in success parameters are `account_id` and `public_key`; `all_keys` may
also be present. A failure can include `errorCode` and `errorMessage`.
Transaction success uses `transactionHashes`. Signed-message values are
normally in the URL fragment as `accountId`, `publicKey`, `signature`, and
`state`. Pass the original URI to the SDK unchanged; do not rebuild it from
selected fields.

### MyNearWallet On Web

The controller redirects in the current tab and uses the current page URL,
without its query or fragment, as both return routes. Configure the web host to
serve the Flutter entry point for that route. Then call `init()` before the
router removes callback query or fragment values:

```dart
final controller = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('your-contract.testnet'),
  methodNames: const ['your_method'],
);

await controller.init(); // reads Uri.base and restores SharedPrefsKeyStore
runApp(App(controller: controller));
```

The web default is `SharedPrefsKeyStore`, which preserves the pending key
across the wallet redirect and restores the connected key after reload. It is
not encrypted. Do not let a router redirect, normalize, or strip the callback
URL before `init()` completes.

Result handling is automatic after `controller.init()`. The SDK only accepts
callbacks that match the configured route and per-flow correlation value.
Callbacks are one-shot, replay cannot consume a later flow, and sign-in also
requires the returned public key to match the pending key. Pending
sign-message flows use `completeSignMessage`, which checks the original
request, state, correlation, and Ed25519 signature.

Payments require wallet signing. Function-call keys cannot attach deposits.

Common typed failures are `deepLinkUnavailable`, `userRejected`,
`missingCallback`, `walletResponseInvalid`, `accessKeyMismatch`, and
`cancelled`. A callback is one-shot; refreshing the callback URL after it was
consumed does not create a new session.

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

Intear launches `intear://<method>?session_id=...` and returns its response on
the same WebSocket bridge session. There is no inbound app callback URL and no
success/failure query parameter contract to register. The signed request,
bridge session, request method, and response are kept within one operation
budget. Browser use still requires an installed native wallet that can handle
the `intear://` scheme.

Android may suspend background sockets while the wallet is open. Short approval
flows work best; long on-chain flows should be tested on real devices.

Intear verifies wallet-produced NEP-413 signatures, including an optional
message requested during connect, before returning them. Bridge connect and
transaction metadata are not all wallet-signed.

Common typed failures are `deepLinkUnavailable`, `userRejected`,
`walletResponseInvalid`, `accountMismatch`, `signatureVerificationFailed`,
`rpcTimeout`, `rpcUnavailable`, `notConnected`, and `cancelled`.

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

HOT queues a request at its relay, launches
`hotwallet://hotcall-<requestId>` (with a Telegram fallback), and polls the
request-specific relay slot. There is no inbound app callback URL and no
success/failure query parameter contract. Selecting HOT on testnet fails with
`wrongNetwork` before a wallet operation is trusted.

HOT verifies wallet-produced NEP-413 signatures before returning them. Relay
connect and transaction metadata remain unsigned; enable `transactionFinality`
and compare on-chain transaction contents for valuable operations.

HOT sessions created before authentic public-key persistence cannot be safely
restored. The controller clears those legacy sessions during `init()` and the
user must reconnect once.

Common typed failures are `wrongNetwork`, `deepLinkUnavailable`,
`userRejected`, `walletResponseInvalid`, `signatureVerificationFailed`,
`rpcTimeout`, `rpcUnavailable`, `rateLimited`, and `cancelled`.

## Callback And Failure Summary

| Wallet | Inbound return | Success data | Failure data |
|---|---|---|---|
| MyNearWallet | Mobile custom scheme or current web route | Account/key, transaction hashes, or signed-message fragment | `errorCode`, `errorMessage`, invalid/missing/replayed callback |
| Intear | Same WebSocket bridge session | Typed bridge response bound to the active operation | Bridge rejection, invalid response, timeout, or closed session |
| HOT | Request-specific relay polling | Typed relay response for the request ID | Relay rejection, invalid response, timeout, rate limit, or unavailable wallet app |

Applications should branch on `NearSdkException.code`, not wallet-specific
message text. The controller exposes the same value as `lastException`.

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
