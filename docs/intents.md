# NEAR Intents

`near_dart` includes app-level NEAR Intents support through the 1Click API and
advanced partner support through the Message Bus solver relay.

Use this feature when the app wants a user outcome instead of a hand-authored
transaction route, for example "swap this asset into that asset and deliver it
to this recipient".

For a product-style reference, see
[NearCoffee](https://github.com/0xjesus/near-coffee): it uses
`OneClickAssetCatalog`, `OneClickQuoteBuilder`, and `OneClickClient.quote`
with `dry: true` to preview a `0.1 wNEAR -> USDC` route directly inside a
Flutter app without moving funds.

## Important limits

- NEAR Intents is mainnet infrastructure. There is no public testnet
  deployment for the Verifier contract or 1Click settlement.
- Use `dry: true` for previews and demos. Dry quotes do not create a deposit
  address and cannot move funds.
- Do not put shared partner API keys in published mobile apps. Use a backend,
  user-scoped credential, or unauthenticated dry preview where allowed.
- If a response includes a NEAR transaction hash, confirm it through RPC before
  treating high-value UX as final.
- Native NEAR is not deposited directly into `intents.near`; wrap to wNEAR or
  use a supported origin-chain deposit flow.

## 1Click app flow

```dart
final intents = OneClickClient();
final catalog = OneClickAssetCatalog(client: intents);
final builder = OneClickQuoteBuilder();

final wnear = await catalog.requireByAssetId('nep141:wrap.near');
final usdc = await catalog.requireByAssetId('nep141:usdc.near');

final request = builder.exactInput(
  originToken: wnear,
  destinationToken: usdc,
  amount: '0.1',
  refundTo: 'alice.near',
  recipient: 'alice.near',
);

final quote = await intents.quote(request);

print(quote.quote.amountOutFormatted);
```

`OneClickAmount.parseDecimal()` converts decimal user input into smallest-unit
strings exactly. Do not use `double` for token amounts.

## Asset discovery

```dart
final catalog = OneClickAssetCatalog(client: OneClickClient());

final nearTokens = await catalog.search(blockchain: 'near');
final usdc = await catalog.requireByAssetId('nep141:usdc.near');

print('${usdc.symbol}: ${OneClickAmount.formatSmallestUnit('240000', 6)}');
```

The catalog caches `/v0/tokens` for five minutes by default. Pass
`refresh: true` when the app needs to force a fresh supported-token list.

## Quote builder

Use `OneClickQuoteBuilder` for product UI. It keeps defaults safe for previews
(`dry: true`) and uses the token decimals from the live asset catalog.

```dart
final builder = OneClickQuoteBuilder(
  defaults: const OneClickQuoteDefaults(
    dry: false,
    slippageTolerance: 100,
    referral: 'nearcoffee',
    appFees: [OneClickAppFee(recipient: 'nearcoffee.near', fee: 25)],
  ),
);

final request = builder.exactOutput(
  originToken: wnear,
  destinationToken: usdc,
  amount: '5.00',
  refundTo: 'alice.near',
  recipient: 'alice.near',
  recipientType: OneClickRecipientType.intents,
);
```

`exactInput()` parses with origin-token decimals. `exactOutput()` parses with
destination-token decimals.

## Swap lifecycle controller

`OneClickSwapController` is a small state machine for Flutter controllers,
Riverpod providers, BLoCs, or CLI progress output.

```dart
final swap = OneClickSwapController(client: intents);

swap.states.listen((state) {
  print('${state.stage}: ${state.error ?? state.depositAddress ?? ''}');
});

final liveRequest = builder.exactInput(
  originToken: wnear,
  destinationToken: usdc,
  amount: '0.1',
  refundTo: 'alice.near',
  recipient: 'alice.near',
  dry: false,
);

final quote = await swap.quote(liveRequest);

await swap.submitDeposit(
  depositAddress: quote.quote.depositAddress!,
  txHash: 'origin-chain-tx-hash',
  memo: quote.quote.depositMemo,
);

await for (final state in swap.pollStatus(
  depositAddress: quote.quote.depositAddress!,
  depositMemo: quote.quote.depositMemo,
)) {
  if (state.isTerminal) break;
}
```

For a real non-dry quote, the quote response provides the deposit address and
memo/chain addresses. After the user deposits on the origin chain, submit the
origin transaction hash and poll status:

```dart
await intents.submitDeposit(
  depositAddress: quote.quote.depositAddress!,
  txHash: 'origin-chain-tx-hash',
  memo: quote.quote.depositMemo,
);

final status = await intents.status(
  depositAddress: quote.quote.depositAddress!,
  depositMemo: quote.quote.depositMemo,
);

if (status.kind == OneClickStatusKind.success) {
  print(status.swapDetails?.nearTxHashes);
}
```

## Explorer API

`OneClickExplorerClient` reads historical 1Click transactions for dashboards,
support tooling, and "where is my swap?" screens. The Explorer API requires a
partner JWT in production and is rate-limited, so call it from a backend when
possible.

```dart
final explorer = OneClickExplorerClient(
  auth: OneClickAuth.bearerToken(jwt),
);

final txs = await explorer.transactions(
  OneClickExplorerTransactionsRequest(
    numberOfTransactions: 25,
    search: 'deposit-address-or-tx-hash',
    fromChainIds: const ['near'],
    statuses: const [OneClickStatusKind.success, OneClickStatusKind.refunded],
  ),
);

for (final tx in txs) {
  print('${tx.status}: ${tx.amountInFormatted} -> ${tx.amountOutFormatted}');
}
```

## Signing generated intents

When funds are already inside Intents (`depositType: INTENTS` or
`CONFIDENTIAL_INTENTS`), 1Click can generate an exact payload for wallet
signing. Preserve that payload byte-for-byte.

```dart
final generated = await intents.generateIntent(
  type: 'swap_transfer',
  depositAddress: quote.quote.depositAddress!,
  signerId: 'alice.near',
  standard: IntentSigningStandard.nep413,
);

final signed = await controller.signMessage(generated.asNep413Payload());

await intents.submitIntent(
  type: 'swap_transfer',
  signedData: SignedMultiPayload.fromNep413(
    generated: generated,
    signed: signed,
  ),
);
```

Redirect wallets such as MyNearWallet still require the normal callback flow:
build the sign-message URL, let the user sign in the wallet, then complete and
verify the callback before calling `submitIntent`.

## Message Bus solver relay

`SolverRelayClient` wraps the lower-level JSON-RPC Message Bus. This is for
registered partners and market makers, not the default app path.

```dart
final relay = SolverRelayClient(
  auth: OneClickAuth.xApiKey(jwt),
);

final quotes = await relay.quote(
  const SolverRelayQuoteRequest(
    defuseAssetIdentifierIn: 'nep141:wrap.near',
    defuseAssetIdentifierOut: 'nep141:usdc.near',
    exactAmountIn: '100000000000000000000000',
  ),
);

final result = await relay.publishIntent(
  SolverRelayPublishIntentRequest(
    quoteHashes: [quotes.first.quoteHash],
    signedData: signedData,
  ),
);

final relayStatus = await relay.getStatus(result.intentHash!);
```

Most Flutter apps should start with `OneClickClient`: it handles quoting,
deposit address generation, retries/refunds, and execution status around the
solver network.
