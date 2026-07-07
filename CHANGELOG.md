## 0.5.0

- Add experimental NEAR Intents support: typed 1Click REST client
  (`OneClickClient`), generated-intent NEP-413 helpers, ANY_INPUT withdrawal
  status, asset catalog and exact amount helpers, quote builder, swap lifecycle
  controller, Explorer API client, and Message Bus JSON-RPC client
  (`SolverRelayClient`) for partner solver integrations.
- Add typed NEP helpers for FT (NEP-141), NFT (NEP-171), and storage
  management (NEP-145) workflows.
- Add typed network configuration (`NearNetwork.mainnet`, `.testnet`,
  `.custom(...)`) with RPC, fallback, WalletConnect chain, wallet, faucet, and
  explorer URLs.
- Add adoption docs: 5-minute guide, wallet recipes, troubleshooting,
  release checklist, NEAR Intents, and NEAR AI guidance.
- Expand CI coverage with `near_wallet_connect` tests and example builds for
  Linux, macOS, and Windows.
- Improve `NearConnectButton` customization and add lightweight Flutter wallet
  widgets in `near_wallet_connect`.

## 0.4.0

Security release addressing an external audit (2026-07-05). Thanks to
frolvlad for the review.

**Breaking**
- `AccountId` enforces the full nearcore account grammar (min length 2, no
  leading/trailing/consecutive separators). Previously-accepted invalid
  IDs now throw `ArgumentError`.
- `PublicKey` requires valid base58 data of the exact key length (ed25519:
  32 bytes, secp256k1: 64). Placeholder keys now throw.
- `MyNearWalletAdapter.handleSignMessageCallback` throws `FormatException`
  when `accountId`/`publicKey`/`signature` are missing instead of filling
  placeholders.

**Security**
- `completeSignIn` only accepts callbacks landing on the configured
  success/failure URLs and requires the returned `public_key` to match the
  pending key — crafted deep links can no longer spoof a session.
- New `completeSignMessage()` verifies the callback `state` and the
  ed25519 signature over the exact NEP-413 payload requested (including
  the redirect `callbackUrl`); throws `SignatureVerificationException`.
- New `verifyNep413Signature()` helper (also useful server-side).

**Other**
- Explicit `platforms:` declarations; README install snippets current;
  platform/feature support matrix; `docs/security.md` threat model.

## 0.3.1

- Fix: `MyNearWalletAdapter.handleSignMessageCallback` now parses the
  wallet's result from the URL **hash fragment** (`callback#accountId=…`),
  which is how MyNearWallet's `/sign-message` redirect returns it. Query
  parameters are still accepted.

## 0.3.0

- **NEP-413 message signing** (`Nep413Payload`, `signNep413Message`,
  `generateNep413Nonce`) — "Sign in with NEAR" without a transaction,
  hash-validated byte-for-byte against near-kit and verified live against a
  better-near-auth API.
- **Intear Wallet adapter** (`IntearWalletAdapter`) — native-app connect,
  NEP-413 signing and wallet-signed transactions via Intear's WebSocket
  bridge + `intear://` deep links. Testnet supported.
- **HOT Wallet adapter** (`HotWalletAdapter`) — connect, NEP-413 signing and
  wallet-signed transactions via HOT's HTTP relay + `hotwallet://` deep
  links. Mainnet only.
- MyNearWallet remains fully supported — the new wallets are additional
  options ahead of MNW's announced sunset (October 31, 2026).
- New dependency: `web_socket_channel`.

## 0.2.2

- Docs: add an Android demo GIF (glass example app) to the README.

## 0.2.1

- Docs: "Verified on real devices & chains" — recorded Android-emulator + web
  evidence and the explorer tx for the on-chain demos.
- Example: full "NEAR Terminal" glassmorphism redesign of the reference app
  (animated dark glass, NEAR branding), verified on web and Android.
- Tests: updated testnet integration tests for real 2026 RPC provider behavior
  (FastNear empty key lists, TOO_LARGE_CONTRACT_STATE).
- dartdoc: fixed unresolved references (now 0 warnings).

## 0.2.0

The release that makes near_dart a **full SDK**: local signing and
transaction broadcasting, validated byte-for-byte against near-api-js and
end-to-end against real testnet.

### Added

- **Local transaction signing**
  - `KeyPairEd25519`: generate, import (`ed25519:` extended secret or
    32-byte seed), sign, verify
  - `signTransaction(transaction, keyPair)` → `SignedTransaction` with
    `hash` and `encodeToBase64()`
  - `verifySignature()` for standalone signature checks
- **Borsh serialization in the core** (`BorshWriter`,
  `serializeTransaction`, `serializeSignedTransaction`, `sha256Hash`),
  validated byte-for-byte against canonical near-api-js@7.2.0 vectors
