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
