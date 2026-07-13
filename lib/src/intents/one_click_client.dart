import 'dart:convert';

import 'package:http/http.dart' as http;

import '../diagnostics/near_diagnostics.dart';
import '../diagnostics/near_errors.dart';
import 'intent_signing.dart';
import 'one_click_auth.dart';
import 'one_click_models.dart';

/// Exception thrown when the 1Click API returns a non-2xx response.
class OneClickApiException extends NearSdkException {
  OneClickApiException(this.statusCode, this.body)
    : super(
        code: _codeForHttpStatus(statusCode),
        message: '1Click API request failed with HTTP $statusCode',
        retryable: _isRetryableHttpStatus(statusCode),
      );

  final int statusCode;
  final String body;

  @override
  String toString() =>
      'OneClickApiException(statusCode: $statusCode, code: $code)';
}

/// REST client for the NEAR Intents 1Click API.
class OneClickClient {
  OneClickClient({
    Uri? baseUri,
    OneClickAuth? auth,
    NearLogger? logger,
    http.Client? httpClient,
  }) : baseUri = baseUri ?? Uri.parse('https://1click.chaindefuser.com'),
       auth = auth,
       logger = logger,
       _http = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  /// Base API URI. Defaults to `https://1click.chaindefuser.com`.
  final Uri baseUri;

  /// Optional partner auth.
  final OneClickAuth? auth;

  /// Receives safe operational diagnostics for 1Click requests.
  final NearLogger? logger;

  final http.Client _http;
  final bool _ownsHttpClient;

  /// Lists tokens supported by the 1Click API.
  Future<List<OneClickToken>> tokens() async {
    final json = await _request('GET', '/v0/tokens');
    if (json is! List) {
      throw const FormatException('Expected token list response');
    }
    return json
        .cast<Map<String, dynamic>>()
        .map(OneClickToken.fromJson)
        .toList();
  }

  /// Requests a swap quote.
  Future<OneClickQuoteResponse> quote(OneClickQuoteRequest request) async {
    final json = await _request('POST', '/v0/quote', body: request.toJson());
    return OneClickQuoteResponse.fromJson(_asObject(json, 'quote response'));
  }

  /// Notifies 1Click about an origin-chain deposit transaction.
  Future<void> submitDeposit({
    required String depositAddress,
    required String txHash,
    String? nearSenderAccount,
    String? memo,
  }) async {
    await _request(
      'POST',
      '/v0/deposit/submit',
      body: {
        'depositAddress': depositAddress,
        'txHash': txHash,
        if (nearSenderAccount != null) 'nearSenderAccount': nearSenderAccount,
        if (memo != null) 'memo': memo,
      },
    );
  }

  /// Checks swap execution status.
  Future<OneClickStatus> status({
    required String depositAddress,
    String? depositMemo,
  }) async {
    final json = await _request(
      'GET',
      '/v0/status',
      query: {
        'depositAddress': depositAddress,
        if (depositMemo != null) 'depositMemo': depositMemo,
      },
    );
    return OneClickStatus.fromJson(_asObject(json, 'status response'));
  }

  /// Generates an unsigned intent for wallet signing.
  Future<GeneratedIntent> generateIntent({
    required String depositAddress,
    required String signerId,
    required IntentSigningStandard standard,
    String type = 'swap_transfer',
  }) async {
    final json = await _request(
      'POST',
      '/v0/generate-intent',
      body: {
        'type': type,
        'depositAddress': depositAddress,
        'signerId': signerId,
        'standard': standard.wireValue,
      },
    );
    return GeneratedIntent.fromJson(_asObject(json, 'generated intent'));
  }

  /// Lists withdrawals produced by an ANY_INPUT quote.
  Future<OneClickAnyInputWithdrawals> anyInputWithdrawals({
    required String depositAddress,
    String? depositMemo,
    DateTime? timestampFrom,
    int? page,
    int? limit,
    OneClickSortOrder? sortOrder,
  }) async {
    final json = await _request(
      'GET',
      '/v0/any-input/withdrawals',
      query: {
        'depositAddress': depositAddress,
        if (depositMemo != null) 'depositMemo': depositMemo,
        if (timestampFrom != null)
          'timestampFrom': timestampFrom.toUtc().toIso8601String(),
        if (page != null) 'page': '$page',
        if (limit != null) 'limit': '$limit',
        if (sortOrder != null) 'sortOrder': sortOrder.wireValue,
      },
    );
    return OneClickAnyInputWithdrawals.fromJson(
      _asObject(json, 'ANY_INPUT withdrawals response'),
    );
  }

  /// Submits a signed intent payload.
  Future<SubmitIntentResponse> submitIntent({
    required String type,
    required SignedMultiPayload signedData,
    Map<String, dynamic> extra = const {},
  }) async {
    final json = await _request(
      'POST',
      '/v0/submit-intent',
      body: {...extra, 'type': type, 'signedData': signedData.toJson()},
    );
    return SubmitIntentResponse.fromJson(
      _asObject(json, 'submit intent response'),
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path, query);
    final stopwatch = Stopwatch()..start();
    _emitRequestEvent(
      NearLogEventType.intentsRequestStarted,
      method: method,
      operation: path,
      uri: uri,
      stopwatch: stopwatch,
    );

    http.Response? response;
    try {
      response = await _send(method, uri, body: body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OneClickApiException(response.statusCode, response.body);
      }
      final result = response.body.isEmpty ? null : jsonDecode(response.body);
      _emitRequestEvent(
        NearLogEventType.intentsRequestSucceeded,
        method: method,
        operation: path,
        uri: uri,
        statusCode: response.statusCode,
        stopwatch: stopwatch,
      );
      return result;
    } catch (_) {
      _emitRequestEvent(
        NearLogEventType.intentsRequestFailed,
        method: method,
        operation: path,
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

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) {
    final headers = {
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...?auth?.headers,
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encodedBody);
      default:
        throw ArgumentError.value(method, 'method', 'Unsupported method');
    }
  }

  Uri _uri(String path, Map<String, String>? query) {
    final base = baseUri.toString().endsWith('/')
        ? baseUri
        : Uri.parse('${baseUri.toString()}/');
    final resolved = base.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    return query == null || query.isEmpty
        ? resolved
        : resolved.replace(queryParameters: query);
  }

  Map<String, dynamic> _asObject(dynamic json, String name) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return json.cast<String, dynamic>();
    throw FormatException('Expected $name object');
  }

  /// Closes the owned HTTP client.
  void close() {
    if (_ownsHttpClient) _http.close();
  }
}

NearErrorCode _codeForHttpStatus(int statusCode) {
  if (statusCode == 429) return NearErrorCode.rateLimited;
  if (statusCode >= 500) return NearErrorCode.rpcUnavailable;
  return NearErrorCode.invalidResponse;
}

bool _isRetryableHttpStatus(int statusCode) {
  return statusCode == 429 || statusCode >= 500;
}
