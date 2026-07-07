import 'one_click_assets.dart';
import 'one_click_models.dart';

/// Defaults for building app-safe 1Click quote requests.
class OneClickQuoteDefaults {
  const OneClickQuoteDefaults({
    this.dry = true,
    this.slippageTolerance = 100,
    this.depositType = OneClickDepositType.originChain,
    this.refundType = OneClickRefundType.originChain,
    this.recipientType = OneClickRecipientType.intents,
    this.deadlineFromNow = const Duration(minutes: 5),
    this.connectedWallets = const [],
    this.appFees = const [],
    this.rebates = const [],
    this.referral,
    this.quoteWaitingTimeMs,
    this.insured,
  });

  /// Safe default for demos and previews. Set false only for live swaps.
  final bool dry;
  final int slippageTolerance;
  final OneClickDepositType depositType;
  final OneClickRefundType refundType;
  final OneClickRecipientType recipientType;
  final Duration deadlineFromNow;
  final List<String> connectedWallets;
  final List<OneClickAppFee> appFees;
  final List<OneClickRebate> rebates;
  final String? referral;
  final int? quoteWaitingTimeMs;
  final bool? insured;
}

/// Builder for common exact-input and exact-output 1Click quote requests.
class OneClickQuoteBuilder {
  const OneClickQuoteBuilder({this.defaults = const OneClickQuoteDefaults()});

  final OneClickQuoteDefaults defaults;

  /// Builds an exact-input quote request from a decimal user amount.
  OneClickQuoteRequest exactInput({
    required OneClickToken originToken,
    required OneClickToken destinationToken,
    required String amount,
    required String refundTo,
    required String recipient,
    bool? dry,
    int? slippageTolerance,
    OneClickDepositType? depositType,
    OneClickRefundType? refundType,
    OneClickRecipientType? recipientType,
    DateTime? deadline,
    OneClickDepositMode? depositMode,
    Map<String, dynamic> extra = const {},
  }) {
    return _build(
      swapType: OneClickSwapType.exactInput,
      originToken: originToken,
      destinationToken: destinationToken,
      amount: amount,
      amountDecimals: originToken.decimals,
      refundTo: refundTo,
      recipient: recipient,
      dry: dry,
      slippageTolerance: slippageTolerance,
      depositType: depositType,
      refundType: refundType,
      recipientType: recipientType,
      deadline: deadline,
      depositMode: depositMode,
      extra: extra,
    );
  }

  /// Builds an exact-output quote request from a decimal desired output.
  OneClickQuoteRequest exactOutput({
    required OneClickToken originToken,
    required OneClickToken destinationToken,
    required String amount,
    required String refundTo,
    required String recipient,
    bool? dry,
    int? slippageTolerance,
    OneClickDepositType? depositType,
    OneClickRefundType? refundType,
    OneClickRecipientType? recipientType,
    DateTime? deadline,
    OneClickDepositMode? depositMode,
    Map<String, dynamic> extra = const {},
  }) {
    return _build(
      swapType: OneClickSwapType.exactOutput,
      originToken: originToken,
      destinationToken: destinationToken,
      amount: amount,
      amountDecimals: destinationToken.decimals,
      refundTo: refundTo,
      recipient: recipient,
      dry: dry,
      slippageTolerance: slippageTolerance,
      depositType: depositType,
      refundType: refundType,
      recipientType: recipientType,
      deadline: deadline,
      depositMode: depositMode,
      extra: extra,
    );
  }

  OneClickQuoteRequest _build({
    required OneClickSwapType swapType,
    required OneClickToken originToken,
    required OneClickToken destinationToken,
    required String amount,
    required int amountDecimals,
    required String refundTo,
    required String recipient,
    bool? dry,
    int? slippageTolerance,
    OneClickDepositType? depositType,
    OneClickRefundType? refundType,
    OneClickRecipientType? recipientType,
    DateTime? deadline,
    OneClickDepositMode? depositMode,
    Map<String, dynamic> extra = const {},
  }) {
    return OneClickQuoteRequest(
      dry: dry ?? defaults.dry,
      swapType: swapType,
      slippageTolerance: slippageTolerance ?? defaults.slippageTolerance,
      originAsset: originToken.assetId,
      depositType: depositType ?? defaults.depositType,
      destinationAsset: destinationToken.assetId,
      amount: OneClickAmount.parseDecimal(amount, amountDecimals),
      refundTo: refundTo,
      refundType: refundType ?? defaults.refundType,
      recipient: recipient,
      recipientType: recipientType ?? defaults.recipientType,
      deadline:
          deadline ?? DateTime.now().toUtc().add(defaults.deadlineFromNow),
      depositMode: depositMode,
      connectedWallets: defaults.connectedWallets,
      referral: defaults.referral,
      rebates: defaults.rebates,
      quoteWaitingTimeMs: defaults.quoteWaitingTimeMs,
      appFees: defaults.appFees,
      insured: defaults.insured,
      extra: extra,
    );
  }
}