- **Transaction broadcasting**: `NearRpcClient.sendTransaction` (`send_tx`
  with configurable `TxExecutionStatus` wait levels) and
  `sendTransactionAsync` (`broadcast_tx_async`)
- **High-level `Account` API**: `transfer()`, `callFunction()`,
  `signAndSendTransaction()` — resolves nonce + block hash, signs and
  broadcasts in one call, with local nonce tracking for consecutive sends
- **NEP-591 Global Contracts**: `DeployGlobalContractAction`,
  `UseGlobalContractAction` (by code hash or account ID)
- **base58 encoding/decoding** (`base58Encode`, `base58Decode`)
- `Transaction` now carries optional `publicKey`, `nonce`, `blockHash`
  (+ `copyWith`)
- **`NearToken` hardening**: exact `parse()` (decimal NEAR → yocto, no
  float), `toNearString()` (precise display, optional fixed decimals), and
  safe arithmetic (`+`, `-` with negative guard, `<`/`>`/`<=`/`>=`,
  `compareTo`). `toString()` is now exact.
- **Configurable RPC `timeout`** (default 30s): a stalled node yields
  `RpcError.timeout` and triggers failover instead of hanging forever
- Real-transaction E2E test against testnet (faucet account → transfer →
  delete), wired into scheduled CI
- Verified on every platform: VM, web (dart2js **and** dart2wasm) — local
  signing produces identical bytes on all

- **Real wallet sign-in (function-call key + local signing)**:
  `MyNearWalletAdapter.signIn()` now generates an ed25519 function-call
  key pair, launches `/login` with its **real public key** (fixing a bug
  where the literal string `'true'` was sent) and `methodNames` as
  repeated query params; `completeSignIn(callbackUri)` verifies and
  promotes the provisioned key so subsequent contract calls are signed
  **locally with no further redirects**. `keyFor(accountId)` exposes the
  stored key for use with `Account`.
- **`KeyStore` abstraction** (`KeyStore`, `InMemoryKeyStore`): pure-Dart
  key persistence interface mirroring near-api-js; the adapter's
  `getAccounts`/`isSignedIn`/`signOut` read from it so a connection
  survives app restarts. Provide a persistent implementation (see the
  example's `SharedPrefsKeyStore`) to survive the web sign-in redirect.
- Example app: redirect-based Connect Wallet flow verified end-to-end on
  web and Android (incl. `nearsdk://` deep-link callback), native deep
  link config for Android/iOS, and multi-platform CI builds
  (Android/iOS/web)

### Changed

- **RPC defaults moved to FastNear** (`https://free.rpc.fastnear.com` /
  `https://test.rpc.fastnear.com`): the `*.near.org` endpoints were
  deprecated in 2025 and are severely rate limited; they remain as
  automatic fallbacks
- `MyNearWalletAdapter.buildSignInUrl` now requires the `publicKey` being
  provisioned; `buildTransactionUrl` requires fully-formed transactions
  (publicKey/nonce/blockHash) and encodes them as base64 **Borsh**
  (comma-separated), the format MyNearWallet actually consumes
- Removed `MyNearWalletAdapter.setAccount` (restore connections through a
  persistent `KeyStore` instead) and the `ed25519:placeholder` stub
- `NearRpcClient` now supports `fallbackUrls` with transport-level
  failover (network errors, HTTP 429/5xx); JSON-RPC errors never fail over
- `TransactionResponse` and transaction status types are now exported
- Removed the `betanet` factory (network was shut down)

## 0.1.0

Initial release of near_dart SDK.

### Features

- **RPC Client**
  - Multi-network support: Mainnet, Testnet, or custom RPC
  - Methods: `status`, `block`, `viewAccount`, `viewAccessKey`, `callFunction`, `validators`, `gasPrice`
  - Type-safe responses with sealed classes

- **Type-Safe Primitives**
  - `AccountId` with validation
  - `NearToken` for handling 24-decimal precision
  - `PublicKey` with key type detection
  - `CryptoHash` for block/transaction hashes
  - `BlockReference` for querying at specific points

- **Wallet Integration**
  - `WalletAdapter` interface for wallet integrations
  - `MyNearWalletAdapter` for deep link wallet connection
  - `WalletConnectAdapterBase` for WalletConnect 2.0

- **Transaction Building**
  - All action types: `CreateAccount`, `DeployContract`, `FunctionCall`, `Transfer`, `Stake`, `AddKey`, `DeleteKey`, `DeleteAccount`
  - Multi-action transaction support
  - NEP-413 message signing

- **Platform Support**
  - iOS, Android, Web, Desktop
  - Pure Dart with no platform-specific dependencies
