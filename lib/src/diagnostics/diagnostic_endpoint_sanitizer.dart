const String invalidDiagnosticEndpointOrigin = 'invalid-endpoint';

/// Returns a safe HTTP(S) origin for diagnostic metadata.
///
/// Endpoint configuration must never change the behavior of an SDK request or
/// disclose a full URL through diagnostic construction.
String sanitizeDiagnosticEndpointOrigin(Object? endpoint) {
  try {
    final uri = _asUri(endpoint);
    if (uri == null) return invalidDiagnosticEndpointOrigin;

    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) {
      return invalidDiagnosticEndpointOrigin;
    }

    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).origin;
  } catch (_) {
    return invalidDiagnosticEndpointOrigin;
  }
}

/// Returns a path for diagnostic metadata only when its endpoint is safe.
String? sanitizeDiagnosticEndpointPath(Object? endpoint) {
  try {
    if (sanitizeDiagnosticEndpointOrigin(endpoint) ==
        invalidDiagnosticEndpointOrigin) {
      return null;
    }
    return _asUri(endpoint)?.path;
  } catch (_) {
    return null;
  }
}

Uri? _asUri(Object? endpoint) {
  return switch (endpoint) {
    Uri() => endpoint,
    String() => Uri.parse(endpoint),
    _ => null,
  };
}
