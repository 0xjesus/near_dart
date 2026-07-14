# Troubleshooting

## Safe diagnostics and typed errors

Register one allowlisting logger with RPC clients or the wallet controller.
Do not add raw request/response objects, callback URLs, messages, nonces,
signatures, authorization values, or key material in the callback.

```dart
const allowedMetadata = <String>{
  'attempt',
  'endpointCount',
  'statusCode',
  'durationMs',
  'walletId',
  'outcome',
  'failureCode',
  'networkId',
  'transactionCount',
  'waitUntil',
};

void nearLogger(NearLogEvent event) {
  final safeMetadata = Map<String, Object?>.fromEntries(
    event.metadata.entries.where(
      (entry) => allowedMetadata.contains(entry.key),
    ),
  );
  print(
    '${event.level.name} ${event.type.name} '
    '${event.operation} $safeMetadata',
  );
}

final controller = NearWalletController(
  network: MyNearWalletNetwork.testnet,
  contractId: AccountId('app.testnet'),
  logger: nearLogger,
);
```

`controller.error` remains the compatible `String?` UI message.
`controller.lastException` is the typed `NearSdkException?`; use its stable
`code` and `retryable` values for behavior rather than matching message text.

```dart
final failure = controller.lastException;
if (failure != null) {
  switch (failure.code) {
    case NearErrorCode.wrongNetwork:
      showNetworkPicker();
    case NearErrorCode.userRejected:
      showTryAgain();
    case NearErrorCode.rpcTimeout when failure.retryable:
      scheduleRetry();
    case NearErrorCode.accessKeyNotFound ||
        NearErrorCode.accessKeyMismatch:
      await controller.disconnect();
      showReconnect();
    default:
      showError(controller.error ?? 'Wallet operation failed');
  }
}
```

## Wrong network

`NearErrorCode.wrongNetwork` means the selected wallet is unavailable on the
controller network. HOT is mainnet-only. Keep the current controller network
and wallet picker in sync; do not silently redirect a testnet operation to
mainnet.

## User rejection

`NearErrorCode.userRejected` is a completed user decision, not a transport
failure. Keep a visible retry path and do not automatically retry approval
prompts. A rejected non-sign-in callback must not clear an existing session.

## Timeout or unavailable relay/RPC

`rpcTimeout`, `rpcUnavailable`, and `rateLimited` may be retryable. Preserve
the user's context, use bounded backoff, and let the user cancel. Before
retrying a transaction submission, query known transaction hashes or account
state so an uncertain response does not cause a duplicate action.

Intear's bridge and HOT's relay can delay or drop messages. A timeout does not
prove that the wallet or chain did nothing.

## Access key missing or mismatched

With `verifyAccessKeyOnConnect: true`:

- `accessKeyNotFound` means `view_access_key` did not find the returned key for
  that account at final block finality.
- `accessKeyMismatch` means a MyNearWallet/Intear key is not a function-call
  key for the configured contract and method scope.

Fresh verification failures are not published as connected sessions. Definite
missing/mismatch failures on restore clear persisted session state; reconnect
to provision or select an authorized key. Retryable RPC failures retain the
credentials for a later `init()` attempt but leave the controller disconnected.

## MyNearWallet callback correlation failed

`walletResponseInvalid` or `missingCallback` during completion commonly means
the callback did not match the exact pending route/correlation value, was
already consumed, belongs to another operation, or was reconstructed by app
code.

- Pass the complete callback URI received from the platform unchanged.
- Start only one MyNearWallet operation at a time.
- Keep the pending key store across redirect and call `controller.init()` once
  before rendering wallet-dependent UI.
- Do not call the legacy sign-message parser for a pending secure flow; use
  `completeSignMessage` with the original request.
- Treat replayed or foreign callbacks as rejected input. Do not disable the
  correlation check to recover a session.

## Transaction confirmation failed

With `transactionFinality` enabled, `sendTransactions` can fail after the
wallet has returned an outcome:

- `walletResponseInvalid`: no usable transaction hash was returned.
- `transactionFailed` or `insufficientBalance`: RPC reported an unknown or
  failed on-chain status.
- `rpcTimeout`, `rpcUnavailable`, or `rateLimited`: confirmation itself could
  not complete.

Do not resubmit immediately. Query the returned hash, inspect the explorer, or
check application state. Successful confirmation returns the original wallet
outcome list; failed confirmation throws and leaves the typed failure in
`controller.lastException`.

## Web callback did not complete

Check that `controller.init()` ran, the entire wallet-returned URL reached the
application, and browser storage was not cleared between redirect and return.
MyNearWallet sign-message fields may be in the fragment. The SDK's web
`SharedPrefsKeyStore` is plain same-origin storage; successful XSS can read or
use it, so fix XSS/CSP issues rather than treating storage as a secret vault.

## Android opens wallet but does not return

Check the manifest scheme/host intent filter, reinstall after manifest
changes, keep `callbackScheme` consistent, and include `INTERNET` permission
in the release manifest.

## iOS opens app but account is not connected

Check `CFBundleURLTypes`, the configured callback route, and initialization
order. The pending key and correlation value must survive until
`controller.init()` processes the link.

## HOT session disappeared after upgrade

Older HOT controller sessions persisted only an account ID. Current versions
require the authentic account/public-key pair so optional on-chain verification
cannot rely on a placeholder key. `init()` clears legacy HOT state that lacks a
valid public key; ask the user to reconnect once.

## Function-call key cannot pay

Function-call keys can pay gas but cannot attach deposits. Use wallet-signed
transactions for transfers, one-yocto calls, storage deposits, or other payable
calls.

## Transaction signs but fails on chain

Check balance, function-call method scope, deposit, receiver network, contract
logs, and explorer status. `TxExecutionStatus.final_` changes how long RPC
waits; it does not turn a failed transaction into a success.

## RPC works on mobile but fails on web

Check provider CORS policy, browser extensions, corporate filtering, and
whether the configured endpoint supports browser requests. Use a
browser-compatible endpoint; never work around CORS by exposing credentials.

## Invalid account ID, public key, or signature

Account IDs use nearcore grammar. Ed25519 public keys must be canonical,
non-identity prime-order points, and signatures must have a strict `R` point
and canonical scalar. Replace invalid fixtures rather than bypassing
validation.

## NEAR Intents quote fails

NEAR Intents uses mainnet infrastructure. Confirm smallest-unit amounts,
address formats, recipient/refund types, and whether a dry quote was intended.
Do not ship partner API credentials in a client binary.
