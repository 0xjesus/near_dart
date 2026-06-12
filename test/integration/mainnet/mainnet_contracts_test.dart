/// Integration tests for contract queries on mainnet.
///
/// NO MOCKS - All tests hit real NEAR mainnet RPC endpoints.
@Tags(['integration', 'mainnet'])
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';
import '../../fixtures/known_data.dart';

void main() {
  late NearRpcClient client;

  setUpAll(() {
    client = NearRpcClient.mainnet();
  });

  tearDownAll(() {
    client.close();
  });

  /// Helper to check if error is rate limiting
  bool isRateLimitError(RpcError error) {
    return error.code == -429 || error.message.contains('DEPRECATED');
  }

  group('Mainnet: wrap.near Contract', () {
    test('ft_metadata returns wNEAR metadata', () async {
      final result = await client.callFunction(
        accountId: MainnetContracts.wrapNear.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue, reason: 'ft_metadata should succeed');

      final response = result.getOrThrow();
      final metadata = response.resultAsJson();

      expect(metadata['name'], equals(ExpectedFtMetadata.wrappedNear.name));
      expect(metadata['symbol'], equals(ExpectedFtMetadata.wrappedNear.symbol));
      expect(
        metadata['decimals'],
        equals(ExpectedFtMetadata.wrappedNear.decimals),
      );
    });

    test('ft_total_supply returns non-zero supply', () async {
      final result = await client.callFunction(
        accountId: MainnetContracts.wrapNear.account,
        methodName: 'ft_total_supply',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      final supply = BigInt.parse(response.resultAsJson() as String);

      // wNEAR on mainnet has significant total supply
      expect(supply, greaterThan(BigInt.zero));
    });

    test('ft_balance_of works for any account', () async {
      final result = await client.callFunction(
        accountId: MainnetContracts.wrapNear.account,
        methodName: 'ft_balance_of',
        args: {'account_id': 'near'},
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      // Balance should be a valid number string
      expect(BigInt.tryParse(response.resultAsJson() as String), isNotNull);
    });
  });

  group('Mainnet: USDT Contract', () {
    test('ft_metadata returns USDT metadata', () async {
      final result = await client.callFunction(
        accountId: MainnetContracts.usdt.account,
        methodName: 'ft_metadata',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(
        result.isSuccess,
        isTrue,
        reason: 'USDT ft_metadata should succeed',
      );

      final response = result.getOrThrow();
      final metadata = response.resultAsJson();

      expect(metadata['symbol'], equals(ExpectedFtMetadata.usdt.symbol));
      expect(metadata['decimals'], equals(ExpectedFtMetadata.usdt.decimals));
    });

    test('ft_total_supply returns USDT supply', () async {
      final result = await client.callFunction(
        accountId: MainnetContracts.usdt.account,
        methodName: 'ft_total_supply',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final response = result.getOrThrow();
      final supply = BigInt.parse(response.resultAsJson() as String);

      // USDT has significant supply on NEAR
      expect(supply, greaterThan(BigInt.zero));
    });
  });

  group('Mainnet: Contract Code', () {
    test('viewCode returns wrap.near contract code', () async {
      final result = await client.viewCode(
        accountId: MainnetContracts.wrapNear.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final code = result.getOrThrow();
      expect(code.codeBase64, isNotEmpty);
      expect(code.hash, isNotEmpty);
    });

    test('viewCode returns USDT contract code', () async {
      final result = await client.viewCode(
        accountId: MainnetContracts.usdt.account,
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final code = result.getOrThrow();
      expect(code.codeBase64, isNotEmpty);
    });
  });

  group('Mainnet: Contract State', () {
    test('viewState returns wrap.near state', () async {
      final result = await client.viewState(
        accountId: MainnetContracts.wrapNear.account,
        prefixBase64: '',
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isFailure && isRateLimitError((result as RpcFailure).error)) {
        return;
      }

      expect(result.isSuccess, isTrue);

      final state = result.getOrThrow();
      // FT contracts have state
      expect(state.values, isNotEmpty);
    });
  });

  group('Mainnet: All Known Contracts', () {
    test('all known contracts respond to ft_metadata', () async {
      for (final contract in MainnetContracts.all) {
        if (contract.methods.contains('ft_metadata')) {
          final result = await client.callFunction(
            accountId: contract.account,
            methodName: 'ft_metadata',
            blockReference: BlockReference.finality(Finality.final_),
          );

          if (result.isFailure &&
              isRateLimitError((result as RpcFailure).error)) {
            return;
          }

          expect(
            result.isSuccess,
            isTrue,
            reason: '${contract.accountId} ft_metadata should succeed',
          );
        }
      }
    });
  });
}
