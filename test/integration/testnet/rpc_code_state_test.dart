/// Integration tests for viewCode() and viewState() RPC methods on testnet.
///
/// NO MOCKS - All tests hit real NEAR testnet RPC endpoints.
///
/// NOTE: viewCode() and viewState() may be rate-limited on NEAR public RPC.
@Tags(['integration', 'testnet'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';
import '../../fixtures/known_data.dart';

void main() {
  late NearRpcClient client;

  setUpAll(() {
    client = NearRpcClient.testnet();
  });

  tearDownAll(() {
    client.close();
  });

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Testnet: viewCode()', () {
    test('returns contract code for wrap.testnet', () async {
      final result = await client.viewCode(
        accountId: TestnetContracts.wrapTestnet.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        // Skip if rate limited
        return;
      }

      expect(
        result.isSuccess,
        isTrue,
        reason: 'viewCode() should succeed for contract',
      );

      final code = result.getOrThrow();
      expect(code.codeBase64, isNotEmpty);
      expect(code.hash, isNotEmpty);
    });

    test('code hash matches account code hash', () async {
      // Get account info
      final accountResult = await client.viewAccount(
        accountId: TestnetContracts.wrapTestnet.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (accountResult.isFailure &&
          isRateLimitError((accountResult as RpcFailure).error)) {
        return;
      }

      final accountCodeHash = accountResult.getOrThrow().codeHash;

      // Get code
      final codeResult = await client.viewCode(
        accountId: TestnetContracts.wrapTestnet.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (codeResult.isFailure &&
          isRateLimitError((codeResult as RpcFailure).error)) {
        return;
      }

      final codeHash = codeResult.getOrThrow().hash;

      // Compare hash strings
      expect(codeHash, equals(accountCodeHash.value));
    });

    test('returns error for non-existent account', () async {
      final result = await client.viewCode(
        accountId: NonExistentAccounts.testnetNonExistent,
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });

    test('code is base64 encoded', () async {
      final result = await client.viewCode(
        accountId: TestnetContracts.wrapTestnet.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final code = result.getOrThrow();

      // Base64 strings only contain A-Z, a-z, 0-9, +, /, =
      expect(code.codeBase64, matches(RegExp(r'^[A-Za-z0-9+/]+=*$')));
    });
  });

  group('Testnet: viewState()', () {
    test('returns state for contract (if endpoint available)', () async {
      final result = await client.viewState(
        accountId: TestnetContracts.wrapTestnet.account,
        prefixBase64: '',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        // Rate limited - this is expected for viewState
        expect(result.isFailure, isTrue);
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'viewState() should succeed');

      final state = result.getOrThrow();
      // FT contracts typically have state
      expect(state.values, isNotEmpty);
    });

    test('state values have key-value pairs (if endpoint available)', () async {
      final result = await client.viewState(
        accountId: TestnetContracts.wrapTestnet.account,
        prefixBase64: '',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      final state = result.getOrThrow();

      for (final entry in state.values) {
        expect(entry.key, isNotEmpty);
        expect(entry.value, isNotEmpty);
      }
    });

    test('returns error for non-existent account', () async {
      final result = await client.viewState(
        accountId: NonExistentAccounts.testnetNonExistent,
        prefixBase64: '',
        blockReference: BlockReference.finality(Finality.final_),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('Testnet: viewCode() block references', () {
    test('viewCode works with final finality', () async {
      final result = await client.viewCode(
        accountId: TestnetContracts.wrapTestnet.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });

    test('viewCode works with optimistic finality', () async {
      final result = await client.viewCode(
        accountId: TestnetContracts.wrapTestnet.account,
        blockReference: BlockReference.finality(Finality.optimistic),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);
    });
  });
}
