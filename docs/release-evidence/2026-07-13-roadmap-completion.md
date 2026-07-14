# Roadmap Completion Evidence

This document records the technical completion of issues #5, #6, and #8-#14.
It is an evidence and handoff document, not a package release announcement.

## Status Snapshot

- Technical commit: `73451f71a47d40084761a173cfd04928da03e3d5`
- Delivery: pushed to `origin/main`
- Package publication: not performed
- Current published package: [`near_dart 0.5.0`](https://pub.dev/packages/near_dart), which predates this roadmap completion
- Issue comments or closures: not performed
- Social or community publication: not performed
- Automated OpenAPI update: PR [#15](https://github.com/0xjesus/near_dart/pull/15) created for owner review; not merged

## Verification

### Local

The following checks passed on the technical commit:

| Check | Result |
|---|---|
| `dart analyze --fatal-infos lib test` | Clean |
| `dart test --exclude-tags integration -r compact` | 639 passed |
| `flutter analyze lib test` in `packages/near_wallet_connect` | Clean |
| `flutter test` in `packages/near_wallet_connect` | 65 passed |
| SDK Chrome tests with JavaScript | 27 passed |
| SDK Chrome tests with Dart2Wasm | 27 passed |
| Wallet redirect/restore browser test with JavaScript | 1 passed |
| Wallet redirect/restore browser test with Wasm | 1 passed |
| Flutter example web build | Passed |
| Flutter example web Wasm build | Passed |
| `dart pub publish --dry-run` | 0 warnings; no publication performed |

The wallet package was resolved against the local core checkout only for local
verification. The temporary dependency override was removed afterward and was
not committed.

The hosted run below passed the real testnet transaction at the exact technical
commit, so the live-chain evidence does not depend on the earlier local faucet
run.

### GitHub Actions

| Workflow | Head | Result | Evidence |
|---|---|---|---|
| Tests, manual full matrix | `73451f7` | Success | [Run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449) |
| Tests, push | `73451f7` | Success | [Run 29308145820](https://github.com/0xjesus/near_dart/actions/runs/29308145820) |
| Sync NEAR OpenAPI, retry | `0581985` | Success | [Run 29305326357](https://github.com/0xjesus/near_dart/actions/runs/29305326357) |

The manual Tests run covered analysis, core and wallet tests, generated client
tests, Android/iOS/web/macOS/Windows/Linux builds, SDK and wallet browser tests
in JavaScript and Wasm, dart2js and dart2wasm compilation, offline end-to-end
tests, mainnet reads, and a real testnet `send_tx`.

The first OpenAPI sync attempt, [run 29305286794](https://github.com/0xjesus/near_dart/actions/runs/29305286794),
generated and analyzed the client successfully, but GitHub blocked the final
PR creation step. Repository Actions permissions were updated
to allow workflows to create pull requests while retaining read-only default
workflow permissions. The retry succeeded and created PR #15.

GitHub also reported a non-blocking Node.js runtime migration annotation for
`actions/checkout@v4` and `peter-evans/create-pull-request@v6`. It did not affect
these successful runs and can be handled as workflow maintenance.

## Issue Evidence

Every suggested closing comment below is a draft. No GitHub issue was mutated.

### #5: better-near-auth session demo

Issue: [#5](https://github.com/0xjesus/near_dart/issues/5)

Implementation:

- `example/lib/main.dart`: interactive Sign in with NEAR flow against a configurable better-near-auth API.
- `lib/src/wallet/nep413.dart`: NEP-413 payload creation, signing, nonce generation, and verification.
- `docs/wallet-recipes.md`: authentication recipe and production verification guidance.

Tests:

- `test/unit/nep413_test.dart`
- Hosted full matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

The configurable external better-near-auth HTTP service is not called by CI.
The example demonstrates the client side of the flow; automated coverage proves
the SDK's NEP-413 payload and cryptographic behavior.

Suggested closing comment:

> Completed on main. The Flutter example demonstrates the client side of a configurable better-near-auth session flow using NEP-413. The SDK provides payload signing and verification, while the wallet recipe documents backend verification and trust checks. CI covers NEP-413 locally and does not call an external better-near-auth deployment. Verification: Tests run 29308148449.

### #6: MyNearWallet, Intear, and HOT adapters

Issue: [#6](https://github.com/0xjesus/near_dart/issues/6)

Implementation:

- `lib/src/wallet/adapters/my_near_wallet_adapter.dart`
- `lib/src/wallet/adapters/intear_wallet_adapter.dart`
- `lib/src/wallet/adapters/hot_wallet_adapter.dart`
- `packages/near_wallet_connect/lib/src/near_wallet_controller.dart`
- `docs/wallet-recipes.md`

Tests:

- `test/e2e/wallet_url_flow_test.dart`
- `test/unit/intear_wallet_adapter_test.dart`
- `test/unit/hot_wallet_adapter_test.dart`
- `test/unit/wallet/callback_security_test.dart`
- `packages/near_wallet_connect/test/near_connect_button_test.dart`
- Hosted full matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

Suggested closing comment:

> Completed on main. near_dart now provides MyNearWallet, Intear, and HOT adapters, including network constraints, callback handling, session restoration, cancellation, and controller integration. Wallet-specific setup and trust assumptions are documented and covered by unit, end-to-end, and Flutter controller tests. Verification: Tests run 29308148449.

### #8: relay and wallet trust hardening

Issue: [#8](https://github.com/0xjesus/near_dart/issues/8)

Implementation:

- `lib/src/wallet/adapters/hot_wallet_adapter.dart`: automatic wallet-produced NEP-413 signature verification.
- `lib/src/wallet/adapters/intear_wallet_adapter.dart`: signed-request binding and automatic NEP-413 response verification.
- `packages/near_wallet_connect/lib/src/wallet_security.dart`: optional on-chain access-key verification and transaction finality confirmation.
- `packages/near_wallet_connect/lib/src/near_wallet_controller.dart`: fail-closed verification before session publication and optional confirmation after submission.
- `docs/security.md`: residual relay trust and production configuration.

Tests:

- `test/unit/hot_wallet_adapter_test.dart`
- `test/unit/intear_wallet_adapter_test.dart`
- `test/unit/wallet/callback_security_test.dart`
- `packages/near_wallet_connect/test/wallet_security_test.dart`
- `packages/near_wallet_connect/test/near_connect_button_test.dart`
- Hosted full matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

Suggested closing comment:

> Completed on main. Intear and HOT now verify wallet-produced NEP-413 signatures where available. The Flutter controller supports opt-in on-chain access-key verification and transaction-finality confirmation, with fail-closed session publication and documented residual relay trust. Verification: Tests run 29308148449.

### #9: typed NEP helpers

Issue: [#9](https://github.com/0xjesus/near_dart/issues/9)

Implementation:

- `lib/src/nep/nep141.dart`: FT metadata, balance, transfer, and transfer-call helpers.
- `lib/src/nep/nep145.dart`: storage bounds, balance, deposit, and unregister helpers.
- `lib/src/nep/nep171.dart`: NFT metadata, token queries, transfer, and transfer-call helpers.
- `lib/src/client/near_rpc_client.dart`: public `viewFunction<T>()` with typed JSON decoding and typed parse failures.
- `lib/src/types/near_gas.dart`: exact TGas conversion and public default function-call gas.
- `lib/src/account/account.dart`: typed contract-call surfaces with explicit gas overrides.
- `lib/src/types/primitives.dart`: exact amount parsing, formatting, and one-yocto utilities.

Tests:

- `test/unit/nep/nep_helpers_test.dart`
- `test/unit/types/near_gas_test.dart`
- `test/integration/testnet/rpc_contract_test.dart`
- `test/integration/mainnet/mainnet_contracts_test.dart`
- Hosted full matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

Suggested closing comment:

> Completed on main. The SDK now includes typed NEP-141, NEP-145, and NEP-171 query and transaction helpers, `viewFunction<T>()`, public exact gas utilities, explicit gas overrides, and exact one-yocto handling. Dedicated mock tests and live contract reads pass in CI. Verification: Tests run 29308148449.

### #10: NEAR Intents and NEAR AI

Issue: [#10](https://github.com/0xjesus/near_dart/issues/10)

Implementation:

- `lib/src/intents/one_click_client.dart`: 1Click quote, deposit submission, and status APIs.
- `lib/src/intents/one_click_quote_builder.dart`: validated quote construction.
- `lib/src/intents/one_click_swap_controller.dart`: application lifecycle and progress state.
- `lib/src/intents/one_click_assets.dart` and `one_click_explorer_client.dart`: asset discovery and explorer history.
- `lib/src/intents/solver_relay_client.dart`: solver relay publish/status flow.
- `lib/src/intents/intent_signing.dart`: generated payload parsing, NEP-413 conversion, and assembly of wallet-signed submissions.
- `docs/intents.md`: production integration guide.
- `docs/near-ai.md`: backend-mediated NEAR AI architecture without shipping API secrets in a Flutter client.
- `example/lib/main.dart` and `screenshots/intents-quote.png`: interactive reference flow and screenshot registered in package metadata for the next release.

Tests:

- `test/unit/intents/one_click_client_test.dart`
- `test/unit/intents/one_click_quote_builder_test.dart`
- `test/unit/intents/one_click_swap_controller_test.dart`
- `test/unit/intents/one_click_assets_test.dart`
- `test/unit/intents/one_click_explorer_client_test.dart`
- `test/unit/intents/solver_relay_client_test.dart`
- `test/unit/intents/endpoint_port_validation_test.dart`
- Hosted web and full matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

The Intents tests use controlled HTTP fixtures. No live swap settlement or
production solver availability is claimed by this evidence.

Suggested closing comment:

> Completed on main. near_dart now provides typed Dart clients for 1Click asset discovery, quote/deposit/status, explorer history, and solver relay requests, plus generated NEP-413 payload conversion, wallet-signed submission assembly, progress state, diagnostics, validation, and bounded timeouts. The example demonstrates a dry quote path; CI uses controlled fixtures and does not claim a live swap settlement. NEAR AI guidance keeps service secrets behind a backend boundary. Verification: Tests run 29308148449.

### #11: onboarding and wallet guides

Issue: [#11](https://github.com/0xjesus/near_dart/issues/11)

Implementation:

- `docs/5-minute-guide.md`: account, balance, view call, signed transaction, and explorer flow.
- `docs/wallet-recipes.md`: MyNearWallet, Intear, HOT, callback, Android, iOS, and web recipes.
- `docs/troubleshooting.md`: callback, deep-link, CORS, network, RPC, and transaction diagnostics.
- `example/lib/main.dart`: runnable reference application.

Tests:

- `test/e2e/send_transaction_e2e_test.dart`
- `test/e2e/wallet_url_flow_test.dart`
- `test/integration/testnet/rpc_contract_test.dart`
- Hosted real transaction and platform matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

Suggested closing comment:

> Completed on main. The repository now has a faucet-to-explorer five-minute guide, wallet-specific platform/callback/failure recipes, and a troubleshooting guide covering callbacks, deep links, CORS, networks, RPC failures, and transaction errors. CI validates a real testnet transaction. Verification: Tests run 29308148449.

### #12: platform CI and release automation

Issue: [#12](https://github.com/0xjesus/near_dart/issues/12)

Implementation:

- `.github/workflows/test.yml`: required analysis, tests, browser checks, integration, and six-platform builds.
- `.github/workflows/release-check.yml`: package dry-runs and release validation without publication.
- `.github/workflows/sync-openapi.yml`: generated client synchronization and owner-reviewed PR creation.
- `test/workflows/workflow_contract_test.dart`: workflow contract regression tests.
- `tool/web_compile_smoke.dart`: dart2js and dart2wasm compile surface.
- `docs/release.md`: release order and checklist.

Tests:

- `test/platform/web_test.dart`
- `test/platform/web_signing_test.dart`
- `packages/near_wallet_connect/test/web_wallet_flow_test.dart`
- `test/workflows/workflow_contract_test.dart`
- Full CI: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)
- Push CI: [Tests run 29308145820](https://github.com/0xjesus/near_dart/actions/runs/29308145820)
- OpenAPI sync: [Run 29305326357](https://github.com/0xjesus/near_dart/actions/runs/29305326357)

Suggested closing comment:

> Completed on main. CI now analyzes and tests all packages, runs SDK and real-localStorage wallet browser flows in JavaScript and Wasm, compiles the web smoke surface with dart2js and dart2wasm, builds Android/iOS/web/macOS/Windows/Linux examples, and verifies real-chain flows. Release dry-runs and OpenAPI synchronization are automated without publishing or auto-merging. Verification: Tests run 29308148449 and sync run 29305326357.

### #13: customizable Flutter wallet UX

Issue: [#13](https://github.com/0xjesus/near_dart/issues/13)

Implementation:

- `packages/near_wallet_connect/lib/src/near_connect_button.dart`: connect, picker, connected, and error builders plus compact/disabled modes; the connect builder receives controller busy state for custom loading UI.
- `packages/near_wallet_connect/lib/src/near_connect_button.dart`: `NearAccountBadge`, `NearBalanceText`, and `NearTransactionStatusView` widgets.
- `packages/near_wallet_connect/lib/src/near_wallet_controller.dart`: lifecycle, cancellation, retry, restore, and transaction progress states.
- `docs/flutter-architectures.md`: Riverpod, Bloc/Cubit, Provider, and ChangeNotifier recipes.
- `packages/near_wallet_connect/screenshots/wallet-connect.png` and `screenshots/intents-quote.png`: screenshots registered in package metadata for the next release.

Tests:

- `packages/near_wallet_connect/test/near_connect_button_test.dart`
- `packages/near_wallet_connect/test/wallet_security_test.dart`
- Hosted Flutter analysis, tests, and builds: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

Suggested closing comment:

> Completed on main. NearConnectButton supports custom connect/loading, wallet picker, connected, and error rendering, along with compact and disabled modes. The package includes account, balance, and transaction-status widgets, architecture recipes, and screenshots registered in package metadata for the next release. Controller and widget behavior is covered by 65 Flutter tests. Verification: Tests run 29308148449.

### #14: diagnostics and typed errors

Issue: [#14](https://github.com/0xjesus/near_dart/issues/14)

Implementation:

- `lib/src/diagnostics/near_diagnostics.dart`: structured, redacted RPC, wallet, intent, and transaction lifecycle events.
- `lib/src/diagnostics/near_errors.dart`: typed error categories and actionable messages.
- `lib/src/diagnostics/diagnostic_endpoint_sanitizer.dart`: SDK-owned endpoint redaction.
- RPC, wallet adapters, Intents clients, and `NearWalletController`: diagnostics integration without direct printing.

Tests:

- `test/unit/diagnostics/near_diagnostics_test.dart`
- `test/unit/diagnostics/near_errors_test.dart`
- `test/unit/client/diagnostic_endpoint_sanitizer_test.dart`
- `test/unit/client/rpc_logging_test.dart`
- `test/unit/client/rpc_timeout_test.dart`
- `packages/near_wallet_connect/test/near_connect_button_test.dart`
- Hosted full matrix: [Tests run 29308148449](https://github.com/0xjesus/near_dart/actions/runs/29308148449)

Suggested closing comment:

> Completed on main. The SDK exposes optional structured diagnostics across RPC, wallet, Intents, and transaction lifecycles, with sensitive endpoint data redacted by default. Common failures use typed categories and actionable messages, including timeout, rejection, callback, network, balance, and transaction states. Verification: Tests run 29308148449.

## NearCoffee Status

NearCoffee is the reference product scenario used by the tutorial, not evidence
of an already deployed Intents integration. Its older repository still needs to
be upgraded to the approved package versions and wired to the new typed Intents
clients. That app-level work belongs after the package release decision and must
be verified in the NearCoffee repository on its own CI and target devices.

## Package Publication Handoff

No package has been published from this work. A compatible release must use
this order:

1. Choose and approve the new `near_dart` version, changelog, and release tag.
2. Run the root release checklist and `dart pub publish --dry-run` without local overrides.
3. Publish `near_dart` only after explicit owner approval.
4. Wait until pub.dev resolves the new core version.
5. Update `near_wallet_connect` to that published core constraint.
6. Resolve `near_wallet_connect` without a path override and repeat analysis, tests, builds, and publish dry-run.
7. Publish `near_wallet_connect` only after a separate explicit owner approval.
8. Update and verify NearCoffee against the published package versions.

The generated `near_jsonrpc_client` change in PR #15 should be reviewed on its
own merits. It is not required to merge or publish the roadmap completion.
