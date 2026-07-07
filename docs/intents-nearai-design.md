# NEAR Intents and NEAR AI support design

Status: implemented foundation for issue #10
Date: 2026-07-06

This document proposes the first Dart/Flutter API surface for NEAR Intents
and NEAR AI support in `near_dart`. It is intentionally staged: ship the
mobile-app integration path first, then add lower-level solver tooling only
after the public API and partner requirements are clearer.

## Sources checked

- NEAR Intents overview:
  https://docs.near.org/chain-abstraction/intents/overview
- 1Click Swap quickstart:
  https://docs.near-intents.org/integration/distribution-channels/1click-api/quickstart
- 1Click Swap API overview:
  https://docs.near-intents.org/integration/distribution-channels/1click-api/about-1click-api
- 1Click supported tokens/status API reference:
  https://docs.near-intents.org/api-reference/oneclick/get-supported-tokens
  and
  https://docs.near-intents.org/api-reference/oneclick/check-swap-execution-status
- Message Bus JSON-RPC API:
  https://docs.near-intents.org/integration/market-makers/message-bus/rpc
- Verifier contract intro and deposits:
  https://docs.near-intents.org/integration/verifier-contract/introduction
  and
  https://docs.near-intents.org/integration/verifier-contract/deposits-and-withdrawals/deposits
- NEAR AI Cloud docs:
  https://docs.near.ai/
- NEAR AI OpenAI compatibility:
  https://docs.near.ai/cloud/guides/openai-compatibility/

## Key findings

- NEAR Intents is the ecosystem's user/agent outcome layer: a user or agent
  states a desired outcome, solvers compete, and accepted intents settle via
  the Verifier contract on NEAR.
- There is no NEAR Intents testnet deployment. Integration tests must mock the
  HTTP API by default, and any live tests must use mainnet with tiny amounts
  and explicit opt-in.
- The docs recommend 1Click Swap for application integrations. It abstracts
  quote creation, deposit address handling, solver coordination, retries,
  refunds, and status polling.
- Message Bus JSON-RPC is useful for solvers/market makers, not the first
  mobile app surface. It requires partner authentication and the docs point
  ordinary swap integrators back to 1Click.
- The Verifier contract is deployed at `intents.near`. It does not accept
  native NEAR directly; NEAR must be wrapped to wNEAR before deposit.
- Signed intent execution is relevant when funds are already inside Intents
  balances (`depositType: INTENTS` or `CONFIDENTIAL_INTENTS`). The user signs
  the exact API-generated payload off-chain, then the app submits the signed
  payload.
- NEAR AI Cloud is beta and exposes OpenAI-compatible inference endpoints.
  That is a docs/example fit before it is a core SDK dependency, especially
  because mobile apps must not hard-code shared API keys.

## Recommended package shape

The SDK now has a `src/intents/` module:

```text
lib/src/intents/
  one_click_client.dart
  one_click_models.dart
  one_click_auth.dart
  intent_signing.dart
  solver_relay_client.dart
  solver_relay_models.dart
```

It is exported from `near_dart.dart`. The user-facing guide lives in
`docs/intents.md`.

Avoid adding a high-level NEAR AI client to `near_dart` in the same release.
Instead, publish a guide/example that uses the OpenAI-compatible API through
`package:http` or the user's preferred OpenAI client. Revisit a typed NEAR AI
package after the agent APIs stabilize.

## MVP: OneClickClient

The first deliverable should be a REST client around the 1Click API:

```dart
final intents = OneClickClient(
  auth: OneClickAuth.xApiKey(apiKey),
);

final tokens = await intents.tokens();
final quote = await intents.quote(
  OneClickQuoteRequest(
    dry: true,
    originAsset: 'nep141:wrap.near',
    destinationAsset: 'nep141:eth-0xdac17f958d2ee523a2206206994597c13d831ec7.omft.near',
    amount: '100000000000000000000000',
    refundTo: 'alice.near',
    recipient: '0x...',
  ),
);

final status = await intents.status(
  depositAddress: quote.depositAddress,
  depositMemo: quote.depositMemo,
);
```

Suggested public API:

```dart
class OneClickClient {
  OneClickClient({
    Uri? baseUri,
    OneClickAuth? auth,
    http.Client? httpClient,
  });

  Future<List<OneClickToken>> tokens();

  Future<OneClickQuote> quote(OneClickQuoteRequest request);

  Future<void> submitDeposit({
    required String depositAddress,
    required String txHash,
  });

  Future<OneClickStatus> status({
    required String depositAddress,
    String? depositMemo,
  });

  Future<GeneratedIntent> generateIntent({
    required String depositAddress,
    required String signerId,
    required IntentSigningStandard standard,
  });

  Future<SubmitIntentResponse> submitIntent({
    required String type,
    required SignedMultiPayload signedData,
  });
}
```

