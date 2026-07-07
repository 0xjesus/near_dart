# Troubleshooting

## Web Callback Did Not Complete

Check:

- `controller.init()` runs before rendering wallet-dependent UI.
- The callback URL matches the configured success URL.
- You are parsing the URL fragment for MyNearWallet sign-message callbacks.
- Browser storage was not cleared between redirect and return.

For web, `SharedPrefsKeyStore` is plain browser storage. Treat web sessions as
lower trust and scope function-call keys tightly.

## Android Opens Wallet But Does Not Return

Check:

- `AndroidManifest.xml` has a matching scheme/host intent filter.
- The app was installed after changing the manifest.
- The callback scheme passed to `NearWalletController(callbackScheme:)` matches
  the manifest.
- The release manifest includes `INTERNET` permission.

## iOS Opens App But Account Is Not Connected

Check:

- `CFBundleURLTypes` includes the callback scheme.
- The wallet callback URL path matches the configured callback.
- You are not handling the deep link before `controller.init()` has restored
  the pending key.

## User Rejected Wallet Request

Wallets may return different rejection payloads. Use `controller.error` for
UI, and keep a retry path visible. Never silently clear a valid existing
session for a non-sign-in callback.

## Function-Call Key Cannot Pay

Function-call keys can pay gas but cannot attach deposits. Use wallet-signed
transactions for transfers, token transfers that require one yocto, storage
deposits, or payable contract calls.

## Transaction Signs But Fails On Chain

Common causes:

- Account has insufficient balance for gas or deposit.
- Method is not in the function-call key scope.
- Attached deposit is missing or wrong.
- Receiver account exists on a different network.
- The contract panicked; inspect logs and explorer status.

Use `waitUntil: TxExecutionStatus.final_` when your UX needs finality instead
of optimistic execution.

## RPC Works On Mobile But Fails On Web

Likely causes:

- RPC provider CORS policy blocks browser requests.
- Browser extension or corporate network blocks the endpoint.
- The app is using an endpoint that works server-side but not from browsers.

Try FastNear defaults or a browser-compatible RPC provider.

## Invalid Account ID Or Public Key

`near_dart >=0.4.0` validates account IDs and public keys strictly. Placeholder
values that used to pass now throw early. Use valid testnet fixture keys in
tests instead of strings like `ed25519:FakeKey`.

## NEAR Intents Quote Fails

Check:

- NEAR Intents is mainnet infrastructure; there is no public testnet.
- Dry quotes (`dry: true`) do not create a deposit address.
- `amount` is in smallest units, not a decimal string.
- `recipientType`, `refundType`, and address format match the destination.
- Do not ship partner API keys in mobile binaries.

## HOT Or Intear Relay Trust

Relays and bridges can delay or drop transport messages. For anything valuable,
verify wallet signatures where available and confirm transaction hashes through
RPC.

