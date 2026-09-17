## 0.1.1

- Sync the generated client with the current nearcore OpenAPI spec.
- Add a package example and point the homepage at the GitHub repository.

## 0.1.0

Initial release.

- Type-safe NEAR JSON-RPC client generated from the nearcore OpenAPI spec
  (343 models + 38 RPC methods).
- Pure Dart: verified on native (VM) and web (dart2js) against live testnet.
- `tool/generate.dart` generator + scheduled GitHub Action to auto-sync with
  upstream nearcore.
