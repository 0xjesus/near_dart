import 'dart:convert';

import 'package:http/http.dart' as http;

import 'intent_signing.dart';
import 'one_click_auth.dart';
import 'one_click_models.dart';

/// Exception thrown when the 1Click API returns a non-2xx response.
class OneClickApiException implements Exception {
  const OneClickApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'OneClickApiException($statusCode): $body';
}

/// REST client for the NEAR Intents 1Click API.
class OneClickClient {
  OneClickClient({Uri? baseUri, OneClickAuth? auth, http.Client? httpClient})
    : baseUri = baseUri ?? Uri.parse('https://1click.chaindefuser.com'),
      auth = auth,
      _http = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null;

  /// Base API URI. Defaults to `https://1click.chaindefuser.com`.
  final Uri baseUri;

  /// Optional partner auth.
  final OneClickAuth? auth;

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
    final response = await _send(method, _uri(path, query), body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OneClickApiException(response.statusCode, response.body);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
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
