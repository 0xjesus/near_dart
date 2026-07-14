# Security model

This page describes what `near_dart` and `near_wallet_connect` verify, what
their optional on-chain checks add, and which decisions remain the
application's responsibility.

## Keys and storage

| Key material | Created by | Purpose | Storage |
|---|---|---|---|
| MyNearWallet function-call key | SDK at connect time | Local gas-only calls to the configured contract | Application `KeyStore` |
| Intear app/function-call key | SDK at connect time | Authenticate bridge requests and, when approved, local contract calls | Application `KeyStore` |
| Wallet full-access key | Wallet | Payments and wallet-produced signatures | Never handled by the SDK |

Function-call and Intear app keys are still secrets. Scope function-call keys
to one contract and explicit methods, and do not put key material in logs,
crash reports, analytics, or URLs.

- `SecureKeyStore` is the default on Android, iOS, macOS, Windows, and Linux.
  It uses `flutter_secure_storage` and migrates older plain-preferences keys on
  the first `NearWalletController.init()`.
- `SharedPrefsKeyStore` is the web default and is plain browser storage. Any
  same-origin JavaScript that runs after an XSS compromise can read or use the
  session. CSP, dependency hygiene, output encoding, short-lived sessions,
  narrow method scopes, and explicit disconnect are application controls; the
  SDK cannot make a browser-held key safe from same-origin script.
- A custom `KeyStore` can provide a different custody model.

## Strict Ed25519 verification

`PublicKey` rejects Ed25519 encodings that are non-canonical, the identity, or
outside the prime-order subgroup. `verifySignature` additionally requires a
64-byte signature, a strict prime-order `R` point, and a canonical scalar
before invoking Ed25519 verification. `verifyNep413Signature` applies that
verification to `sha256(borsh(NEP-413 payload))`.

A successful local verification proves that the holder of the private key for
the supplied public key signed the exact bytes checked by the application. For
NEP-413, those bytes include the message, nonce, recipient, and callback URL
when present. It does **not** prove that the public key is currently authorized
for the claimed account, that the nonce is fresh, that the recipient is your
service, that the user intended a separate transaction, or that a transaction
was included on chain. Check those properties separately.

## MyNearWallet callbacks

Secure MyNearWallet completion APIs bind each pending operation to its
configured callback route and a per-flow correlation value added to the
callback URL. A callback must contain that value exactly once. Fixed query and
fragment parameters in the configured URL must also match. Only one flow may
be pending, accepted callbacks are consumed once, and a replay cannot consume
a later flow.

- `completeSignIn` accepts only the correlated success or failure route. A
  successful callback must return the exact SDK-generated pending public key
  before that key is promoted to the account session.
- `handleTransactionCallback` requires the pending correlated transaction
  flow and canonical transaction hashes. Callback hashes and the placeholder
  outcomes built from them are not signed wallet assertions.
- `completeSignMessage` requires the original pending request, matching
  `state`, exact correlated route, and a valid Ed25519 signature over the exact
  NEP-413 payload requested. Use this completion API for pending sign-message
  flows; `handleSignMessageCallback` is only a legacy parser when no secure
  sign-message flow is pending.

Pass the wallet-returned callback URI to the matching completion method
unchanged. Correlation and one-shot handling prevent callback mix-up and
replay inside the current pending flow; they do not establish on-chain account
ownership. For authentication, also enforce nonce freshness and recipient on
your server and verify the returned key against the claimed account.

## Intear and HOT signatures

The SDK verifies wallet-produced NEP-413 signatures before returning them:

- Intear verifies a requested `messageToSign` during connect and every
  `signMessage` result. It also requires the signed account to equal the
  requested/connected account.
- HOT verifies every `signMessage` result against the payload supplied by the
  application.

Intear requests are signed by the SDK's app key so the wallet can authenticate
the application request. These checks authenticate the specified NEP-413
signatures, not every WebSocket or HTTP relay response. In particular, connect
account metadata and transaction-result metadata are not wallet-signed by
these adapters.

The Intear bridge and HOT relay remain availability dependencies: they can
drop, delay, replay, substitute, or withhold unsigned transport metadata. HOT
request IDs bind polling to an encoded request, and Intear uses a per-request
WebSocket session, but neither property turns all returned payloads into
cryptographic wallet statements.

## Optional on-chain policy

`NearWalletSecurityPolicy` preserves existing behavior by default: both
options are off.

```dart
final controller = NearWalletController(
  network: MyNearWalletNetwork.mainnet,
  contractId: AccountId('app.near'),
  methodNames: const ['submit'],
  securityPolicy: const NearWalletSecurityPolicy(
    verifyAccessKeyOnConnect: true,
    transactionFinality: TxExecutionStatus.final_,
  ),
);
```

### Access-key verification

With `verifyAccessKeyOnConnect: true`, fresh MyNearWallet callbacks, fresh
Intear/HOT connections, and restored sessions call `view_access_key` at final
block finality before the controller publishes the account.

- MyNearWallet and Intear keys must exist and have function-call permission
  for `contractId` covering every configured `methodNames` entry. An empty
  on-chain method list covers all methods; a restricted on-chain list does not
  satisfy an empty requested list.
- HOT keys must exist for the account, but no function-call scope is required
  because HOT does not provide the controller's local `signer()` key.
- A definite missing/mismatched restored key clears the persisted session. A
  retryable RPC failure leaves credentials available for a later retry but
  does not publish a connected account.

This option verifies the returned key against current chain state. It does not
authenticate unrelated relay fields or prove user intent for a transaction.

### Transaction confirmation

With a non-null `transactionFinality`, `NearWalletController.sendTransactions`
extracts every distinct hash from Intear/HOT outcomes, calls `txStatus` with
the connected sender and requested `waitUntil`, and rejects missing hashes,
RPC failures, unknown status, and on-chain failure. After successful
confirmation it returns the original wallet outcome list unchanged. With the
default `null`, no confirmation RPC is made and the adapter outcomes are
returned directly.

Confirmation proves that each returned hash reached the requested status and
reports its on-chain success or failure. Because relay transaction metadata is
unsigned, a hash could still refer to a different transaction. For high-value
flows, compare the on-chain signer, receiver, actions, amounts, and other
expected fields with the request before treating the operation as authorized.

## Diagnostics

`NearLogger` receives immutable structured events. SDK producers omit raw
payloads and redact metadata values whose keys indicate authorization,
tokens, secrets, private keys, signatures, nonces, message bodies, or signed
transactions. Logger exceptions are ignored so telemetry cannot change SDK
behavior.

Treat redaction as defense in depth. Logger callbacks must use an explicit
allowlist and must not attach request objects, callback URIs, messages,
signatures, credentials, or key material. See
[Troubleshooting](troubleshooting.md#safe-diagnostics-and-typed-errors) for a
minimal example.

## Production checklist

1. Use explicit function-call `methodNames` and a dedicated contract.
2. Enable access-key verification where an RPC dependency at connect/restore
   time fits the product's availability requirements.
3. Enable transaction finality and compare on-chain transaction contents for
   valuable operations.
4. For sign-in, verify the signature, account key, nonce freshness, recipient,
   and your own session/challenge lifetime server-side.
5. Harden browser applications against XSS and treat web sessions as lower
   trust.
6. Report vulnerabilities privately through GitHub security advisories.
