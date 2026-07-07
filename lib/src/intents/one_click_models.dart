/// Swap mode used by the NEAR Intents 1Click API.
enum OneClickSwapType {
  exactInput('EXACT_INPUT'),
  exactOutput('EXACT_OUTPUT'),
  flexInput('FLEX_INPUT'),
  anyInput('ANY_INPUT');

  const OneClickSwapType(this.wireValue);

  final String wireValue;

  factory OneClickSwapType.fromJson(String value) =>
      _enumFromWire(values, value, 'swap type');
}

/// Source of the deposit that funds a 1Click swap.
enum OneClickDepositType {
  originChain('ORIGIN_CHAIN'),
  intents('INTENTS'),
  confidentialIntents('CONFIDENTIAL_INTENTS');

  const OneClickDepositType(this.wireValue);

  final String wireValue;

  factory OneClickDepositType.fromJson(String value) =>
      _enumFromWire(values, value, 'deposit type');
}

/// Where 1Click sends refunds.
enum OneClickRefundType {
  originChain('ORIGIN_CHAIN'),
  intents('INTENTS'),
  confidentialIntents('CONFIDENTIAL_INTENTS');

  const OneClickRefundType(this.wireValue);

  final String wireValue;

  factory OneClickRefundType.fromJson(String value) =>
      _enumFromWire(values, value, 'refund type');
}

/// Where 1Click sends swap output.
enum OneClickRecipientType {
  destinationChain('DESTINATION_CHAIN'),
  intents('INTENTS'),
  confidentialIntents('CONFIDENTIAL_INTENTS');

  const OneClickRecipientType(this.wireValue);

  final String wireValue;

  factory OneClickRecipientType.fromJson(String value) =>
      _enumFromWire(values, value, 'recipient type');
}

/// Deposit-address mode returned by 1Click.
enum OneClickDepositMode {
  simple('SIMPLE'),
  memo('MEMO');

  const OneClickDepositMode(this.wireValue);

  final String wireValue;

  factory OneClickDepositMode.fromJson(String value) =>
      _enumFromWire(values, value, 'deposit mode');
}

/// Confidentiality setting for invite-only 1Click flows.
enum OneClickConfidentiality {
  public('public'),
  basic('basic'),
  advanced('advanced');

  const OneClickConfidentiality(this.wireValue);

  final String wireValue;

  factory OneClickConfidentiality.fromJson(String value) =>
      _enumFromWire(values, value, 'confidentiality');
}

/// Sort order for paginated 1Click endpoints.
enum OneClickSortOrder {
  asc('asc'),
  desc('desc');

  const OneClickSortOrder(this.wireValue);

  final String wireValue;
}

/// A token supported by the NEAR Intents 1Click API.
class OneClickToken {
  const OneClickToken({
    required this.assetId,
    required this.decimals,
    required this.blockchain,
    required this.symbol,
    required this.raw,
    this.contractAddress,
    this.price,
    this.priceUpdatedAt,
  });

  factory OneClickToken.fromJson(Map<String, dynamic> json) {
    return OneClickToken(
      assetId: json['assetId'] as String,
      decimals: json['decimals'] as int,
      blockchain: json['blockchain'] as String,
      symbol: json['symbol'] as String,
      contractAddress: json['contractAddress'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      priceUpdatedAt: _tryParseDate(json['priceUpdatedAt']),
      raw: Map.unmodifiable(json),
    );
  }

  final String assetId;
  final int decimals;
  final String blockchain;
  final String symbol;
  final String? contractAddress;
  final double? price;
  final DateTime? priceUpdatedAt;

  /// Original API object for fields that are not modeled yet.
  final Map<String, dynamic> raw;
}

/// App fee configuration for distribution-channel quotes.
class OneClickAppFee {
  const OneClickAppFee({required this.recipient, required this.fee});

  factory OneClickAppFee.fromJson(Map<String, dynamic> json) {
    return OneClickAppFee(
      recipient: json['recipient'] as String,
      fee: (json['fee'] as num).toInt(),
    );
  }

  /// Fee recipient address.
  final String recipient;

  /// Fee in basis points. `100` means 1%.
  final int fee;

