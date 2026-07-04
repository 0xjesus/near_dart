## 0.2.1

- Fix: a wallet callback that is not a pending sign-in (e.g. MyNearWallet's
  `/sign` transaction redirect, which appends `account_id` next to
  `transactionHashes`) no longer clears the connected session.

## 0.2.0

- **Multi-wallet support**: `NearConnectButton` now opens a wallet picker —
  MyNearWallet, **Intear** (testnet + mainnet) and **HOT** (mainnet). The new
  wallets are additional options; MyNearWallet remains fully supported until
  its announced sunset (October 31, 2026).
- **One unified API** on `NearWalletController`, whatever the wallet:
  `connect(wallet: …)`, `signer()` (local function-call key),
  `signMessage(…)` (NEP-413) and `sendTransactions(…)`.
- The connected wallet is persisted and restored across app restarts
  (`walletOption`).
- Requires `near_dart ^0.3.0`.

## 0.1.1

- Docs: add an Android demo GIF to the README.

## 0.1.0

Initial release.

- `NearWalletController`: adaptive connect (web full-page redirect / mobile
  deep links), persistent key storage, callback handling, and `signer()` for
  local contract calls after connect.
- `NearConnectButton`: drop-in connect/disconnect widget.
- `SharedPrefsKeyStore`: persistent KeyStore that survives the redirect.
- Built on near_dart ^0.2.0; verified building on web and Android.
