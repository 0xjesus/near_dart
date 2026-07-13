# CI and Roadmap Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore green CI/CD and finish the remaining technical deliverables in GitHub issues #8 through #14 without breaking the published `near_dart 0.5.0` and `near_wallet_connect 0.4.0` APIs.

**Architecture:** Add shared, pure-Dart diagnostics and error types to the core package, then consume them from RPC, Intents, wallet adapters, and the Flutter controller. Keep relay transports separate from chain verification by adding an injectable wallet-security service in `near_wallet_connect`. Treat workflow configuration as tested code and keep publication assets/docs independent from runtime behavior.

**Tech Stack:** Dart 3.9+, Flutter stable, `package:http`, `package:test`, `flutter_test`, GitHub Actions, `package:yaml`, NEAR JSON-RPC, NEP-413.

## Global Constraints

- Existing public constructors and return values remain source-compatible; every new option defaults to current behavior.
- Logs never include private keys, signatures, authorization headers, nonces, raw payloads, message bodies, signed transaction bytes, or API credentials.
- `verifyAccessKeyOnConnect` and transaction confirmation are explicit opt-ins.
- No prerelease Flutter dependency is introduced to repair Windows CI.
- No pub.dev publish, public issue mutation, or external post occurs without separate explicit approval.
- Every behavior change follows red-green-refactor.

---

## File Structure

- Create `lib/src/diagnostics/near_diagnostics.dart`: redacted structured event API.
- Create `lib/src/diagnostics/near_errors.dart`: stable error codes, exception type, and normalization.
- Modify `lib/src/client/near_rpc_client.dart`: RPC diagnostics and configurable `txStatus` finality.
- Modify `lib/src/types/rpc_result.dart`: map `RpcError` to a stable SDK error code.
- Modify `lib/src/intents/{one_click_client,one_click_explorer_client,solver_relay_client}.dart`: shared errors and events.
- Modify `lib/src/wallet/adapters/{my_near_wallet_adapter,intear_wallet_adapter,hot_wallet_adapter}.dart`: wallet events and typed failures; verify Intear/HOT signatures.
- Create `packages/near_wallet_connect/lib/src/wallet_security.dart`: access-key and transaction confirmation policy/service.
- Modify `packages/near_wallet_connect/lib/src/near_wallet_controller.dart`: typed controller error state, security policy, and logging.
- Create `test/unit/diagnostics/{near_diagnostics_test,near_errors_test}.dart`: redaction/error mapping tests.
- Create `test/unit/client/rpc_logging_test.dart`: RPC event ordering and safe metadata tests.
- Extend existing Intents and wallet adapter tests for diagnostics and signature rejection.
- Create `packages/near_wallet_connect/test/wallet_security_test.dart`: access-key and transaction finality tests.
- Extend `packages/near_wallet_connect/test/near_connect_button_test.dart`: controller typed error compatibility.
- Create `test/workflows/workflow_contract_test.dart`: parsed workflow contract tests.
- Create `tool/web_compile_smoke.dart`: dart2js/dart2wasm compile entry point.
- Create `.github/workflows/release-check.yml`: non-publishing release dry-run gate.
- Modify `.github/workflows/{test,sync-openapi}.yml`: Windows compatibility, web compilers, and least-privilege sync.
- Create `docs/flutter-architectures.md`: Riverpod, Bloc/Cubit, Provider, and ChangeNotifier recipes.
- Create package screenshot assets from existing product demos and register them in package pubspecs.
- Modify release/security/troubleshooting/readme docs to describe the completed behavior.

---

### Task 1: Lock Down Workflow Contracts and Repair CI/CD

**Files:**
- Modify: `pubspec.yaml`
- Create: `test/workflows/workflow_contract_test.dart`
- Create: `tool/web_compile_smoke.dart`
- Modify: `.github/workflows/test.yml`
- Modify: `.github/workflows/sync-openapi.yml`
- Create: `.github/workflows/release-check.yml`
- Modify: `docs/release.md`

