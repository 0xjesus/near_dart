const String invalidDiagnosticEndpointOrigin = 'invalid-endpoint';
const int _minimumHttpTransportPort = 0;
const int _maximumHttpTransportPort = 65535;

/// The result of validating an endpoint for HTTP transport.
class SupportedHttpEndpointValidation {
  const SupportedHttpEndpointValidation._(this.uri);

  const SupportedHttpEndpointValidation.unsupported() : uri = null;

  /// The validated HTTP(S) endpoint, or null when unsupported.
  final Uri? uri;

  /// Whether [uri] is safe to pass to an HTTP transport.
  bool get isSupported => uri != null;
}

/// Validates an endpoint for HTTP transport without throwing.
SupportedHttpEndpointValidation validateSupportedHttpEndpoint(
  Object? endpoint,
) {
  try {
    final uri = _asUri(endpoint);
    if (uri == null) return const SupportedHttpEndpointValidation.unsupported();

    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) {
      return const SupportedHttpEndpointValidation.unsupported();
    }

    // Dart's HTTP transports accept the inclusive TCP port range. Port zero
    // is transport-valid even though a connection to it may fail normally.
    if (uri.hasPort &&
        (uri.port < _minimumHttpTransportPort ||
            uri.port > _maximumHttpTransportPort)) {
      return const SupportedHttpEndpointValidation.unsupported();
    }

    return SupportedHttpEndpointValidation._(uri);
  } catch (_) {
    return const SupportedHttpEndpointValidation.unsupported();
  }
}

/// Whether an endpoint can be passed to an HTTP transport.
bool isSupportedHttpEndpoint(Object? endpoint) =>
    validateSupportedHttpEndpoint(endpoint).isSupported;

/// Returns a safe HTTP(S) origin for diagnostic metadata.
///
/// Endpoint configuration must never change the behavior of an SDK request or
/// disclose a full URL through diagnostic construction.
String sanitizeDiagnosticEndpointOrigin(Object? endpoint) {
  try {
    final uri = validateSupportedHttpEndpoint(endpoint).uri;
    if (uri == null) {
      return invalidDiagnosticEndpointOrigin;
    }

    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).origin;
  } catch (_) {
    return invalidDiagnosticEndpointOrigin;
  }
}

Uri? _asUri(Object? endpoint) {
  return switch (endpoint) {
    Uri() => endpoint,
    String() => Uri.parse(endpoint),
    _ => null,
  };
}
