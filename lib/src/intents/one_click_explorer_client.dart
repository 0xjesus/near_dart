import 'dart:convert';

import 'package:http/http.dart' as http;

import '../diagnostics/near_diagnostics.dart';
import '../diagnostics/near_errors.dart';
import 'one_click_auth.dart';
import 'one_click_models.dart';

/// Exception thrown when the NEAR Intents Explorer API returns non-2xx.
class OneClickExplorerApiException extends NearSdkException {
  OneClickExplorerApiException(this.statusCode, this.body)
    : super(
        code: _codeForExplorerHttpStatus(statusCode),
        message: 'Explorer API request failed with HTTP $statusCode',
        retryable: _isRetryableExplorerHttpStatus(statusCode),
      );

  final int statusCode;
  final String body;

  @override
  String toString() =>
      'OneClickExplorerApiException(statusCode: $statusCode, code: $code)';
}

/// Cursor direction for Explorer transaction pagination.
enum OneClickExplorerDirection {
  next('next'),
  prev('prev');

  const OneClickExplorerDirection(this.wireValue);

  final String wireValue;
}

/// Query filters for `GET /transactions` on the Explorer API.
class OneClickExplorerTransactionsRequest {
  OneClickExplorerTransactionsRequest({
    this.numberOfTransactions,
    this.lastDepositAddressAndMemo,
    this.lastDepositAddress,
    this.lastDepositMemo,
    this.direction,
    this.search,
    this.fromChainIds = const [],
    this.fromTokenIds = const [],
    this.toChainIds = const [],
    this.toTokenIds = const [],
    this.depositMemo,
    this.referral,
    this.affiliate,
    this.statuses = const [],
    this.showTestTxs,
    this.minUsdPrice,
    this.maxUsdPrice,
    this.startTimestamp,
    this.endTimestamp,
    this.startTimestampUnix,
    this.endTimestampUnix,
    this.extraQuery = const {},
  }) {
    final count = numberOfTransactions;
    if (count != null && (count < 1 || count > 1000)) {
      throw ArgumentError.value(
        count,
        'numberOfTransactions',
        'Must be between 1 and 1000',
      );
    }
  }

  final int? numberOfTransactions;
  final String? lastDepositAddressAndMemo;
  final String? lastDepositAddress;
  final String? lastDepositMemo;
  final OneClickExplorerDirection? direction;
  final String? search;
  final List<String> fromChainIds;
  final List<String> fromTokenIds;
  final List<String> toChainIds;
  final List<String> toTokenIds;
  final String? depositMemo;
  final String? referral;
  final String? affiliate;
  final List<OneClickStatusKind> statuses;
  final bool? showTestTxs;
  final num? minUsdPrice;
  final num? maxUsdPrice;
  final DateTime? startTimestamp;
  final DateTime? endTimestamp;
  final int? startTimestampUnix;
  final int? endTimestampUnix;

  /// Extra query parameters for upstream filters not modeled yet.
  final Map<String, List<String>> extraQuery;

  Map<String, List<String>> toQueryParametersAll() {
    final query = <String, List<String>>{
      for (final entry in extraQuery.entries) entry.key: [...entry.value],
    };

    void add(String key, Object? value) {
      if (value == null) return;
      query[key] = [value.toString()];
    }

    void addAll(String key, Iterable<String> values) {
      final list = values.where((value) => value.isNotEmpty).toList();
      if (list.isNotEmpty) query[key] = list;
    }

    add('numberOfTransactions', numberOfTransactions);
    add('lastDepositAddressAndMemo', lastDepositAddressAndMemo);
    add('lastDepositAddress', lastDepositAddress);
    add('lastDepositMemo', lastDepositMemo);
    add('direction', direction?.wireValue);
    add('search', search);
    addAll('fromChainId', fromChainIds);
    addAll('fromTokenId', fromTokenIds);
    addAll('toChainId', toChainIds);
    addAll('toTokenId', toTokenIds);
    add('depositMemo', depositMemo);
    add('referral', referral);
    add('affiliate', affiliate);
    if (statuses.isNotEmpty) {
      add('statuses', statuses.map((status) => status.wireValue).join(','));
    }
    add('showTestTxs', showTestTxs);
    add('minUsdPrice', minUsdPrice);
    add('maxUsdPrice', maxUsdPrice);
    add('startTimestamp', startTimestamp?.toUtc().toIso8601String());
    add('endTimestamp', endTimestamp?.toUtc().toIso8601String());
    add('startTimestampUnix', startTimestampUnix);
    add('endTimestampUnix', endTimestampUnix);
    return query;
  }
}