**Interfaces:**
- Consumes: committed workflow YAML.
- Produces: deterministic tests for required jobs/permissions and a web compilation entry point.

- [ ] **Step 1: Add the YAML test dependency and write the failing workflow contract test**

Add `yaml: ^3.1.3` under root `dev_dependencies`, then create a test that loads YAML maps and asserts:

```dart
import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Map<Object?, Object?> workflow(String path) {
  final value = loadYaml(File(path).readAsStringSync());
  return (value as YamlMap).cast<Object?, Object?>();
}

void main() {
  test('Windows uses the VS 2022 compatibility runner', () {
    final jobs = workflow('.github/workflows/test.yml')['jobs'] as YamlMap;
    final windows = jobs['example-windows'] as YamlMap;
    expect(windows['runs-on'], 'windows-2022');
  });

  test('OpenAPI sync has least privileges required to open a PR', () {
    final jobs = workflow('.github/workflows/sync-openapi.yml')['jobs']
        as YamlMap;
    final sync = jobs['sync'] as YamlMap;
    expect(
      (sync['permissions'] as YamlMap).cast<String, Object?>(),
      {'contents': 'write', 'pull-requests': 'write'},
    );
  });

  test('aggregate gate requires every claimed platform', () {
    final jobs = workflow('.github/workflows/test.yml')['jobs'] as YamlMap;
    final gate = jobs['all-tests-pass'] as YamlMap;
    final needs = (gate['needs'] as YamlList).cast<String>();
    expect(
      needs,
      containsAll(<String>[
        'example-android',
        'example-ios',
        'example-web',
        'example-linux',
        'example-macos',
        'example-windows',
      ]),
    );
  });
}
```

- [ ] **Step 2: Run the workflow contract test and verify RED**

Run: `dart pub get && dart test test/workflows/workflow_contract_test.dart -r expanded`

Expected: FAIL because Windows is `windows-latest` and the sync job has no permissions map.

- [ ] **Step 3: Apply the minimum workflow repairs**

Change the Windows job to:

```yaml
  example-windows:
    name: Example builds (Windows)
    # flutter_inappwebview 6.1.5 fails on VS 2026. Track upstream #2839.
    runs-on: windows-2022
```

Add to the OpenAPI sync job:

```yaml
    permissions:
      contents: write
      pull-requests: write
```

- [ ] **Step 4: Add explicit web compiler smoke checks**

Create `tool/web_compile_smoke.dart`:

```dart
import 'dart:typed_data';

import 'package:near_dart/near_dart.dart';

Future<void> main() async {
  final key = await KeyPairEd25519.fromSeed(Uint8List(32));
  final signature = await key.sign(Uint8List.fromList(const [1, 2, 3]));
  if (signature.length != 64) throw StateError('Invalid ed25519 signature');
}
```

Add `dart2js` and `dart2wasm` steps to `platform-chrome`, writing outputs to
the runner temp directory:

```yaml
      - name: Compile SDK smoke test with dart2js
        run: dart compile js -O1 tool/web_compile_smoke.dart -o "$RUNNER_TEMP/near_dart.js"
      - name: Compile SDK smoke test with dart2wasm
        run: dart compile wasm tool/web_compile_smoke.dart -o "$RUNNER_TEMP/near_dart.wasm"
```

- [ ] **Step 5: Add a non-publishing release-check workflow**

Create a manual and pull-request workflow with three jobs:

```yaml
name: Release Check

on:
  workflow_dispatch:
  pull_request:
    paths:
      - 'pubspec.yaml'
      - 'packages/**/pubspec.yaml'
      - 'CHANGELOG.md'
      - 'packages/**/CHANGELOG.md'

permissions:
  contents: read

jobs:
  near-dart:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      - run: dart pub get --no-example
      - run: dart analyze --fatal-infos lib test
      - run: dart pub publish --dry-run
  near-jsonrpc-client:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: packages/near_jsonrpc_client
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      - run: dart pub get
      - run: dart analyze
      - run: dart test
      - run: dart pub publish --dry-run
  near-wallet-connect:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: packages/near_wallet_connect
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze lib test
      - run: flutter test
      - run: dart pub publish --dry-run
```

