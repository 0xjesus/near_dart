import 'package:near_dart/src/diagnostics/diagnostic_endpoint_sanitizer.dart';
import 'package:test/test.dart';

void main() {
  group('validateSupportedHttpEndpoint', () {
    test('accepts the Dart HTTP transport port range and default ports', () {
      for (final endpoint in [
        'http://example.com',
        'https://example.com:0/path',
        'https://example.com:65535/path',
      ]) {
        expect(
          validateSupportedHttpEndpoint(endpoint).isSupported,
          isTrue,
          reason: endpoint,
        );
      }
    });

    test('rejects malformed and out-of-range explicit ports', () {
      for (final endpoint in [
        'https://example.com:-1/path',
        'https://example.com:99999/path',
        'https://example.com:not-a-port/path',
      ]) {
        expect(
          validateSupportedHttpEndpoint(endpoint).isSupported,
          isFalse,
          reason: endpoint,
        );
      }
    });
  });
}
