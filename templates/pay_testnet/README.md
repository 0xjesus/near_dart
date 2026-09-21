# Pay on testnet in 15 minutes

A throwaway Flutter app that sends 0.001 NEAR on testnet with a local key.

## 1. Create the app (1 min)

From this repository:

```bash
./tool/create_near_app.sh my_near_pay
cd my_near_pay
```

That runs `flutter create`, adds `near_dart`, and drops in this screen.

## 2. Fund a throwaway testnet account (2 min)

```bash
npm install -g near-cli-rs@latest
near create-account <you>.testnet --useFaucet --networkId testnet
near account export-account <you>.testnet
```

Export only this disposable testnet account. Never paste a mainnet key.

## 3. Run and pay (the rest of the 15 min)

```bash
flutter run
```

Paste the account id and `ed25519:…` secret, tap **Send on testnet**. The
screen prints a testnet explorer URL when the transfer finalizes.

The example app in `example/` is the full demo. This template is the shortest
path that compiles and moves funds.