- [ ] **Step 6: Verify GREEN and update release documentation**

Run:

```bash
dart test test/workflows/workflow_contract_test.dart -r expanded
dart compile js -O1 tool/web_compile_smoke.dart -o /tmp/near_dart.js
dart compile wasm tool/web_compile_smoke.dart -o /tmp/near_dart.wasm
```

Expected: all commands exit 0. Update `docs/release.md` with Windows, Linux,
macOS, Chrome, dart2js, dart2wasm, and the manual Release Check workflow.

- [ ] **Step 7: Commit the CI slice**

```bash
git add pubspec.yaml pubspec.lock test/workflows tool/web_compile_smoke.dart .github/workflows docs/release.md
git commit -m "ci: repair desktop and OpenAPI automation"
```

---

### Task 2: Add Redacted Diagnostics and Stable Error Types

**Files:**
- Create: `lib/src/diagnostics/near_diagnostics.dart`
- Create: `lib/src/diagnostics/near_errors.dart`
- Modify: `lib/near_dart.dart`
- Modify: `lib/src/types/rpc_result.dart`
- Create: `test/unit/diagnostics/near_diagnostics_test.dart`
- Create: `test/unit/diagnostics/near_errors_test.dart`

**Interfaces:**
- Produces: `NearLogger`, `NearLogEvent`, `NearLogEventType`, `NearErrorCode`, `NearSdkException`, `nearErrorFrom`, and `RpcError.nearErrorCode`.

- [ ] **Step 1: Write failing tests for redaction and error mapping**

Tests must prove that sensitive metadata is replaced and cannot appear in
`toString`, while safe operational metadata remains:

```dart
test('redacts sensitive metadata recursively', () {
  final event = NearLogEvent(
    level: NearLogLevel.info,
    type: NearLogEventType.rpcRequestStarted,
    operation: 'query',
    metadata: {
      'endpoint': 'https://rpc.example.com',
      'authorization': 'Bearer secret',
      'nested': {'signature': 'abc', 'attempt': 2},
    },
    timestamp: DateTime.utc(2026, 7, 13),
  );
  expect(event.metadata['endpoint'], 'https://rpc.example.com');
  expect(event.toString(), isNot(contains('Bearer secret')));
  expect(event.toString(), isNot(contains('abc')));
  expect(event.toString(), contains('<redacted>'));
});

test('maps RPC timeout and rate limit to stable codes', () {
  expect(RpcError.timeout('slow').nearErrorCode, NearErrorCode.rpcTimeout);
  expect(RpcError.http(429, 'limited').nearErrorCode, NearErrorCode.rateLimited);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run: `dart test test/unit/diagnostics -r expanded`

Expected: compile failure because the public types do not exist.

- [ ] **Step 3: Implement the diagnostics API**

Define these exact public types:

```dart
enum NearLogLevel { debug, info, warning, error }

enum NearLogEventType {
  rpcRequestStarted,
  rpcRequestRetried,
  rpcRequestSucceeded,
  rpcRequestFailed,
  intentsRequestStarted,
  intentsRequestSucceeded,
  intentsRequestFailed,
  walletFlowOpened,
  walletCallbackReceived,
  walletConnected,
  walletDisconnected,
  transactionSubmitted,
  transactionFinalized,
}

typedef NearLogger = void Function(NearLogEvent event);

class NearLogEvent {
  NearLogEvent({
    required this.level,
    required this.type,
    required this.operation,
    Map<String, Object?> metadata = const {},
    DateTime? timestamp,
  }) : metadata = Map.unmodifiable(redactNearMetadata(metadata)),
       timestamp = timestamp ?? DateTime.now().toUtc();

  final NearLogLevel level;
  final NearLogEventType type;
  final String operation;
  final Map<String, Object?> metadata;
  final DateTime timestamp;
}

