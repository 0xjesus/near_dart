import 'dart:convert';

import 'package:http/http.dart' as http;

import '../diagnostics/diagnostic_endpoint_sanitizer.dart';
import '../diagnostics/near_diagnostics.dart';
import '../diagnostics/near_errors.dart';
import 'one_click_auth.dart';
import 'solver_relay_models.dart';

/// Exception thrown when the solver relay returns an HTTP or JSON-RPC error.
class SolverRelayException extends NearSdkException {
  const SolverRelayException(this._message, {this.statusCode, this.body})
    : _codeOverride = null,
      _retryableOverride = null,
      super(
        code: NearErrorCode.invalidResponse,
        message: 'Solver relay request failed',
      );

  const SolverRelayException.invalidEndpoint()
    : _message = 'Solver relay endpoint is invalid or unsupported.',
      statusCode = null,
      body = null,
      _codeOverride = NearErrorCode.invalidInput,
      _retryableOverride = false,
      super(
        code: NearErrorCode.invalidInput,
        message: 'Solver relay endpoint is invalid or unsupported.',
      );

  const SolverRelayException.transport()
    : _message = 'Solver relay transport failed.',
      statusCode = null,
      body = null,
      _codeOverride = NearErrorCode.rpcUnavailable,
      _retryableOverride = true,
      super(
        code: NearErrorCode.rpcUnavailable,
        message: 'Solver relay transport failed.',
        retryable: true,
      );

  final String _message;
  final int? statusCode;
  final String? body;
  final NearErrorCode? _codeOverride;
  final bool? _retryableOverride;

  @override
  NearErrorCode get code => _codeOverride ?? _codeForSolverFailure(statusCode);

  @override
  String get message => _message;

  @override
  bool get retryable =>
      _retryableOverride ?? _isRetryableSolverFailure(statusCode);

  @override
  String toString() =>
      'SolverRelayException(statusCode: $statusCode, code: $code)';
}

/// JSON-RPC client for the NEAR Intents Message Bus solver relay.
///
/// This is an advanced/partner API. Apps that only need swap UX should prefer
/// [OneClickClient].
class SolverRelayClient {
  SolverRelayClient({
    Uri? endpoint,
    OneClickAuth? auth,
    NearLogger? logger,
    http.Client? httpClient,
  }) : endpoint =
           endpoint ??
           Uri.parse('https://solver-relay-v2.chaindefuser.com/rpc'),
       auth = auth,
       logger = logger,
       _http = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  /// JSON-RPC endpoint.
  final Uri endpoint;

  /// Partner JWT/API key. The relay expects it in `X-API-Key`.
  final OneClickAuth? auth;

  /// Receives safe operational diagnostics for solver relay requests.
  final NearLogger? logger;

  final http.Client _http;
  final bool _ownsHttpClient;
  int _nextId = 1;

  /// Requests solver quotes through the Message Bus.
  Future<List<SolverRelayQuote>> quote(SolverRelayQuoteRequest request) =>
      _rpc('quote', [request.toJson()], (result) {
        if (result is! List) {
          throw const SolverRelayException('Expected quote result list');
        }
        return result
            .cast<Map<String, dynamic>>()
            .map(SolverRelayQuote.fromJson)
            .toList();
      });

  /// Publishes a signed user intent for execution.
  Future<SolverRelayPublishIntentResponse> publishIntent(
    SolverRelayPublishIntentRequest request,
  ) => _rpc(
    'publish_intent',
    [request.toJson()],
    (result) => SolverRelayPublishIntentResponse.fromJson(_asObject(result)),
  );

  /// Checks execution status for a published intent.
  Future<SolverRelayIntentStatus> getStatus(String intentHash) =>
      _rpc('get_status', [
        {'intent_hash': intentHash},
      ], (result) => SolverRelayIntentStatus.fromJson(_asObject(result)));

  Future<T> _rpc<T>(
    String method,
    List<Map<String, dynamic>> params,
    T Function(dynamic result) parser,
  ) async {
    final id = _nextId++;
    final stopwatch = Stopwatch()..start();
    _emitRequestEvent(
      NearLogEventType.intentsRequestStarted,
      operation: method,
      stopwatch: stopwatch,
    );

    http.Response? response;
    try {
      final validatedEndpoint = validateSupportedHttpEndpoint(endpoint);
      if (!validatedEndpoint.isSupported) {
        throw const SolverRelayException.invalidEndpoint();
      }
      try {
        response = await _http.post(
          validatedEndpoint.uri!,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            ...?auth?.headers,
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'method': method,
            'params': params,
          }),
        );
      } catch (_) {
        throw const SolverRelayException.transport();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SolverRelayException(
          'Solver relay request failed with HTTP ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['error'] != null) {
        throw SolverRelayException(
          'Solver relay JSON-RPC request failed',
          body: response.body,
        );
      }
      final result = parser(decoded['result']);
      _emitRequestEvent(
        NearLogEventType.intentsRequestSucceeded,
        operation: method,
        statusCode: response.statusCode,
        stopwatch: stopwatch,
      );
      return result;
    } catch (_) {
      _emitRequestEvent(
        NearLogEventType.intentsRequestFailed,
        operation: method,
        statusCode: response?.statusCode,
        stopwatch: stopwatch,
      );
      rethrow;
    }
  }

  void _emitRequestEvent(
    NearLogEventType type, {
    required String operation,
    required Stopwatch stopwatch,
    int? statusCode,
  }) {
    final safeEndpoint = sanitizeDiagnosticEndpointOrigin(endpoint);
    final endpointPath = sanitizeDiagnosticEndpointPath(endpoint);
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
          'endpoint': safeEndpoint,
          'method': 'POST',
          'operation': operation,
          if (endpointPath != null) 'path': endpointPath,
          if (statusCode != null) 'statusCode': statusCode,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      ),
    );
  }

  Map<String, dynamic> _asObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const FormatException('Expected object');
  }

  /// Closes the owned HTTP client.
  void close() {
    if (_ownsHttpClient) _http.close();
  }
}

NearErrorCode _codeForSolverFailure(int? statusCode) {
  if (statusCode == 429) return NearErrorCode.rateLimited;
  if (statusCode != null && statusCode >= 500) {
    return NearErrorCode.rpcUnavailable;
  }
  return NearErrorCode.invalidResponse;
}

bool _isRetryableSolverFailure(int? statusCode) {
  return statusCode == 429 || (statusCode != null && statusCode >= 500);
}
