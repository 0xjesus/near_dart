# NEAR Flutter Publication Drafts

These drafts are prepared for owner review only. None has been posted.

Common links:

- Tutorial/demo: https://youtu.be/2jpLhZ0H43k
- Repository (`main`): https://github.com/0xjesus/near_dart
- Current pub.dev release (`near_dart 0.5.0`): https://pub.dev/packages/near_dart

The repository contains work newer than the current pub.dev release. Do not
describe every feature on `main` as published until the separate release
checklist and owner approval are complete.

## X

### Post 1

near_dart on main now covers NEAR Intents clients, MyNearWallet/Intear/HOT,
typed NEP helpers, encrypted non-web storage, callback hardening, diagnostics,
and six-platform CI. NearCoffee is the next reference-app integration target.

Demo: https://youtu.be/2jpLhZ0H43k

### Post 2

Looking for 2-3 production Flutter projects on NEAR to test near_dart in real
wallet, contract, token/NFT, and Intents flows.

Current code and adoption tracker:
https://github.com/0xjesus/near_dart

## LinkedIn

Production Flutter adoption is the next milestone for near_dart, an open-source
Dart and Flutter SDK for NEAR.

The implementation on `main` now includes:

- typed clients for NEAR Intents 1Click quotes, deposits, status, asset discovery, explorer history, and solver relay requests;
- conversion of generated NEP-413 intent payloads and assembly of wallet-signed submissions;
- MyNearWallet, Intear, and HOT wallet integrations;
- NEP-413 authentication plus a configurable better-near-auth example;
- typed NEP-141, NEP-145, and NEP-171 helpers, `viewFunction<T>()`, and exact gas/amount utilities;
- encrypted key storage on supported non-web platforms, callback correlation and validation, optional on-chain access-key verification, and optional transaction confirmation;
- structured diagnostics, typed errors, and CI verification across Android, iOS, web, macOS, Windows, and Linux.

NearCoffee is the product scenario used in the tutorial. Updating the NearCoffee
repository to the new package versions and implementing its real Intents flow
is the next app-level step; it is not presented as already complete.

Tutorial: https://youtu.be/2jpLhZ0H43k

I am looking for 2-3 production Flutter projects in the NEAR ecosystem to
integrate the SDK and report concrete friction from real user flows.

Repository: https://github.com/0xjesus/near_dart

Current published release: https://pub.dev/packages/near_dart

#NEAR #Flutter #Dart #Web3 #OpenSource

## NEAR Forum

Title: Looking for 2-3 production Flutter projects to adopt near_dart

Production Flutter adoption is the next milestone for near_dart. The goal is
to make NEAR usable from Dart across real mobile, web, and desktop products,
not only from isolated RPC examples.

The implementation on `main` includes:

- a typed core SDK for RPC, accounts, local transaction signing, contract calls, and NEP-413 authentication;
- MyNearWallet, Intear, and HOT wallet flows for Flutter;
- typed NEP-141, NEP-145, and NEP-171 helpers;
- typed NEAR Intents clients for 1Click quote/deposit/status, asset discovery, explorer history, and solver relay requests;
- conversion of API-generated NEP-413 payloads plus assembly of wallet-signed intent submissions;
- encrypted non-web key storage, callback validation/correlation, optional access-key checks, and optional transaction confirmation;
- structured diagnostics and typed application-facing errors;
- CI coverage for Android, iOS, web, macOS, Windows, Linux, JavaScript, Dart2Wasm, mainnet reads, and a real testnet transaction.

NearCoffee is the reference product scenario in the tutorial. Its repository
still needs to be upgraded and wired to the new Intents APIs, so this is a
roadmap target rather than a claim that the app integration is already live.

Video tutorial: https://youtu.be/2jpLhZ0H43k

Repository: https://github.com/0xjesus/near_dart

I am looking for 2-3 production projects willing to integrate near_dart and
share missing APIs, wallet edge cases, platform failures, and developer-
experience friction. That production evidence is the next priority.

The technical work is on `main`. Package publication and version changes
remain a separate, owner-approved release step.

## Reddit

Title: near_dart adds NEAR Intents clients and multi-wallet Flutter flows - looking for adopters

near_dart is an open-source Dart and Flutter SDK for NEAR. The code on `main`
now includes typed 1Click and solver-relay clients, MyNearWallet/Intear/HOT,
NEP-413, typed FT/storage/NFT helpers, encrypted non-web storage, callback
hardening, diagnostics, and six-platform CI.

NearCoffee is the tutorial's reference product scenario and the next app we
plan to upgrade; its real Intents integration is not claimed as complete.

Tutorial: https://youtu.be/2jpLhZ0H43k

Repository: https://github.com/0xjesus/near_dart

I am looking for 2-3 Flutter projects building on NEAR to test real wallet,
platform, and API flows. Publication of the newer `main` work will be handled
separately after version and release approval.

## Telegram / Discord

near_dart on `main` now includes typed NEAR Intents clients, MyNearWallet /
Intear / HOT, NEP-413, typed FT/storage/NFT helpers, encrypted non-web storage,
callback hardening, diagnostics, and six-platform CI.

NearCoffee is the tutorial scenario and next repository integration target,
not a completed Intents implementation.

Tutorial: https://youtu.be/2jpLhZ0H43k
Repo: https://github.com/0xjesus/near_dart

Looking for 2-3 production Flutter projects on NEAR to integrate the SDK and
report concrete feedback from real users.