void emitNearLog(NearLogger? logger, NearLogEvent event) {
  if (logger == null) return;
  try { logger(event); } catch (_) {}
}
```

`redactNearMetadata` recursively redacts keys containing `authorization`,
`token`, `secret`, `privatekey`, `signature`, `payload`, `body`, `signedtx`,
or `nonce` after lowercasing and removing `_`/`-`.

- [ ] **Step 4: Implement stable SDK errors**

Define:

```dart
enum NearErrorCode {
  invalidInput,
  wrongNetwork,
  notConnected,
  missingCallback,
  deepLinkUnavailable,
  userRejected,
  walletResponseInvalid,
  accountMismatch,
  signatureVerificationFailed,
  accessKeyNotFound,
  accessKeyMismatch,
  rpcUnavailable,
  rpcTimeout,
  rateLimited,
  transactionFailed,
  insufficientBalance,
  unsupportedOperation,
  invalidResponse,
  cancelled,
  unknown,
}

class NearSdkException implements Exception {
  const NearSdkException({
    required this.code,
    required this.message,
    this.retryable = false,
    this.cause,
  });
  final NearErrorCode code;
  final String message;
  final bool retryable;
  final Object? cause;
}
```

Implement `nearErrorFrom(Object error)` with deterministic mappings for
`TimeoutException`, `UnsupportedError`, `StateError`, `FormatException`, and
known message fragments such as `reject`, `insufficient balance`, `access key`,
`wrong network`, and `could not open`.

- [ ] **Step 5: Export types and map RPC errors**

Export both diagnostics files from `lib/near_dart.dart`. Add a
`NearErrorCode get nearErrorCode` extension/getter on `RpcError` mapping timeout,
network, HTTP 429, other HTTP failures, parse errors, cancellation, and runtime
messages without changing `RpcResult` behavior.

- [ ] **Step 6: Verify GREEN and commit**

Run:

```bash
dart format lib/src/diagnostics lib/src/types/rpc_result.dart test/unit/diagnostics
dart test test/unit/diagnostics -r expanded
dart analyze --fatal-infos lib test
```

Expected: exit 0.

```bash
git add lib/near_dart.dart lib/src/diagnostics lib/src/types/rpc_result.dart test/unit/diagnostics
git commit -m "feat: add redacted diagnostics and typed errors"
```

---

### Task 3: Instrument RPC and NEAR Intents Clients

**Files:**
- Modify: `lib/src/client/near_rpc_client.dart`
- Modify: `lib/src/intents/one_click_client.dart`
- Modify: `lib/src/intents/one_click_explorer_client.dart`
- Modify: `lib/src/intents/solver_relay_client.dart`
- Create: `test/unit/client/rpc_logging_test.dart`
- Extend: `test/unit/intents/one_click_client_test.dart`
- Extend: `test/unit/intents/one_click_explorer_client_test.dart`
- Extend: `test/unit/intents/solver_relay_client_test.dart`

**Interfaces:**
- Consumes: `NearLogger` and `NearSdkException` from Task 2.
- Produces: optional `logger:` constructor parameters and safe operation events.

- [ ] **Step 1: Write failing event-order tests**

For a primary RPC 503 followed by fallback success, assert:

```dart
expect(events.map((e) => e.type), [
  NearLogEventType.rpcRequestStarted,
  NearLogEventType.rpcRequestRetried,
  NearLogEventType.rpcRequestSucceeded,
]);
expect(events.expand((e) => e.metadata.keys), isNot(contains('params')));
```

For each Intents client, assert `started` then `succeeded` for 2xx and
`started` then `failed` for HTTP/JSON-RPC errors. Pass an auth value containing
`test-secret` and prove no event string contains it.

- [ ] **Step 2: Run focused tests and verify RED**

Run:

```bash
dart test test/unit/client/rpc_logging_test.dart -r expanded
dart test test/unit/intents -r expanded
```

Expected: compile failures because clients have no `logger` parameter.

- [ ] **Step 3: Instrument `NearRpcClient`**

Add `NearLogger? logger` to all constructors/factories. Emit one started event,
one retry event per fallback transition, and one terminal event. Metadata is
limited to:

```dart
{
  'endpoint': Uri.parse(url).origin,
  'attempt': attempt,
  'endpointCount': endpoints.length,
  'statusCode': response.statusCode,
  'durationMs': stopwatch.elapsedMilliseconds,
}
```

Do not log params, request IDs, response bodies, or parser output. Add
`TxExecutionStatus waitUntil = TxExecutionStatus.executed` to `txStatus` and
send `waitUntil.rpcValue` instead of the fixed string.

- [ ] **Step 4: Instrument Intents clients and normalize exceptions**

Add `NearLogger? logger` to each constructor. Emit endpoint origin, HTTP method,
operation/path, status code, and duration. Make `OneClickApiException`,
`OneClickExplorerApiException`, and `SolverRelayException` extend
`NearSdkException` while preserving their existing constructor fields. Their
`toString` methods must not print response bodies.

- [ ] **Step 5: Verify GREEN and commit**

Run:

```bash
dart format lib/src/client lib/src/intents test/unit/client test/unit/intents
dart test test/unit/client/rpc_logging_test.dart -r expanded
dart test test/unit/intents -r expanded
dart analyze --fatal-infos lib test
```

Expected: exit 0 and no secret value in test output.

```bash
git add lib/src/client lib/src/intents test/unit/client test/unit/intents
git commit -m "feat: instrument RPC and Intents operations"
```

---

### Task 4: Verify Wallet Signatures and Normalize Adapter Failures

**Files:**
- Modify: `lib/src/wallet/adapters/my_near_wallet_adapter.dart`
- Modify: `lib/src/wallet/adapters/intear_wallet_adapter.dart`
- Modify: `lib/src/wallet/adapters/hot_wallet_adapter.dart`
- Extend: `test/unit/intear_wallet_adapter_test.dart`
- Extend: `test/unit/hot_wallet_adapter_test.dart`
- Extend: `test/unit/wallet/callback_security_test.dart`

**Interfaces:**
- Consumes: `verifyNep413Signature`, `NearLogger`, and `NearSdkException`.
- Produces: cryptographically verified Intear/HOT signed messages and typed adapter failures.

- [ ] **Step 1: Write failing tests with real generated signatures**

Generate a wallet key in each test, sign the exact `Nep413Payload`, inject the
response through the existing fake WebSocket/HTTP transport, and assert a valid
signature succeeds. Mutate one signature byte and assert:

```dart
throwsA(
  isA<NearSdkException>().having(
    (error) => error.code,
    'code',
    NearErrorCode.signatureVerificationFailed,
  ),
)
```

Also assert Intear does not persist its app key when sign-in message
verification fails, and HOT sign-in fails with `walletResponseInvalid` when
`publicKey` is missing.

- [ ] **Step 2: Run adapter tests and verify RED**

Run:

```bash
dart test test/unit/intear_wallet_adapter_test.dart -r expanded
dart test test/unit/hot_wallet_adapter_test.dart -r expanded
dart test test/unit/wallet/callback_security_test.dart -r expanded
```

Expected: invalid signatures are currently accepted and HOT substitutes a
zero key.

- [ ] **Step 3: Verify Intear responses before persistence**

In `signIn`, parse and verify `signedMessage` before `keyStore.setKey`. Require
a signed response when `messageToSign` was requested, ensure its account ID
matches the connected account, and call `verifyNep413Signature`. In
`signMessage`, ensure the returned account matches the requested account and
verify the signature before returning.

- [ ] **Step 4: Verify HOT responses and remove the placeholder key**

Require `accountId` and `publicKey` in sign-in. In `signMessage`, parse then
call `verifyNep413Signature` before returning. Convert relay HTTP, deep-link,
timeout, rejection, and malformed-response failures to stable error codes.

- [ ] **Step 5: Add adapter logging**

Add optional `logger:` parameters and emit wallet-flow-opened and terminal
events with only wallet ID, operation, duration, and success/failure code.
Instrument MyNearWallet callback receipt without including callback query or
fragment values.

- [ ] **Step 6: Verify GREEN and commit**

Run all three focused test commands from Step 2, then:

```bash
dart test test/unit --exclude-tags integration
dart analyze --fatal-infos lib test
```

Expected: exit 0.

```bash
git add lib/src/wallet/adapters test/unit/intear_wallet_adapter_test.dart test/unit/hot_wallet_adapter_test.dart test/unit/wallet
git commit -m "fix: verify wallet signatures and type relay failures"
```

---

### Task 5: Add On-Chain Wallet Security Policies to Flutter

**Files:**
- Create: `packages/near_wallet_connect/lib/src/wallet_security.dart`
- Modify: `packages/near_wallet_connect/lib/src/near_wallet_controller.dart`
- Modify: `packages/near_wallet_connect/lib/near_wallet_connect.dart`
- Create: `packages/near_wallet_connect/test/wallet_security_test.dart`
- Extend: `packages/near_wallet_connect/test/near_connect_button_test.dart`

**Interfaces:**
- Consumes: `NearRpcClient.viewAccessKey`, `NearRpcClient.txStatus`, typed transaction responses, and adapter results.
- Produces: `NearWalletSecurityPolicy`, `NearWalletSecurity`, `lastException`, access-key checks, and transaction confirmation.

- [ ] **Step 1: Write failing security service tests**

Define desired policy usage:

```dart
const policy = NearWalletSecurityPolicy(
  verifyAccessKeyOnConnect: true,
  transactionFinality: TxExecutionStatus.final_,
);
```

Using a fake `NearRpcClient`, test:

- function-call key exists with matching receiver and methods: pass;
- missing key: `accessKeyNotFound`;
- wrong receiver or insufficient method scope: `accessKeyMismatch`;
- two distinct transaction hashes: two `txStatus` calls with `final_`;
- transaction status failure: `transactionFailed` or
  `insufficientBalance` when the failure payload contains that signal;
- confirmation enabled but no extractable hashes: `walletResponseInvalid`.

- [ ] **Step 2: Run Flutter tests and verify RED**

Run:

```bash
cd packages/near_wallet_connect
flutter test test/wallet_security_test.dart
```

Expected: compile failure because the policy/service do not exist.

- [ ] **Step 3: Implement the injectable security service**

Define:

```dart
class NearWalletSecurityPolicy {
  const NearWalletSecurityPolicy({
    this.verifyAccessKeyOnConnect = false,
    this.transactionFinality,
  });
  final bool verifyAccessKeyOnConnect;
  final TxExecutionStatus? transactionFinality;
}

