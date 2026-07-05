# Security model

This page describes what secrets the `near_dart` / `near_wallet_connect`
packages handle, where they are stored, which parts of a wallet flow are
verified by the SDK, and what remains a trust assumption your app should
know about. It reflects the fixes shipped for the 2026-07-05 external
security audit.

## What secrets the SDK handles

| Secret | Created by | Purpose | Lives in |
|---|---|---|---|
| **Function-call key** | the SDK, at connect time | signs gas-only contract calls locally | your `KeyStore` |
| **Intear app key** | the SDK, at connect time | authenticates bridge requests to Intear | your `KeyStore` |
| **Full-access keys** | never handled | payments/sign-message happen inside the user's wallet | the wallet app |

The SDK never sees seed phrases or full-access private keys. Function-call
keys cannot move funds (deposits require the wallet), but they can spend
gas and call your contract — treat them as secrets.

## Key storage

- **`SecureKeyStore`** (default on Android, iOS, macOS, Windows, Linux) —
  backed by `flutter_secure_storage`: Android Keystore, Apple Keychain,
  Windows DPAPI, Linux Secret Service. Existing sessions from older
  versions are migrated out of plain preferences automatically.
- **`SharedPrefsKeyStore`** (default on web only) — plain, unencrypted
  storage. On web there is no OS secret storage: any same-origin script
  can read it, so treat web sessions as lower trust and prefer short-lived
  function-call keys with narrow method scopes.
- Bring your own store by implementing `KeyStore` (e.g. hardware-backed or
  server-side custody) and passing it to `NearWalletController(keyStore:)`.

## Redirect & deep-link flows (MyNearWallet)

Threats: a malicious app or page crafts a deep link that looks like a
wallet callback (session fixation / account spoofing), or a forged
sign-message result.

Mitigations in the SDK:

- `completeSignIn` only accepts callbacks that land on the **configured
  success/failure URLs**, requires a `public_key` in the callback, and
  requires it to **match the pending key** generated for this sign-in.
  Anything else is ignored or rejected.
- A callback that is not a pending sign-in (e.g. a transaction-result
  redirect) can never clear or replace the connected session.
- `completeSignMessage` validates the `state` parameter (CSRF) and
  **cryptographically verifies** the ed25519 signature over the exact
  NEP-413 payload the app requested — including the `callbackUrl` that
  redirect wallets embed in the signed bytes.

Remaining app responsibility: register your callback scheme correctly
(Android `intent-filter`, iOS `CFBundleURLTypes`) and, for auth flows,
check on-chain that the returned key belongs to the claimed account
(`view_access_key`) — signature verification proves key possession, not
account ownership.

## Bridge & relay flows (Intear, HOT)

- **Intear**: every request is signed with the app key
  (`sha256("{nonce}|{payload}")`, ed25519) so the wallet can authenticate
  the dApp. Responses arrive over the same WebSocket session that created
  the request. When a response carries a NEP-413 signed message, verify it
  with `verifyNep413Signature`. Trust assumption: the bridge service
  (`logout-bridge-service.intear.tech`) can drop or delay messages but a
  forged "connected" response would still need the wallet's approval UI to
  have produced meaningful signatures for anything that matters on-chain.
- **HOT**: requests/responses are relayed via `h4n.app` keyed by
  `sha1(request)`. The relay is trusted for transport; transaction results
  should be treated as **hints** and confirmed via RPC (the transaction
  hash can be looked up independently) before showing success UX for
  anything valuable.

## General recommendations for production apps

1. Scope function-call keys to one contract and explicit `methodNames`.
2. Verify NEP-413 results server-side for Sign-in-with-NEAR (nonce
   freshness, recipient match, on-chain key check).
3. Confirm payments via RPC (`tx` status) rather than trusting redirect
   parameters — callback URLs are user-visible and replayable.
4. On web, assume storage is readable by successful XSS: keep sessions
   short and permissions narrow.
5. Report vulnerabilities privately via GitHub security advisories.
