import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../diagnostics/diagnostic_endpoint_sanitizer.dart';
import '../diagnostics/near_diagnostics.dart';
import '../diagnostics/near_errors.dart';
import 'intent_signing.dart';
import 'one_click_auth.dart';
import 'one_click_models.dart';

enum _OneClickApiFailureKind {
  http,
  invalidEndpoint,
  invalidRequest,
  timeout,
  transport,
}

/// Exception thrown when a 1Click API request fails.
class OneClickApiException extends NearSdkException {
  const OneClickApiException(this.statusCode, this.body)
    : _failureKind = _OneClickApiFailureKind.http,
      super(
        code: NearErrorCode.invalidResponse,
        message: '1Click API request failed',
      );

  const OneClickApiException.invalidEndpoint()
    : statusCode = 0,
      body = '',
      _failureKind = _OneClickApiFailureKind.invalidEndpoint,
      super(
        code: NearErrorCode.invalidInput,
        message: '1Click API endpoint is invalid or unsupported.',
      );

  const OneClickApiException.invalidRequest()
    : statusCode = 0,
      body = '',
      _failureKind = _OneClickApiFailureKind.invalidRequest,
      super(
        code: NearErrorCode.invalidInput,
        message: '1Click API request is invalid.',
      );

  const OneClickApiException.timeout()
    : statusCode = 0,
      body = '',
      _failureKind = _OneClickApiFailureKind.timeout,
      super(
        code: NearErrorCode.rpcTimeout,
        message: '1Click API request timed out.',
        retryable: true,
      );

  const OneClickApiException.transport()
    : statusCode = 0,
      body = '',
      _failureKind = _OneClickApiFailureKind.transport,
      super(
        code: NearErrorCode.rpcUnavailable,
        message: '1Click API transport failed.',
        retryable: true,
      );

  final int statusCode;
  final String body;
  final _OneClickApiFailureKind _failureKind;

  @override
  NearErrorCode get code => switch (_failureKind) {
    _OneClickApiFailureKind.http => _codeForHttpStatus(statusCode),
    _OneClickApiFailureKind.invalidEndpoint => NearErrorCode.invalidInput,
    _OneClickApiFailureKind.invalidRequest => NearErrorCode.invalidInput,
    _OneClickApiFailureKind.timeout => NearErrorCode.rpcTimeout,
    _OneClickApiFailureKind.transport => NearErrorCode.rpcUnavailable,
  };

  @override
  String get message => switch (_failureKind) {
    _OneClickApiFailureKind.http =>
      '1Click API request failed with HTTP $statusCode',
    _OneClickApiFailureKind.invalidEndpoint =>
      '1Click API endpoint is invalid or unsupported.',
    _OneClickApiFailureKind.invalidRequest => '1Click API request is invalid.',
    _OneClickApiFailureKind.timeout => '1Click API request timed out.',
    _OneClickApiFailureKind.transport => '1Click API transport failed.',
  };