class NearWalletSecurity {
  const NearWalletSecurity(this.client);
  final NearRpcClient client;

  Future<void> verifyAccessKey({
    required WalletAccount account,
    required AccountId contractId,
    required List<String> methodNames,
    required bool requireFunctionCallScope,
  });

  Future<void> confirmTransactions({
    required AccountId senderAccountId,
    required List<dynamic> outcomes,
    required TxExecutionStatus waitUntil,
  });
}
```

Hash extraction accepts strings and maps containing `transactionHash`,
`transaction_hash`, `txHash`, `hash`, nested `transaction.hash`, or lists in
`transactionHashes`. It deduplicates while retaining order.

- [ ] **Step 4: Integrate policy, typed state, and logging in controller**

Add optional constructor fields:

```dart
NearWalletController({
  // existing parameters
  this.securityPolicy = const NearWalletSecurityPolicy(),
  NearWalletSecurity? security,
  this.logger,
}) : security = security ?? NearWalletSecurity(client), ...;
```

Because initializer ordering must use the resolved client, refactor the
constructor to a redirecting/private constructor or initialize `security` in
the constructor body. Expose:

```dart
NearSdkException? get lastException => _lastException;
```

Keep `String? get error` equal to `lastException?.message` for compatibility.
Map unavailable wallet, disconnected signing, unsupported wallet operations,
callbacks, and adapter exceptions through `nearErrorFrom`.

After Intear/MyNearWallet connect, verify the function-call scope when enabled;
after HOT connect, verify key existence only. Remove any newly persisted key if
verification fails. After wallet submission, confirm hashes when
`transactionFinality != null`, then return the original outcomes unchanged.

- [ ] **Step 5: Verify controller compatibility tests**

Add a widget/controller test that attempts HOT on testnet and asserts both:

```dart
expect(controller.error, contains('not available'));
expect(controller.lastException?.code, NearErrorCode.wrongNetwork);
```

Run:

```bash
cd packages/near_wallet_connect
dart format lib test
flutter analyze lib test
flutter test
```

Expected: exit 0.

- [ ] **Step 6: Commit the wallet security slice**

```bash
git add packages/near_wallet_connect/lib packages/near_wallet_connect/test
git commit -m "feat: add on-chain wallet confirmation policies"
```

---

### Task 6: Finish Architecture Recipes and Pub Screenshots

**Files:**
- Create: `docs/flutter-architectures.md`
- Modify: `README.md`
- Modify: `packages/near_wallet_connect/README.md`
- Create: `screenshots/intents-quote.png`
- Create: `packages/near_wallet_connect/screenshots/wallet-connect.png`
- Modify: `pubspec.yaml`
- Modify: `packages/near_wallet_connect/pubspec.yaml`

**Interfaces:**
- Consumes: existing `NearWalletController`/`NearConnectButton` APIs and existing demo recordings.
- Produces: copy-paste state-management recipes and package-gallery metadata.

- [ ] **Step 1: Write the four complete architecture recipes**

Create one concise section each for ChangeNotifier, Provider, Riverpod, and
Bloc/Cubit. Every example owns controller initialization/disposal, exposes
busy/account/error state, and renders `NearConnectButton`; partner API keys are
not present in client code.

- [ ] **Step 2: Extract real product frames for package screenshots**

Use existing repository/NearCoffee demo video frames, not generated mockups.
Extract PNGs with deterministic timestamps, crop only window chrome/letterbox,
and inspect both images before adding them. Target widths between 1200 and
1920 pixels and keep each file below 4 MB.

- [ ] **Step 3: Register screenshot metadata**

Add to the root and wallet pubspecs:

```yaml
screenshots:
  - description: NEAR Intents quote and lifecycle in the reference app
    path: screenshots/intents-quote.png
