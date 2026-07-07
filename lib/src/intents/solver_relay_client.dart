import 'dart:convert';

import 'package:http/http.dart' as http;

import 'one_click_auth.dart';
import 'solver_relay_models.dart';

/// Exception thrown when the solver relay returns an HTTP or JSON-RPC error.
class SolverRelayException implements Exception {
  const SolverRelayException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'SolverRelayException: $message';
}

/// JSON-RPC client for the NEAR Intents Message Bus solver relay.
///
/// This is an advanced/partner API. Apps that only need swap UX should prefer
/// [OneClickClient].
class SolverRelayClient {
  SolverRelayClient({
    Uri? endpoint,
    OneClickAuth? auth,
    http.Client? httpClient,
  }) : endpoint =
           endpoint ??
           Uri.parse('https://solver-relay-v2.chaindefuser.com/rpc'),
       auth = auth,
       _http = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  /// JSON-RPC endpoint.
  final Uri endpoint;

  /// Partner JWT/API key. The relay expects it in `X-API-Key`.
  final OneClickAuth? auth;

  final http.Client _http;
  final bool _ownsHttpClient;
  int _nextId = 1;

  /// Requests solver quotes through the Message Bus.
  Future<List<SolverRelayQuote>> quote(SolverRelayQuoteRequest request) async {
    final result = await _rpc('quote', [request.toJson()]);
    if (result is! List) {
      throw const SolverRelayException('Expected quote result list');
    }
    return result
        .cast<Map<String, dynamic>>()
        .map(SolverRelayQuote.fromJson)
        .toList();
  }

  /// Publishes a signed user intent for execution.
  Future<SolverRelayPublishIntentResponse> publishIntent(
    SolverRelayPublishIntentRequest request,
  ) async {
    final result = await _rpc('publish_intent', [request.toJson()]);
    return SolverRelayPublishIntentResponse.fromJson(_asObject(result));
  }

  /// Checks execution status for a published intent.
  Future<SolverRelayIntentStatus> getStatus(String intentHash) async {
    final result = await _rpc('get_status', [
      {'intent_hash': intentHash},
    ]);
    return SolverRelayIntentStatus.fromJson(_asObject(result));
  }

  Future<dynamic> _rpc(String method, List<Map<String, dynamic>> params) async {
    final id = _nextId++;
    final response = await _http.post(
      endpoint,
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SolverRelayException(
        'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['error'] != null) {
      throw SolverRelayException(
        'JSON-RPC error: ${decoded['error']}',
        body: response.body,
      );
    }
    return decoded['result'];
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
