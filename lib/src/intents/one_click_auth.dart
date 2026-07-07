/// Authentication for the NEAR Intents 1Click API.
///
/// The current docs mention both `X-API-Key` and bearer JWT flows depending
/// on the endpoint and partner setup, so the client keeps this explicit.
class OneClickAuth {
  const OneClickAuth._(this.headerName, this.headerValue);

  /// Sends the partner key as `X-API-Key`.
  factory OneClickAuth.xApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'API key cannot be empty');
    }
    return OneClickAuth._('X-API-Key', apiKey);
  }

  /// Sends the JWT as `Authorization: Bearer <token>`.
  factory OneClickAuth.bearerToken(String token) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token cannot be empty');
    }
    return OneClickAuth._('Authorization', 'Bearer $token');
  }

  /// Header name used for this auth strategy.
  final String headerName;

  /// Header value used for this auth strategy.
  final String headerValue;

  /// HTTP headers to add to authenticated requests.
  Map<String, String> get headers => {headerName: headerValue};
}