```

and:

```yaml
screenshots:
  - description: Multi-wallet connection in Flutter
    path: screenshots/wallet-connect.png
```

- [ ] **Step 4: Link recipes and validate package metadata**

Run:

```bash
dart pub publish --dry-run
cd packages/near_wallet_connect
dart pub publish --dry-run
```

Expected: no screenshot path/format warnings and no unintentional local files.

- [ ] **Step 5: Commit adoption assets**

```bash
git add docs/flutter-architectures.md README.md packages/near_wallet_connect/README.md screenshots packages/near_wallet_connect/screenshots pubspec.yaml packages/near_wallet_connect/pubspec.yaml
git commit -m "docs: add Flutter recipes and package screenshots"
```

---

### Task 7: Documentation, Security Review, and Full Local Verification

**Files:**
- Modify: `docs/security.md`
- Modify: `docs/troubleshooting.md`
- Modify: `docs/wallet-recipes.md`
- Modify: `README.md`
- Modify: `packages/near_wallet_connect/README.md`
- Modify: `CHANGELOG.md`
- Modify: `packages/near_wallet_connect/CHANGELOG.md`

**Interfaces:**
- Consumes: all implemented APIs.
- Produces: accurate trust model, migration notes, and release evidence.

- [ ] **Step 1: Document diagnostics and typed error handling**

Add examples that switch on `NearErrorCode`, register a logger, and state that
callbacks must not record secrets. Document compatibility of `controller.error`
and `controller.lastException`.

- [ ] **Step 2: Update the relay threat model**

State exactly which responses are now signature-verified, how optional access
key verification works, how transaction finality is confirmed, and what relay
availability/unsigned metadata risks remain.

- [ ] **Step 3: Add unreleased changelog entries**

Use an `Unreleased` section in both changelogs. Do not bump package versions;
publishing remains a separate approved operation.

- [ ] **Step 4: Run the complete local verification matrix**

From root:

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos lib test
dart test --exclude-tags integration
dart test --tags integration
dart test --platform chrome test/platform/web_test.dart
dart compile js -O1 tool/web_compile_smoke.dart -o /tmp/near_dart.js
dart compile wasm tool/web_compile_smoke.dart -o /tmp/near_dart.wasm
dart pub publish --dry-run
```