/// Historical 1Click swap transaction from the Explorer API.
class OneClickExplorerTransaction {
  const OneClickExplorerTransaction({
    required this.originAsset,
    required this.destinationAsset,
    required this.depositAddress,
    required this.recipient,
    required this.status,
    required this.statusKind,
    required this.appFees,
    required this.nearTxHashes,
    required this.originChainTxHashes,
    required this.destinationChainTxHashes,
    required this.senders,
    required this.raw,
    this.depositMemo,
    this.depositAddressAndMemo,
    this.createdAt,
    this.createdAtTimestamp,
    this.intentHashes,
    this.referral,
    this.amountInFormatted,
    this.amountOutFormatted,
    this.amountIn,
    this.amountInUsd,
    this.amountOut,
    this.amountOutUsd,
    this.refundTo,
    this.refundFeeFormatted,
    this.depositType,
    this.recipientType,
    this.refundType,
    this.refundReason,
    this.refundFee,
  });

  factory OneClickExplorerTransaction.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString();
    return OneClickExplorerTransaction(
      originAsset: json['originAsset'] as String,
      destinationAsset: json['destinationAsset'] as String,
      depositAddress: json['depositAddress'] as String,
      depositMemo: json['depositMemo'] as String?,
      depositAddressAndMemo: json['depositAddressAndMemo'] as String?,
      recipient: json['recipient'] as String,
      status: status,
      statusKind: OneClickStatusKind.fromWire(status),
      createdAt: _tryParseDate(json['createdAt']),
      createdAtTimestamp: (json['createdAtTimestamp'] as num?)?.toInt(),
      intentHashes: json['intentHashes'] as String?,
      referral: json['referral'] as String?,
      amountInFormatted: _readString(json, 'amountInFormatted'),
      amountOutFormatted: _readString(json, 'amountOutFormatted'),
      appFees: _appFees(json['appFees']),
      nearTxHashes: _stringList(json['nearTxHashes']),
      originChainTxHashes: _stringList(json['originChainTxHashes']),
      destinationChainTxHashes: _stringList(json['destinationChainTxHashes']),
      amountIn: _readString(json, 'amountIn'),
      amountInUsd: _readString(json, 'amountInUsd'),
      amountOut: _readString(json, 'amountOut'),
      amountOutUsd: _readString(json, 'amountOutUsd'),
      refundTo: json['refundTo'] as String?,
      senders: _stringList(json['senders']),
      refundFeeFormatted: _readString(json, 'refundFeeFormatted'),
      depositType: _depositTypeOrNull(json['depositType']),
      recipientType: _recipientTypeOrNull(json['recipientType']),
      refundType: _refundTypeOrNull(json['refundType']),
      refundReason: json['refundReason'] as String?,
      refundFee: _readString(json, 'refundFee'),
      raw: Map.unmodifiable(json),
    );
  }

  final String originAsset;
  final String destinationAsset;
  final String depositAddress;
  final String? depositMemo;
  final String? depositAddressAndMemo;
  final String recipient;
  final String status;
  final OneClickStatusKind statusKind;
  final DateTime? createdAt;
  final int? createdAtTimestamp;
  final String? intentHashes;
  final String? referral;
  final String? amountInFormatted;
  final String? amountOutFormatted;
  final List<OneClickAppFee> appFees;
  final List<String> nearTxHashes;
  final List<String> originChainTxHashes;
  final List<String> destinationChainTxHashes;
  final String? amountIn;
  final String? amountInUsd;
  final String? amountOut;
  final String? amountOutUsd;
  final String? refundTo;
  final List<String> senders;
  final String? refundFeeFormatted;
  final OneClickDepositType? depositType;
  final OneClickRecipientType? recipientType;
  final OneClickRefundType? refundType;
  final String? refundReason;
  final String? refundFee;

  /// Original API object for fields that are not modeled yet.
  final Map<String, dynamic> raw;
}

/// Read-only client for the NEAR Intents Explorer API.
class OneClickExplorerClient {
  OneClickExplorerClient({
    Uri? baseUri,
    OneClickAuth? auth,
    NearLogger? logger,
    http.Client? httpClient,
  }) : baseUri =
           baseUri ?? Uri.parse('https://explorer.near-intents.org/api/v0'),
       auth = auth,
       logger = logger,
       _http = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  /// Base API URI. Defaults to `https://explorer.near-intents.org/api/v0`.
  final Uri baseUri;

