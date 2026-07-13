# Release Checklist

Run this before publishing any package to pub.dev.

## Prepare

1. Bump `version:` in the package `pubspec.yaml`.
2. Update the package `CHANGELOG.md`.
3. Update README install snippets.
4. Update examples if public APIs changed.
5. Confirm no local-only overrides are committed.

## Root `near_dart`

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos lib test
dart test --exclude-tags integration
dart test --tags integration
dart pub publish --dry-run
```

## `near_wallet_connect`

```bash
cd packages/near_wallet_connect
flutter pub get
flutter analyze lib test
flutter test
dart pub publish --dry-run
```

## `near_jsonrpc_client`

```bash
cd packages/near_jsonrpc_client
dart pub get
dart analyze
dart test
dart pub publish --dry-run
```

## Example Builds

```bash
cd example
flutter build web --debug
flutter build apk --debug
flutter build ios --debug --no-codesign

cd ../packages/near_wallet_connect/example
flutter build apk --debug
```

## CI Workflow Coverage

The required CI workflow builds the example on Windows Server 2022, Linux,
and macOS, and runs the SDK's Chrome platform tests. The Chrome job also
compiles `tool/web_compile_smoke.dart` with both `dart2js` and `dart2wasm`.

The manual **Release Check** workflow runs on relevant package and changelog
pull requests. It performs analysis, tests, and `dart pub publish --dry-run`
for each published package; it does not publish packages.

## Publish Order

1. Publish `near_dart`.
2. Wait until pub.dev serves the new version.
3. Publish `near_wallet_connect` if it depends on the new core.
4. Update dependent apps such as NearCoffee.
5. Record device demos for wallet-visible changes.

Publishing requires explicit owner approval every time.