Then:

```bash
cd packages/near_wallet_connect
flutter pub get
flutter analyze lib test
flutter test
dart pub publish --dry-run
```

Then:

```bash
cd packages/near_jsonrpc_client
dart pub get
dart analyze
dart test
dart pub publish --dry-run
```

Then build locally available example targets:

```bash
cd example
flutter build web --debug
flutter build apk --debug
flutter build linux --debug
```

Expected: every command exits 0. Windows/macOS/iOS remain GitHub-hosted gates
when unavailable locally.

- [ ] **Step 5: Scan for leaked instrumentation and secrets**

Run:

```bash
rg -n "\[DEBUG-|Bearer [A-Za-z0-9]|X-API-Key:|private[_ -]?key" lib test docs packages --glob '!**/*.lock'
git diff --check
git status --short
```

Expected: no debug tags or literal credentials; documentation references are
generic placeholders only.

- [ ] **Step 6: Commit documentation and verification updates**

```bash
git add README.md CHANGELOG.md docs packages/near_wallet_connect/README.md packages/near_wallet_connect/CHANGELOG.md
git commit -m "docs: document diagnostics and wallet hardening"
```

---

### Task 8: Push, Verify GitHub Actions, and Prepare Issue/Publication Handoff

**Files:**
- Create: `docs/release-evidence/2026-07-13-roadmap-completion.md`
- Create: `docs/publication/2026-07-13-channel-copy.md`

