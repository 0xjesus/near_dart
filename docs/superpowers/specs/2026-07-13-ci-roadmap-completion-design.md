# CI and Roadmap Completion Design

Date: 2026-07-13

## Goal

Restore reliable CI/CD, complete the remaining technical work represented by
GitHub issues #8 through #14, reconcile already-shipped work in issues #5, #6,
#9, #10, #11, and #13, and leave the repository ready for a focused adoption
and publication campaign.

## Current State

`near_dart 0.5.0` and `near_wallet_connect 0.4.0` are published. The core SDK,
typed NEP helpers, NEAR Intents clients, wallet adapters, secure key storage,
adoption guides, customizable connect UI, and basic desktop CI already exist.

Two workflows currently fail for independent reasons:

1. `windows-latest` migrated to Visual Studio 2026. The stable
   `flutter_inappwebview_windows 0.6.0` dependency still uses experimental
   coroutine headers rejected by the new compiler.
2. The OpenAPI sync workflow has a read-only `GITHUB_TOKEN`, so regeneration
   succeeds but pushing its pull-request branch returns HTTP 403.

The issue tracker is stale: several completed deliverables still appear open,
while issue #8 and issue #14 contain meaningful unfinished technical work.

## Scope

### CI/CD Reliability

- Pin the Windows example build to `windows-2022` until the stable
  `flutter_inappwebview_windows` release supports Visual Studio 2026. Keep a
  source comment linking the upstream compatibility issue.
- Grant only `contents: write` and `pull-requests: write` to the OpenAPI sync
  job.
- Add repository tests that parse workflow YAML and assert the Windows runner,
  OpenAPI permissions, required platform jobs, and aggregate gate remain
  configured.
- Add explicit dart2js and dart2wasm compile checks for the web signing entry
  point. Keep the Chrome runtime test for browser behavior.
- Add a release verification workflow that runs publish dry-runs and package
  health checks without publishing.
- Expand `docs/release.md` to match every claimed platform and automation gate.

### Structured Diagnostics and Typed Errors

- Add a core diagnostics module with:
  - `NearLogLevel`.
  - `NearLogEventType` for RPC, wallet, transaction, and Intents lifecycle
    events.
  - Immutable `NearLogEvent` metadata.
  - Optional `NearLogger` callback.
- Events contain operation names, endpoint origins, attempt counts, status,
  and durations. They never contain private keys, signatures, authorization
  headers, raw payloads, message bodies, or transaction bytes.
- Add `NearErrorCode` and `NearSdkException` with stable machine-readable
  codes, a safe developer message, optional cause, and retryability.
- Existing `RpcResult`, adapter return values, controller `error` strings, and
  constructor defaults remain source-compatible. Typed errors are additive:
  RPC errors expose a mapped code, adapters throw `NearSdkException`
  subclasses or normalized instances, and `NearWalletController` exposes
  `lastException` alongside `error`.
- Instrument `NearRpcClient`, `OneClickClient`, `OneClickExplorerClient`,
  `SolverRelayClient`, wallet adapters, and `NearWalletController` through the
  same optional callback.

### Wallet and Relay Hardening

- Automatically verify NEP-413 signatures returned by Intear and HOT when the
  response includes all required account/public-key/signature fields. A
  malformed or invalid signature fails with `signatureVerificationFailed`.
- Preserve the existing verified MyNearWallet callback path.
- Add controller-level transaction confirmation that queries `txStatus` for
  every returned hash and waits for configurable finality before reporting a
  confirmed result. Confirmation is enabled through an explicit policy so
  existing latency behavior remains available.
- Add optional post-connect access-key verification. When enabled, the
  controller checks the returned function-call key on chain before persisting
  the connected state. Missing or mismatched keys fail closed.
- Timeouts, user rejection, wrong network, missing callbacks, RPC
  unavailability, transaction failure, insufficient balance signals, and
  signature failures receive stable error codes.
- Document residual relay trust: transport availability and unsigned
  transaction-result metadata cannot be made cryptographically authoritative;
  chain confirmation is the source of truth.

## Issue Completion

- #5: verify the existing better-near-auth demonstration and documentation,
  then mark complete.
- #6: verify the existing MyNearWallet, Intear, and HOT implementations, then
  mark complete.
- #8: complete signature verification, transaction confirmation, and optional
  access-key checks described above.
- #9: verify existing NEP-141, NEP-145, and NEP-171 helpers and tests, then mark
  complete.
- #10: verify the shipped Intents clients and NEAR AI integration guidance,
  then mark complete. No mobile application may embed partner API secrets.
- #11: verify the five-minute guide, wallet recipes, and troubleshooting guide,
  then mark complete.
- #12: complete all workflow, browser, desktop, and release checks described
  above.
- #13: add concise Riverpod, Bloc/Cubit, Provider, and ChangeNotifier recipes;
  register polished existing screenshots in the package metadata; verify the
  already-shipped builders and widgets.
- #14: complete diagnostics and typed errors described above.

Closing or commenting on public issues is a separate external action. The code
will produce a precise completion matrix and suggested closing comments, but
no issue will be closed without the owner's explicit per-action approval.

## API Boundaries

Diagnostics and errors live in focused core files and are exported from
`lib/near_dart.dart`. HTTP clients consume the shared logger but do not depend
on Flutter. `near_wallet_connect` re-exports the common types and owns only
controller-specific normalization.

Security verification helpers stay in the wallet layer. Chain confirmation
uses `NearRpcClient`; adapters remain transport-specific and do not create
their own RPC clients. This keeps network policy, failover, and logging in one
place.

## Data Flow

1. An operation emits a redacted `started` event.
2. Transport or wallet code performs the request.
3. Returned authentication material is validated before state is persisted.
4. Wallet transaction hashes optionally pass through RPC finality checks.
5. The operation emits `succeeded`, `failed`, `retried`, or `finalized` with
   safe metadata.
6. Failures retain a human-readable message and expose a stable
   `NearErrorCode` for UI decisions.

## Testing

- Follow red-green-refactor for every Dart behavior change.
- Unit-test event ordering, metadata redaction, error mapping, signature
  verification, access-key validation, and multi-hash confirmation.
- Use fake HTTP/RPC transports; tests must not log or snapshot secrets.
- Parse workflow YAML in tests instead of matching raw text.
- Run root format, analysis, offline tests, tagged integration tests, package
  tests, Chrome tests, dart2js/dart2wasm compiles, publish dry-runs, and all
  locally available example builds.
- Push only after local gates pass, then watch GitHub Actions until both the
  main test workflow and OpenAPI sync workflow complete successfully.

## Publication Readiness

After technical verification, prepare channel-specific English copy for X,
LinkedIn, NEAR Telegram/Discord, Reddit, NEAR Builders groups, and the NEAR
Forum. The message leads with production Flutter adoption and NearCoffee as
the reference application, with NEAR Intents as a concrete capability rather
than the entire product identity.

No public post, issue close, package publish, or external message is performed
without explicit approval for that exact action.

## Non-Goals

- No new pub.dev release in this effort without separate approval.
- No storage or exposure of API keys in examples or mobile binaries.
- No replacement of wallet protocols or unrelated UI redesign.
- No claim that relay transport metadata is equivalent to on-chain finality.
- No migration to prerelease Flutter plugins solely to satisfy CI.
