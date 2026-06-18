# near_jsonrpc_client

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Type-safe NEAR Protocol JSON-RPC client for Dart, **generated from the
official [nearcore OpenAPI spec](https://github.com/near/nearcore/blob/master/chain/jsonrpc/openapi/openapi.json)**.

- **Platform-agnostic**: pure Dart — runs identically on native (AOT: mobile,
  desktop, server) and web (compiled to JavaScript / WASM).
- **Fully generated**: every request/response model (343 types) and all 38 RPC
  methods are produced by `tool/generate.dart` from the spec — no hand-written
  drift.
- **Auto-maintained**: a scheduled GitHub Action re-fetches the spec,
  regenerates the client, and opens a PR when nearcore changes.

```dart
import 'package:near_jsonrpc_client/near_jsonrpc_client.dart';

void main() async {
  final rpc = NearJsonRpcClient(endpoint: 'https://test.rpc.fastnear.com');

  // No-input methods take no arguments:
  final status = await rpc.status();
  print(status.chain_id);                       // testnet
  print(status.sync_info!.latest_block_height); // typed

  // Methods with params take a generated request type:
  final block = await rpc.block(
    RpcBlockRequest.fromJson({'finality': 'final'}),
  );
  print(block.header!.height);

  rpc.close();
}
```

## How it's generated

`tool/generate.dart` reads `tool/openapi.json` (a committed snapshot of the
nearcore spec) and emits:

- `lib/src/models.g.dart` — a Dart class for every object schema, a Dart
  `enum` for every string enum, a holder for every `oneOf`/`anyOf` union, and
  typedefs for aliases.
- `lib/src/client.g.dart` — `NearJsonRpcClient` with one typed method per RPC
  path.

Regenerate manually with:

```bash
dart run tool/generate.dart
```

## Design notes

- **Defensive decoding**: every model field is nullable. nearcore's spec marks
  many fields `required` that can be null/absent in real responses, and the
  spec evolves — a generated client must decode without crashing.
- **Unions** (`oneOf`/`anyOf`, e.g. NEAR's Rust-tagged enums) are represented
  as holders exposing the raw decoded `json`; inspect it for the active
  variant.
- The client exposes `NearJsonRpcClient.specVersion` — the nearcore OpenAPI
  version it was generated from.

## Relationship to `near_dart`

This package is the low-level, generated RPC layer. For transaction signing
(ed25519 + Borsh), a high-level `Account` API, and wallet connect, see
[`near_dart`](https://pub.dev/packages/near_dart).

## License

MIT