Model notes:

- `OneClickToken`: `assetId`, `symbol`, `decimals`, `blockchain`,
  `contractAddress`, `price`, `priceUpdatedAt`.
- `OneClickQuoteRequest`: keep the raw 1Click field names where possible
  (`originAsset`, `destinationAsset`, `amount`, `depositType`, `recipient`,
  `recipientType`, `refundTo`, `refundType`, `slippageTolerance`, `deadline`,
  `dry`) so Dart docs match upstream docs and examples.
- `OneClickQuote`: preserve unknown fields in `raw` until the API shape is
  stable; typed getters for `depositAddress`, `depositMemo`, `amountIn`,
  `amountOut`, `deadline`, and fee fields can be added incrementally.
- `OneClickStatusCode`: include at least `pendingDeposit`, `knownDepositTx`,
  `processing`, `success`, `incompleteDeposit`, `refunded`, `failed`, plus an
  `unknown(String raw)` escape hatch.
- `OneClickAuth`: support both `X-API-Key` and bearer JWT because the docs use
  both across pages/endpoints and mention legacy JWT auth for signed intent
  endpoints.

## Signed intent flow

Do not invent a signing format. The 1Click API generates the unsigned intent
payload; the wallet signs that exact payload; the app submits the signature.

The SDK already has NEP-413 primitives and wallet message signing:

- `NearWalletController.signMessage(...)` for Intear and HOT.
- `MyNearWalletAdapter.buildSignMessageUrl(...)` /
  `completeSignMessage(...)` for redirect-wallet NEP-413.
- `verifyNep413Signature(...)` for local verification.

The new `intent_signing.dart` should provide glue types, not a parallel
cryptography stack:

```dart
enum IntentSigningStandard {
  nep413,
  erc191,
  rawEd25519,
  webauthn,
  tonConnect,
  sep53,
  tip191,
}

class GeneratedIntent {
  final String depositAddress;
  final IntentSigningStandard standard;
  final Map<String, dynamic> intent;
  final Map<String, dynamic> raw;
}

class SignedMultiPayload {
  final IntentSigningStandard standard;
  final Map<String, dynamic> payload;
  final String publicKey;
  final String signature;
}
```

For the first release, only `nep413` should have helper constructors because
`near_dart` already owns NEAR signing. Other standards can remain parsed data
for applications that integrate EVM/TON/etc. wallets themselves.

## Non-goals for the first release

- No solver/market-maker WebSocket implementation.
- No automatic custody or private-key import.
- No automatic native NEAR deposit into `intents.near`; apps must wrap NEAR
  first or use an origin-chain deposit flow provided by 1Click.
- No default live mainnet tests.
- No in-SDK NEAR AI account/API-key management.

## Security and UX rules

- Any API result that claims settlement should be treated as a remote service
  result. If a NEAR transaction hash is returned, confirm it through
  `NearRpcClient.tx(...)` before showing high-value success UX.
- Keep API keys out of published mobile binaries. Use a backend, user-scoped
  token, or partner flow. The SDK can accept auth headers, but examples should
  default to unauthenticated/dry flows.
- Preserve and submit exact payloads returned by `generate-intent`. Re-encoding
  or normalizing JSON can break signatures.
- Clearly label that NEAR Intents has no testnet. Demos should use dry quotes
  or tiny mainnet amounts with explicit user approval.
- Never ask an agent to operate a wallet or approve an intent. The user signs
  in their own wallet UI.

## NEAR AI exploration

The near-term deliverable should be documentation and an example rather than
core SDK code:

1. Add `docs/near-ai.md` showing OpenAI-compatible configuration against
   NEAR AI Cloud.
2. Show a mobile-safe architecture: Flutter app -> developer backend ->
   NEAR AI, or Flutter app with a user-provided key for prototypes only.
3. Show how an agent can call the new `OneClickClient` API server-side to
   request a dry quote, then return a human-readable proposal for the user to
   approve in-wallet.
4. Defer autonomous signing/spending. This SDK should make the wallet approval
   boundary explicit.

## Implementation plan

1. Add `OneClickClient` and models with mocked HTTP tests for tokens, quote,
   deposit submit, status, generate intent, and submit intent.
2. Add docs examples for dry quotes and status polling.
3. Add NEP-413 signed intent helper tests using existing NEP-413 vectors where
   possible.
4. Add an example app tab or small sample that fetches supported tokens and
   performs a dry quote; keep real swaps behind clear manual steps.
5. Add `docs/near-ai.md` with OpenAI-compatible NEAR AI usage and agent safety
   guidance.
6. Only after this, evaluate a lower-level `SolverRelayClient` for
   `quote`, `publish_intent`, and `get_status` JSON-RPC for registered
   market makers.
