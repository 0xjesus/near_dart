import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OneClickQuoteBuilder', () {
    const wnear = OneClickToken(
      assetId: 'nep141:wrap.near',
      decimals: 24,
      blockchain: 'near',
      symbol: 'wNEAR',
      raw: {},
    );
    const usdc = OneClickToken(
      assetId: 'nep141:usdc.near',
      decimals: 6,
      blockchain: 'near',
      symbol: 'USDC',
      raw: {},
    );

    test('builds exact-input quote requests from decimal user amounts', () {
      final deadline = DateTime.utc(2026, 7, 6, 12, 5);
      const builder = OneClickQuoteBuilder(
        defaults: OneClickQuoteDefaults(
          dry: false,
          slippageTolerance: 75,
          connectedWallets: ['alice.near'],
          referral: 'nearcoffee',
          appFees: [OneClickAppFee(recipient: 'nearcoffee.near', fee: 25)],
        ),
      );

      final request = builder.exactInput(
        originToken: wnear,
        destinationToken: usdc,
        amount: '0.1',
        refundTo: 'alice.near',
        recipient: 'alice.near',
        recipientType: OneClickRecipientType.intents,
        deadline: deadline,
      );

      expect(request.dry, isFalse);
      expect(request.swapType, OneClickSwapType.exactInput);
      expect(request.slippageTolerance, 75);
      expect(request.originAsset, 'nep141:wrap.near');
      expect(request.destinationAsset, 'nep141:usdc.near');
      expect(request.amount, '100000000000000000000000');
      expect(request.connectedWallets, ['alice.near']);
      expect(request.referral, 'nearcoffee');
      expect(request.appFees.single.fee, 25);
      expect(request.deadline, deadline);
    });

    test('builds exact-output requests using destination token decimals', () {
      final request = const OneClickQuoteBuilder().exactOutput(
        originToken: wnear,
        destinationToken: usdc,
        amount: '4.25',
        refundTo: 'alice.near',
        refundType: OneClickRefundType.intents,
        recipient: 'bob.near',
        recipientType: OneClickRecipientType.destinationChain,
        depositMode: OneClickDepositMode.memo,
        extra: {'partnerPayload': 'extra-kept'},
      );

      expect(request.dry, isTrue);
      expect(request.swapType, OneClickSwapType.exactOutput);
      expect(request.amount, '4250000');
      expect(request.refundType, OneClickRefundType.intents);
      expect(request.recipientType, OneClickRecipientType.destinationChain);
      expect(request.depositMode, OneClickDepositMode.memo);
      expect(request.toJson()['partnerPayload'], 'extra-kept');
    });
  });
}