**Interfaces:**
- Consumes: local test evidence and GitHub Actions run URLs.
- Produces: auditable completion matrix and publication drafts; no public mutation.

- [ ] **Step 1: Review the complete branch diff**

Run:

```bash
git status --short --branch
git diff origin/main...HEAD --stat
git diff origin/main...HEAD -- . ':!**/*.lock'
```

Expected: only scoped roadmap/CI changes.

- [ ] **Step 2: Push the verified commits**

Run: `git push origin main`

Expected: push succeeds. This authorizes code delivery only, not package or
social publication.

- [ ] **Step 3: Dispatch and watch both workflows**

Run:

```bash
gh workflow run test.yml -f run_integration=true -f run_mainnet=true
gh workflow run sync-openapi.yml
gh run list --limit 10
```

Watch each relevant run to completion with `gh run watch <run-id> --exit-status`.
If sync creates a PR, record it but do not merge it automatically.

- [ ] **Step 4: Record release evidence and issue matrix**

The evidence document lists each issue #5, #6, and #8-#14 with exact files,
tests, and CI URLs. It includes suggested closing text but does not call
`gh issue close` or post comments.

- [ ] **Step 5: Prepare channel-specific English publication copy**

Create concise variants for X, LinkedIn, NEAR Forum, Reddit, and Telegram/
Discord. Each leads with production Flutter adoption, links the YouTube demo
`https://youtu.be/2jpLhZ0H43k`, names NearCoffee as the reference app, and asks
for 2-3 production projects. Do not post any copy.

- [ ] **Step 6: Final verification**

Run:

```bash
git status --short --branch
gh run list --limit 10 --json name,conclusion,headSha,url
```

Expected: clean worktree, main synchronized, required workflows successful.
Report any automated OpenAPI PR separately for owner review.