  Map<String, dynamic> toJson() => {'recipient': recipient, 'fee': fee};
}

/// Rebate split configuration for 1Click quotes.
class OneClickRebate {
  const OneClickRebate({required this.recipient, required this.share});

  final String recipient;
  final int share;

  Map<String, dynamic> toJson() => {'recipient': recipient, 'share': share};
}

/// Request body for `POST /v0/quote`.
class OneClickQuoteRequest {
  const OneClickQuoteRequest({
    required this.dry,
    required this.swapType,
    required this.slippageTolerance,
    required this.originAsset,
    required this.depositType,
    required this.destinationAsset,
    required this.amount,
    required this.refundTo,
    required this.refundType,
    required this.recipient,
    required this.recipientType,
    required this.deadline,
    this.depositMode,
    this.connectedWallets = const [],
    this.sessionId,
    this.virtualChainRecipient,
    this.virtualChainRefundRecipient,
    this.customRecipientMsg,
    this.confidentiality,
    this.referral,
    this.rebates = const [],
    this.quoteWaitingTimeMs,
    this.appFees = const [],
    this.insured,
    this.extra = const {},
  });

  /// Use `true` for previews: no deposit address is created.
  final bool dry;

  final OneClickSwapType swapType;

  /// Slippage tolerance in basis points. `100` means 1%.
  final int slippageTolerance;

  final String originAsset;
  final OneClickDepositType depositType;
  final String destinationAsset;

  /// Amount in smallest units. Decimal strings are invalid upstream.
  final String amount;

  final String refundTo;
  final OneClickRefundType refundType;
  final String recipient;
  final OneClickRecipientType recipientType;
  final DateTime deadline;
  final OneClickDepositMode? depositMode;
  final List<String> connectedWallets;
  final String? sessionId;
  final String? virtualChainRecipient;
  final String? virtualChainRefundRecipient;
  final String? customRecipientMsg;
  final OneClickConfidentiality? confidentiality;
  final String? referral;
  final List<OneClickRebate> rebates;
  final int? quoteWaitingTimeMs;
  final List<OneClickAppFee> appFees;
  final bool? insured;

  /// Additional upstream fields not modeled by this SDK version.
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => _withoutNulls({
    ...extra,
    'dry': dry,
    'swapType': swapType.wireValue,
    'slippageTolerance': slippageTolerance,
    'originAsset': originAsset,
    'depositType': depositType.wireValue,
    'destinationAsset': destinationAsset,
    'amount': amount,
    'refundTo': refundTo,
    'refundType': refundType.wireValue,
    'recipient': recipient,
    'recipientType': recipientType.wireValue,
    'deadline': deadline.toUtc().toIso8601String(),
    'depositMode': depositMode?.wireValue,
    if (connectedWallets.isNotEmpty) 'connectedWallets': connectedWallets,
    'sessionId': sessionId,
    'virtualChainRecipient': virtualChainRecipient,
    'virtualChainRefundRecipient': virtualChainRefundRecipient,
    'customRecipientMsg': customRecipientMsg,
    'confidentiality': confidentiality?.wireValue,
    'referral': referral,
    if (rebates.isNotEmpty) 'rebates': rebates.map((r) => r.toJson()).toList(),
    'quoteWaitingTimeMs': quoteWaitingTimeMs,
    if (appFees.isNotEmpty) 'appFees': appFees.map((f) => f.toJson()).toList(),
    'insured': insured,
  });
}

/// Full response from `POST /v0/quote`.
class OneClickQuoteResponse {
  const OneClickQuoteResponse({
    required this.correlationId,
    required this.quote,
    required this.raw,
    this.timestamp,
    this.signature,
    this.quoteRequest,
  });

  factory OneClickQuoteResponse.fromJson(Map<String, dynamic> json) {
    return OneClickQuoteResponse(
      correlationId: (json['correlationId'] ?? '').toString(),
      timestamp: _tryParseDate(json['timestamp']),
      signature: json['signature'] as String?,
      quoteRequest: _objectOrNull(json['quoteRequest']),
      quote: OneClickQuote.fromJson(_requiredObject(json, 'quote')),
      raw: Map.unmodifiable(json),
    );
  }

