## 0.1.0

Initial release.

- `NearWalletController`: adaptive connect (web full-page redirect / mobile
  deep links), persistent key storage, callback handling, and `signer()` for
  local contract calls after connect.
- `NearConnectButton`: drop-in connect/disconnect widget.
- `SharedPrefsKeyStore`: persistent KeyStore that survives the redirect.
- Built on near_dart ^0.2.0; verified building on web and Android.
