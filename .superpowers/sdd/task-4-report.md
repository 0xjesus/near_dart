# Task 4 Report

## Outcome

Implemented wallet signature verification and normalized adapter failures for
MyNearWallet, Intear, and HOT Wallet. Commit: `b8e4525`.

## RED

- Baseline focused tests passed: Intear 6, HOT 4, callback security 11.
- The initial diagnostics/API RED failed to compile because the three adapters
  did not accept `logger:` and legacy exception types had no stable `code`.
- Behavioral RED proved Intear accepted invalid and mismatched signatures,
  accepted a missing requested signed message, and persisted the app key.
- Behavioral RED proved HOT accepted a one-byte signature mutation and
  substituted the all-zero public key when the wallet omitted `publicKey`.
- Callback RED proved malformed/state-mismatched callbacks were not catchable
  as `NearSdkException`, and transaction callback values were copied into
  public execution errors.

## GREEN

- Focused commands: 3 passed, 40 tests total (15 Intear, 11 HOT, 14 callback).
- Full root unit command: 403 tests passed, 0 failed.
- Fatal analysis: 0 issues.
- Web compilation: dart2js and dart2wasm both succeeded.
- `git diff --check`: clean.

## Files

- `lib/src/wallet/adapters/my_near_wallet_adapter.dart`
- `lib/src/wallet/adapters/intear_wallet_adapter.dart`
- `lib/src/wallet/adapters/hot_wallet_adapter.dart`
- `test/unit/intear_wallet_adapter_test.dart`
- `test/unit/hot_wallet_adapter_test.dart`
- `test/unit/wallet/callback_security_test.dart`

## Self-review

- Intear verifies the exact requested NEP-413 payload and account before
  persisting its app key. Sign-in without a requested message remains valid.
- HOT requires nonempty account and public-key fields and verifies the exact
  requested NEP-413 payload before returning a signed message.
- Adapter-specific exception types remain available while extending
  `NearSdkException`; legacy Intear no-session and MyNear malformed-callback
  checks remain catchable as `StateError` and `FormatException` respectively.
- Wallet lifecycle metadata is limited to wallet ID, operation, duration,
  outcome, and stable failure code. Logger exceptions are isolated.
- Exceptions and diagnostic strings omit relay bodies, callback values,
  signatures, nonces, raw messages, keys, and full deep links.

## Residual risks

- Local signature verification proves control of the returned key, not that
  the key belongs to the claimed account on chain. Access-key verification is
  still required where account/key ownership is security-critical.
- Bridge and relay availability remain trusted transport dependencies.
- Unsigned transaction-result metadata remains relay/callback supplied and
  should be confirmed through RPC for value-bearing workflows.

## Strict RFC 8032 Follow-up

### Dependency rationale

- Added `edwards25519: ^1.0.5` for proven Edwards25519 point decoding,
  canonical encoding, addition, and equality operations on VM and web.
- The SDK does not implement field arithmetic. Its internal strict validator
  decodes with `Point`, requires an exact canonical byte round trip, rejects
  identity, and proves prime-subgroup membership with dependency-backed
  repeated double/add evaluation of `[L]P`.

### Security behavior

- `PublicKey` rejects noncanonical, identity, small-order, and mixed-order
  Ed25519 encodings with `ArgumentError`; secp256k1 remains byte-length based.
- `verifySignature` returns `false` for malformed public-point inputs,
  non-64-byte signatures, noncanonical or non-prime-subgroup `A`/`R`, and
  `S >= L`, before invoking the existing verifier.
- HOT's explicit all-zero key is classified as `walletResponseInvalid`.

### Verification evidence

- RED baseline: strict vectors failed through permissive construction/backend
  exceptions; the identity `A`, `R`, `S = 0` forgery verified; HOT accepted an
  explicit all-zero key.
- `dart pub get --no-example`: passed.
- `dart format --output=none --set-exit-if-changed .`: 135 files, 0 changed.
- Focused strict Ed25519 and HOT suite: 50 passed.
- `dart test --exclude-tags integration --reporter=compact`: 572 passed.
- `dart test --platform chrome test/platform/web_test.dart --reporter=compact`:
  22 passed, including strict RFC 8032 acceptance and rejection coverage.
- `dart analyze --fatal-infos lib test`: no issues.
- `dart compile js -O1 tool/web_compile_smoke.dart -o /tmp/near_dart_strict.js`:
  passed.
- `dart compile wasm tool/web_compile_smoke.dart -o /tmp/near_dart_strict.wasm`:
  passed.
- `git diff --cached --check`: clean before commit.

### Commit

- `c4fcb9b635e63d3dfbc77fb8e7905917039b515c`

## Minor Findings Follow-up

### Changes

- Replaced the mislabeled second order-8 vector with the canonical encoding
  `c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac037a`.
- `isCanonicalEd25519Scalar` now rejects every element outside the integer byte
  range `0..255` before little-endian decoding.
- `verifySignature` regression coverage confirms `false`, without an exception,
  for negative and above-byte values in both `R` and `S` portions of a signature.

### Verification Evidence

- TDD RED: the three new scalar tests failed because `-1`, `300`, and `256`
  were accepted as canonical scalar elements.
- TDD GREEN: focused VM strict suite: 45 passed.
- Focused Chrome strict suite: 45 passed.
- `dart analyze --fatal-infos lib test`: no issues found.
- `dart compile js -O1 tool/web_compile_smoke.dart -o /tmp/near_dart_strict.js`:
  passed.
- `dart compile wasm tool/web_compile_smoke.dart -o /tmp/near_dart_strict.wasm`:
  passed.
- `git diff --check`: clean.

### Commit

- `8f7e3f5a16b61894b7e89214e879a208f0f44b8d`