  /// JWT auth. Explorer requires `Authorization: Bearer ...` in production.
  final OneClickAuth? auth;

  /// Receives safe operational diagnostics for Explorer API requests.
  final NearLogger? logger;

  final http.Client _http;
  final bool _ownsHttpClient;

  /// Retrieves historical 1Click swap transactions.
  Future<List<OneClickExplorerTransaction>> transactions([
    OneClickExplorerTransactionsRequest? request,
  ]) async {
    const method = 'GET';
    const operation = '/transactions';
    final uri = _uri(operation, request?.toQueryParametersAll() ?? const {});
    final stopwatch = Stopwatch()..start();
    _emitRequestEvent(
      NearLogEventType.intentsRequestStarted,
      method: method,
      operation: operation,
      uri: uri,
      stopwatch: stopwatch,
    );

    http.Response? response;
    try {
      response = await _http.get(
        uri,
        headers: {'Accept': 'application/json', ...?auth?.headers},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OneClickExplorerApiException(response.statusCode, response.body);
      }
      final decoded = response.body.isEmpty
          ? const []
          : jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Expected Explorer transactions list');
      }
      final transactions = decoded
          .whereType<Map>()
          .map(
            (json) => OneClickExplorerTransaction.fromJson(
              json.cast<String, dynamic>(),
            ),
          )
          .toList();
      _emitRequestEvent(
        NearLogEventType.intentsRequestSucceeded,
        method: method,
        operation: operation,
        uri: uri,
        statusCode: response.statusCode,
        stopwatch: stopwatch,
      );
      return transactions;
    } catch (_) {
      _emitRequestEvent(
        NearLogEventType.intentsRequestFailed,
        method: method,
        operation: operation,
        uri: uri,
        statusCode: response?.statusCode,
        stopwatch: stopwatch,
      );
      rethrow;
    }
  }

  void _emitRequestEvent(
    NearLogEventType type, {
    required String method,
    required String operation,
    required Uri uri,
    required Stopwatch stopwatch,
    int? statusCode,
  }) {
    emitNearLog(
      logger,
      NearLogEvent(
        level: switch (type) {
          NearLogEventType.intentsRequestFailed => NearLogLevel.error,
          _ => NearLogLevel.info,
        },
        type: type,
        operation: operation,
        metadata: {
          'endpoint': uri.origin,
          'method': method,
          'operation': operation,
          'path': uri.path,
          if (statusCode != null) 'statusCode': statusCode,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      ),
    );
  }

  Uri _uri(String path, Map<String, List<String>> queryParametersAll) {
    final base = baseUri.toString().endsWith('/')
        ? baseUri
        : Uri.parse('${baseUri.toString()}/');
    final resolved = base.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    return queryParametersAll.isEmpty
        ? resolved
        : resolved.replace(query: _encodeQuery(queryParametersAll));
  }

  /// Closes the owned HTTP client.
  void close() {
    if (_ownsHttpClient) _http.close();
  }
}

NearErrorCode _codeForExplorerHttpStatus(int statusCode) {
  if (statusCode == 429) return NearErrorCode.rateLimited;
  if (statusCode >= 500) return NearErrorCode.rpcUnavailable;
  return NearErrorCode.invalidResponse;
}

bool _isRetryableExplorerHttpStatus(int statusCode) {
  return statusCode == 429 || statusCode >= 500;
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? null : value.toString();
}

List<String> _stringList(Object? value) =>
    (value as List? ?? const []).map((v) => v.toString()).toList();

List<OneClickAppFee> _appFees(Object? value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((m) => OneClickAppFee.fromJson(m.cast<String, dynamic>()))
    .toList();

OneClickDepositType? _depositTypeOrNull(Object? value) =>
    value is String ? OneClickDepositType.fromJson(value) : null;

OneClickRecipientType? _recipientTypeOrNull(Object? value) =>
    value is String ? OneClickRecipientType.fromJson(value) : null;

OneClickRefundType? _refundTypeOrNull(Object? value) =>
    value is String ? OneClickRefundType.fromJson(value) : null;

String _encodeQuery(Map<String, List<String>> values) {
  return [
    for (final entry in values.entries)
      for (final value in entry.value)
        '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}',
  ].join('&');
}
