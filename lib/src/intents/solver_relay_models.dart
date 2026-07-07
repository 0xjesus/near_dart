import 'intent_signing.dart';

/// Quote request for the NEAR Intents Message Bus solver relay.
class SolverRelayQuoteRequest {
  const SolverRelayQuoteRequest({
    required this.defuseAssetIdentifierIn,
    required this.defuseAssetIdentifierOut,
    this.exactAmountIn,
    this.exactAmountOut,
    this.minDeadlineMs,
    this.extra = const {},
  });

  final String defuseAssetIdentifierIn;
  final String defuseAssetIdentifierOut;
  final String? exactAmountIn;
  final String? exactAmountOut;
  final int? minDeadlineMs;

  /// Extra JSON-RPC params for upstream fields not modeled yet.
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() {
    if ((exactAmountIn == null) == (exactAmountOut == null)) {
      throw StateError(
        'Exactly one of exactAmountIn or exactAmountOut is required',
      );
    }
    return {
      ...extra,
      'defuse_asset_identifier_in': defuseAssetIdentifierIn,
      'defuse_asset_identifier_out': defuseAssetIdentifierOut,
      if (exactAmountIn != null) 'exact_amount_in': exactAmountIn,
      if (exactAmountOut != null) 'exact_amount_out': exactAmountOut,
      if (minDeadlineMs != null) 'min_deadline_ms': minDeadlineMs,
    };
  }
}

/// A solver quote returned by the Message Bus.
class SolverRelayQuote {
  const SolverRelayQuote({
    required this.quoteHash,
    required this.defuseAssetIdentifierIn,
    required this.defuseAssetIdentifierOut,
    required this.amountIn,
    required this.amountOut,
    required this.raw,
    this.expirationTime,
  });

  factory SolverRelayQuote.fromJson(Map<String, dynamic> json) {
    return SolverRelayQuote(
      quoteHash: json['quote_hash'] as String,
      defuseAssetIdentifierIn: json['defuse_asset_identifier_in'] as String,
      defuseAssetIdentifierOut: json['defuse_asset_identifier_out'] as String,
      amountIn: json['amount_in'].toString(),
      amountOut: json['amount_out'].toString(),
      expirationTime: _tryParseDate(json['expiration_time']),
      raw: Map.unmodifiable(json),
    );
  }

  final String quoteHash;
  final String defuseAssetIdentifierIn;
  final String defuseAssetIdentifierOut;
  final String amountIn;
  final String amountOut;
  final DateTime? expirationTime;
  final Map<String, dynamic> raw;
}

/// Response from Message Bus `publish_intent`.
class SolverRelayPublishIntentResponse {
  const SolverRelayPublishIntentResponse({
    required this.status,
    required this.raw,
    this.intentHash,
    this.reason,
  });

  factory SolverRelayPublishIntentResponse.fromJson(Map<String, dynamic> json) {
    return SolverRelayPublishIntentResponse(
      status: json['status'] as String,
      intentHash: json['intent_hash'] as String?,
      reason: json['reason'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  final String status;
  final String? intentHash;
  final String? reason;
  final Map<String, dynamic> raw;
}

/// Known Message Bus intent execution states.
enum SolverRelayIntentStatusKind {
  pending,
  txBroadcasted,
  settled,
  notFoundOrNotValid,
  unknown,
}

/// Response from Message Bus `get_status`.
class SolverRelayIntentStatus {
  const SolverRelayIntentStatus({
    required this.intentHash,
    required this.status,
    required this.kind,
    required this.raw,
    this.data,
  });

  factory SolverRelayIntentStatus.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    final data = json['data'];
    return SolverRelayIntentStatus(
      intentHash: json['intent_hash'] as String,
      status: status,
      kind: _statusKind(status),
      data: data is Map ? data.cast<String, dynamic>() : null,
      raw: Map.unmodifiable(json),
    );
  }

  final String intentHash;
  final String status;
  final SolverRelayIntentStatusKind kind;
  final Map<String, dynamic>? data;
  final Map<String, dynamic> raw;

  String? get nearTransactionHash => data?['hash'] as String?;
}

/// Signed intent publish request for the Message Bus.
class SolverRelayPublishIntentRequest {
  const SolverRelayPublishIntentRequest({
    required this.quoteHashes,
    required this.signedData,
  });

  final List<String> quoteHashes;
  final SignedMultiPayload signedData;

  Map<String, dynamic> toJson() => {
    'quote_hashes': quoteHashes,
    'signed_data': signedData.toJson(),
  };
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

SolverRelayIntentStatusKind _statusKind(String status) {
  switch (status) {
    case 'PENDING':
      return SolverRelayIntentStatusKind.pending;
    case 'TX_BROADCASTED':
      return SolverRelayIntentStatusKind.txBroadcasted;
    case 'SETTLED':
      return SolverRelayIntentStatusKind.settled;
    case 'NOT_FOUND_OR_NOT_VALID':
      return SolverRelayIntentStatusKind.notFoundOrNotValid;
    default:
      return SolverRelayIntentStatusKind.unknown;
  }
}
