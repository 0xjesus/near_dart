## 0.3.0

Security release addressing an external audit (2026-07-05).

**Breaking / behavior change**
- **Secure key storage by default**: on Android/iOS/macOS/Windows/Linux the
  controller now stores keys in `SecureKeyStore` (flutter_secure_storage:
  Keystore / Keychain / DPAPI / libsecret). Existing sessions in plain
  shared preferences are migrated automatically on first `init()`.
- `SharedPrefsKeyStore` remains the default only on web and is documented
  as plain-storage (demo/web) — pass it explicitly if you really want it.

**Other**
- New dependency: `flutter_secure_storage`.
- Explicit `platforms:` declarations; README updated with the secure
  storage model. Requires `near_dart ^0.4.0`.

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