  @override
  bool get retryable => switch (_failureKind) {
    _OneClickApiFailureKind.http => _isRetryableHttpStatus(statusCode),
    _OneClickApiFailureKind.invalidEndpoint => false,
    _OneClickApiFailureKind.invalidRequest => false,
    _OneClickApiFailureKind.timeout => true,
    _OneClickApiFailureKind.transport => true,
  };

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
    Duration requestTimeout = const Duration(seconds: 30),
  }) : requestTimeout = _validateRequestTimeout(requestTimeout),
       baseUri = baseUri ?? Uri.parse('https://1click.chaindefuser.com'),
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

  /// Maximum wall-clock time allowed for one HTTP request.
  ///
  /// Defaults to 30 seconds.
  final Duration requestTimeout;

  final http.Client _http;
  final bool _ownsHttpClient;

  /// Lists tokens supported by the 1Click API.
  Future<List<OneClickToken>> tokens() => _request(
    'GET',
    '/v0/tokens',
    parser: (json) {
      if (json is! List) {
        throw const FormatException('Expected token list response');
      }
      return json
          .cast<Map<String, dynamic>>()
          .map(OneClickToken.fromJson)
          .toList();
    },
  );

  /// Requests a swap quote.
  Future<OneClickQuoteResponse> quote(OneClickQuoteRequest request) => _request(
    'POST',
    '/v0/quote',
    body: request.toJson(),
    parser: (json) =>
        OneClickQuoteResponse.fromJson(_asObject(json, 'quote response')),
  );

  /// Notifies 1Click about an origin-chain deposit transaction.
  Future<void> submitDeposit({
    required String depositAddress,
    required String txHash,
    String? nearSenderAccount,
    String? memo,
  }) async {
    await _request<void>(
      'POST',
      '/v0/deposit/submit',
      body: {
        'depositAddress': depositAddress,
        'txHash': txHash,
        if (nearSenderAccount != null) 'nearSenderAccount': nearSenderAccount,
        if (memo != null) 'memo': memo,
      },
      parser: (_) {},
    );
  }

  /// Checks swap execution status.
  Future<OneClickStatus> status({
    required String depositAddress,
    String? depositMemo,
  }) async {
    return _request(
      'GET',
      '/v0/status',
      query: {
        'depositAddress': depositAddress,
        if (depositMemo != null) 'depositMemo': depositMemo,
      },
      parser: (json) =>
          OneClickStatus.fromJson(_asObject(json, 'status response')),
    );
  }

  /// Generates an unsigned intent for wallet signing.
  Future<GeneratedIntent> generateIntent({
    required String depositAddress,
    required String signerId,
    required IntentSigningStandard standard,
    String type = 'swap_transfer',
  }) async {
    return _request(
      'POST',
      '/v0/generate-intent',
      body: {
        'type': type,
        'depositAddress': depositAddress,
        'signerId': signerId,
        'standard': standard.wireValue,
      },
      parser: (json) =>
          GeneratedIntent.fromJson(_asObject(json, 'generated intent')),
    );
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
    return _request(
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
      parser: (json) => OneClickAnyInputWithdrawals.fromJson(
        _asObject(json, 'ANY_INPUT withdrawals response'),
      ),
    );
  }

  /// Submits a signed intent payload.
  Future<SubmitIntentResponse> submitIntent({
    required String type,
    required SignedMultiPayload signedData,
    Map<String, dynamic> extra = const {},
  }) async {
    return _request(
      'POST',
      '/v0/submit-intent',
      body: {...extra, 'type': type, 'signedData': signedData.toJson()},
      parser: (json) => SubmitIntentResponse.fromJson(
        _asObject(json, 'submit intent response'),
      ),
    );
  }

  Future<T> _request<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    required T Function(dynamic json) parser,
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
      final endpoint = validateSupportedHttpEndpoint(uri);
      if (!endpoint.isSupported) {
        throw const OneClickApiException.invalidEndpoint();
      }
      String? encodedBody;
      try {
        encodedBody = body == null ? null : jsonEncode(body);
      } catch (_) {
        throw const OneClickApiException.invalidRequest();
      }
      try {
        response = await _send(
          method,
          endpoint.uri!,
          body: encodedBody,
        ).timeout(requestTimeout);
      } on TimeoutException {
        throw const OneClickApiException.timeout();
      } catch (_) {
        throw const OneClickApiException.transport();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OneClickApiException(response.statusCode, response.body);
      }
      final json = response.body.isEmpty ? null : jsonDecode(response.body);
      final result = parser(json);
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
    final endpoint = sanitizeDiagnosticEndpointOrigin(uri);
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
          'endpoint': endpoint,
          'method': method,
          'operation': operation,
          'path': operation,
          if (statusCode != null) 'statusCode': statusCode,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      ),
    );
  }

  Future<http.Response> _send(String method, Uri uri, {String? body}) {
    final headers = {
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...?auth?.headers,
    };
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: body);
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
  if (statusCode == 408) return NearErrorCode.rpcTimeout;
  if (statusCode == 429) return NearErrorCode.rateLimited;
  if (statusCode >= 500) return NearErrorCode.rpcUnavailable;
  return NearErrorCode.invalidResponse;
}

bool _isRetryableHttpStatus(int statusCode) {
  return statusCode == 408 || statusCode == 429 || statusCode >= 500;
}

Duration _validateRequestTimeout(Duration requestTimeout) {
  if (requestTimeout <= Duration.zero) {
    throw ArgumentError.value(
      requestTimeout,
      'requestTimeout',
      'Must be greater than Duration.zero',
    );
  }
  return requestTimeout;
}
