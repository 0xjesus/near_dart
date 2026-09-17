# near_wallet_connect example

Minimal Flutter app: one `NearWalletController`, one `NearConnectButton`.

```dart
final wallet = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('guestbook.near-examples.testnet'),
  callbackScheme: 'nearsdk',
);
await wallet.init();
```

The picker lists Intear first. MyNearWallet remains available until 31 Oct 2026.

Register `nearsdk` in AndroidManifest.xml and Info.plist (already set in this
example). Then:

```bash
cd packages/near_wallet_connect/example
flutter run
```