  final String correlationId;
  final DateTime? timestamp;
  final String? signature;
  final Map<String, dynamic>? quoteRequest;
  final OneClickQuote quote;

  /// Original API response for fields that are not modeled yet.
  final Map<String, dynamic> raw;
}

/// Chain-specific deposit address returned by quote responses.
class OneClickChainDepositAddress {
  const OneClickChainDepositAddress({
    required this.blockchain,
    required this.address,
    required this.raw,
    this.memo,
  });

  factory OneClickChainDepositAddress.fromJson(Map<String, dynamic> json) {
    return OneClickChainDepositAddress(
      blockchain: json['blockchain'] as String,
      address: json['address'] as String,
      memo: json['memo'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final String blockchain;
  final String address;
  final String? memo;
  final Map<String, dynamic> raw;
}

/// Quote details inside a 1Click quote or status response.
class OneClickQuote {
  const OneClickQuote({
    required this.raw,
    this.depositAddress,
    this.depositMemo,
    this.amountIn,
    this.amountInFormatted,
    this.amountInUsd,
    this.minAmountIn,
    this.amountOut,
    this.amountOutFormatted,
    this.amountOutUsd,
    this.minAmountOut,
    this.timeEstimate,
    this.deadline,
    this.timeWhenInactive,
    this.virtualChainRecipient,
    this.virtualChainRefundRecipient,
    this.customRecipientMsg,
    this.refundFee,
    this.withdrawFee,
    this.chainDepositAddresses = const [],
  });

  factory OneClickQuote.fromJson(Map<String, dynamic> json) {
    return OneClickQuote(
      depositAddress: json['depositAddress'] as String?,
      depositMemo: json['depositMemo'] as String?,
      amountIn: _readString(json, 'amountIn'),
      amountInFormatted: _readString(json, 'amountInFormatted'),
      amountInUsd: _readString(json, 'amountInUsd'),
      minAmountIn: _readString(json, 'minAmountIn'),
      amountOut: _readString(json, 'amountOut'),
      amountOutFormatted: _readString(json, 'amountOutFormatted'),
      amountOutUsd: _readString(json, 'amountOutUsd'),
      minAmountOut: _readString(json, 'minAmountOut'),
      timeEstimate: (json['timeEstimate'] as num?)?.toInt(),
      deadline: _tryParseDate(json['deadline']),
      timeWhenInactive: _tryParseDate(json['timeWhenInactive']),
      virtualChainRecipient: json['virtualChainRecipient'] as String?,
      virtualChainRefundRecipient:
          json['virtualChainRefundRecipient'] as String?,
      customRecipientMsg: json['customRecipientMsg'] as String?,
      refundFee: _readString(json, 'refundFee'),
      withdrawFee: _readString(json, 'withdrawFee'),
      chainDepositAddresses:
          (json['chainDepositAddresses'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (m) => OneClickChainDepositAddress.fromJson(
                  m.cast<String, dynamic>(),
                ),
              )
              .toList(),
      raw: Map.unmodifiable(json),
    );
  }

  final String? depositAddress;
  final String? depositMemo;
  final String? amountIn;
  final String? amountInFormatted;
  final String? amountInUsd;
  final String? minAmountIn;
  final String? amountOut;
  final String? amountOutFormatted;
  final String? amountOutUsd;
  final String? minAmountOut;
  final int? timeEstimate;
  final DateTime? deadline;
  final DateTime? timeWhenInactive;
  final String? virtualChainRecipient;
  final String? virtualChainRefundRecipient;
  final String? customRecipientMsg;
  final String? refundFee;
  final String? withdrawFee;
  final List<OneClickChainDepositAddress> chainDepositAddresses;

  /// Original API response for fields that are not modeled yet.
  final Map<String, dynamic> raw;
}

/// Known status categories returned by `GET /v0/status`.
enum OneClickStatusKind {
  pendingDeposit('PENDING_DEPOSIT'),
  knownDepositTx('KNOWN_DEPOSIT_TX'),
  processing('PROCESSING'),
  success('SUCCESS'),
  incompleteDeposit('INCOMPLETE_DEPOSIT'),
  refunded('REFUNDED'),
  failed('FAILED'),
  unknown('UNKNOWN');

  const OneClickStatusKind(this.wireValue);

  final String wireValue;

  factory OneClickStatusKind.fromWire(String status) {
    for (final kind in values) {
      if (kind.wireValue == status) return kind;
    }
    return unknown;
  }

  bool get isTerminal {
    switch (this) {
      case OneClickStatusKind.success:
      case OneClickStatusKind.refunded:
      case OneClickStatusKind.failed:
      case OneClickStatusKind.incompleteDeposit:
        return true;
      case OneClickStatusKind.pendingDeposit:
      case OneClickStatusKind.knownDepositTx:
      case OneClickStatusKind.processing:
      case OneClickStatusKind.unknown:
        return false;
    }
  }
}

/// Transaction hash and explorer URL from a status response.
class OneClickTxHash {
  const OneClickTxHash({
    required this.hash,
    required this.raw,
    this.explorerUrl,
  });

  factory OneClickTxHash.fromJson(Map<String, dynamic> json) {
    return OneClickTxHash(
      hash: json['hash'] as String,
      explorerUrl: json['explorerUrl'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final String hash;
  final String? explorerUrl;
  final Map<String, dynamic> raw;
}

/// Swap execution details included in `GET /v0/status`.
class OneClickSwapDetails {
  const OneClickSwapDetails({
    required this.raw,
    this.intentHashes = const [],
    this.nearTxHashes = const [],
    this.originChainTxHashes = const [],
    this.destinationChainTxHashes = const [],
    this.amountIn,
    this.amountInFormatted,
    this.amountInUsd,
    this.amountOut,
    this.amountOutFormatted,
    this.amountOutUsd,
    this.slippage,
    this.refundedAmount,
    this.refundReason,
    this.depositedAmount,
    this.withdrawFee,
    this.referral,
  });

  factory OneClickSwapDetails.fromJson(Map<String, dynamic> json) {
    return OneClickSwapDetails(
      intentHashes: _stringList(json['intentHashes']),
      nearTxHashes: _stringList(json['nearTxHashes']),
      originChainTxHashes: _txHashes(json['originChainTxHashes']),
      destinationChainTxHashes: _txHashes(json['destinationChainTxHashes']),
      amountIn: _readString(json, 'amountIn'),
      amountInFormatted: _readString(json, 'amountInFormatted'),
      amountInUsd: _readString(json, 'amountInUsd'),
      amountOut: _readString(json, 'amountOut'),
      amountOutFormatted: _readString(json, 'amountOutFormatted'),
      amountOutUsd: _readString(json, 'amountOutUsd'),
      slippage: (json['slippage'] as num?)?.toInt(),
      refundedAmount: _readString(json, 'refundedAmount'),
      refundReason: json['refundReason'] as String?,
      depositedAmount: _readString(json, 'depositedAmount'),
      withdrawFee: _readString(json, 'withdrawFee'),
      referral: json['referral'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final List<String> intentHashes;
  final List<String> nearTxHashes;
  final List<OneClickTxHash> originChainTxHashes;
  final List<OneClickTxHash> destinationChainTxHashes;
  final String? amountIn;
  final String? amountInFormatted;
  final String? amountInUsd;
  final String? amountOut;
  final String? amountOutFormatted;
  final String? amountOutUsd;
  final int? slippage;
  final String? refundedAmount;
  final String? refundReason;
  final String? depositedAmount;
  final String? withdrawFee;
  final String? referral;
  final Map<String, dynamic> raw;
}

/// Response from `GET /v0/status`.
class OneClickStatus {
  const OneClickStatus({
    required this.correlationId,
    required this.status,
    required this.kind,
    required this.raw,
    this.quoteResponse,
    this.updatedAt,
    this.swapDetails,
  });

  factory OneClickStatus.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString();
    final quoteResponseJson = _objectOrNull(json['quoteResponse']);
    final swapDetailsJson = _objectOrNull(json['swapDetails']);
    return OneClickStatus(
      correlationId: (json['correlationId'] ?? '').toString(),
      status: status,
      kind: _statusKind(status),
      quoteResponse: quoteResponseJson == null
          ? null
          : OneClickQuoteResponse.fromJson(quoteResponseJson),
      updatedAt: _tryParseDate(json['updatedAt']),
      swapDetails: swapDetailsJson == null
          ? null
          : OneClickSwapDetails.fromJson(swapDetailsJson),
      raw: Map.unmodifiable(json),
    );
  }

  final String correlationId;

  /// Raw upstream status, for example `SUCCESS`.
  final String status;

  /// Normalized status kind for app logic.
  final OneClickStatusKind kind;
  final OneClickQuoteResponse? quoteResponse;
  final DateTime? updatedAt;
  final OneClickSwapDetails? swapDetails;

  /// Original API response for fields that are not modeled yet.
  final Map<String, dynamic> raw;
}

/// Response from `GET /v0/any-input/withdrawals`.
class OneClickAnyInputWithdrawals {
  const OneClickAnyInputWithdrawals({
    required this.asset,
    required this.recipient,
    required this.affiliateRecipient,
    required this.raw,
    this.withdrawals,
  });

  factory OneClickAnyInputWithdrawals.fromJson(Map<String, dynamic> json) {
    final withdrawalsJson = _objectOrNull(json['withdrawals']);
    return OneClickAnyInputWithdrawals(
      asset: json['asset'] as String,
      recipient: json['recipient'] as String,
      affiliateRecipient: json['affiliateRecipient'] as String,
      withdrawals: withdrawalsJson == null
          ? null
          : OneClickWithdrawal.fromJson(withdrawalsJson),
      raw: Map.unmodifiable(json),
    );
  }

  final String asset;
  final String recipient;
  final String affiliateRecipient;
  final OneClickWithdrawal? withdrawals;
  final Map<String, dynamic> raw;
}

/// A single ANY_INPUT withdrawal summary.
class OneClickWithdrawal {
  const OneClickWithdrawal({
    required this.raw,
    this.amountOut,
    this.amountOutFormatted,
    this.amountOutUsd,
    this.withdrawFee,
    this.withdrawFeeFormatted,
    this.withdrawFeeUsd,
    this.timestamp,
    this.hash,
  });

  factory OneClickWithdrawal.fromJson(Map<String, dynamic> json) {
    return OneClickWithdrawal(
      amountOut: _readString(json, 'amountOut'),
      amountOutFormatted: _readString(json, 'amountOutFormatted'),
      amountOutUsd: _readString(json, 'amountOutUsd'),
      withdrawFee: _readString(json, 'withdrawFee'),
      withdrawFeeFormatted: _readString(json, 'withdrawFeeFormatted'),
      withdrawFeeUsd: _readString(json, 'withdrawFeeUsd'),
      timestamp: _tryParseDate(json['timestamp']),
      hash: json['hash'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final String? amountOut;
  final String? amountOutFormatted;
  final String? amountOutUsd;
  final String? withdrawFee;
  final String? withdrawFeeFormatted;
  final String? withdrawFeeUsd;
  final DateTime? timestamp;
  final String? hash;
  final Map<String, dynamic> raw;
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? null : value.toString();
}

Map<String, dynamic>? _objectOrNull(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('Expected object, got ${value.runtimeType}');
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) {
  final value = _objectOrNull(json[key]);
  if (value == null) throw FormatException('Expected $key object');
  return value;
}

List<String> _stringList(Object? value) =>
    (value as List? ?? const []).map((v) => v.toString()).toList();

List<OneClickTxHash> _txHashes(Object? value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((m) => OneClickTxHash.fromJson(m.cast<String, dynamic>()))
    .toList();

Map<String, dynamic> _withoutNulls(Map<String, dynamic> json) {
  return {
    for (final entry in json.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}

OneClickStatusKind _statusKind(String status) {
  return OneClickStatusKind.fromWire(status);
}

T _enumFromWire<T>(List<T> values, String value, String label) {
  for (final candidate in values) {
    final wireValue = (candidate as dynamic).wireValue as String;
    if (wireValue == value) return candidate;
  }
  throw ArgumentError.value(value, 'value', 'Unsupported $label');
}
