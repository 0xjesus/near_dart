const String _redactedValue = '<redacted>';

const List<String> _sensitiveKeyFragments = <String>[
  'authorization',
  'token',
  'secret',
  'privatekey',
  'signature',
  'payload',
  'body',
  'messagebody',
  'nonce',
];

final RegExp _signedTransactionKeyPattern = RegExp(
  r'(^|_)(?:signed_(?:transaction|tx)|signed(?:transaction|tx))(?=_|$)',
);

/// Severity assigned to a diagnostics event.
enum NearLogLevel {
  /// Verbose diagnostic information.
  debug,

  /// Normal operational information.
  info,

  /// A recoverable or unexpected condition.
  warning,

  /// A failed operation.
  error,
}

/// Named lifecycle events emitted by the SDK.
enum NearLogEventType {
  /// An RPC request is about to be sent.
  rpcRequestStarted,

  /// An RPC request is being retried.
  rpcRequestRetried,

  /// An RPC request completed successfully.
  rpcRequestSucceeded,

  /// An RPC request failed.
  rpcRequestFailed,

  /// A NEAR Intents request is about to be sent.
  intentsRequestStarted,

  /// A NEAR Intents request completed successfully.
  intentsRequestSucceeded,

  /// A NEAR Intents request failed.
  intentsRequestFailed,

  /// A wallet flow was opened.
  walletFlowOpened,

  /// A wallet callback was received.
  walletCallbackReceived,

  /// A wallet was connected.
  walletConnected,

  /// A wallet was disconnected.
  walletDisconnected,

  /// A transaction was submitted to a wallet or RPC endpoint.
  transactionSubmitted,

  /// A submitted transaction reached finality.
  transactionFinalized,
}

/// Receives a structured, redacted SDK diagnostics event.
typedef NearLogger = void Function(NearLogEvent event);

/// An immutable, redacted diagnostics event emitted by the SDK.
class NearLogEvent {
  /// Creates a diagnostics event with recursively redacted metadata.
  NearLogEvent({
    required this.level,
    required this.type,
    required this.operation,
    Map<String, Object?> metadata = const <String, Object?>{},
    DateTime? timestamp,
  }) : metadata = redactNearMetadata(metadata),
       timestamp = timestamp ?? DateTime.now().toUtc();

  /// Severity assigned to this event.
  final NearLogLevel level;

  /// Lifecycle event represented by this event.
  final NearLogEventType type;

  /// The SDK operation that produced this event.
  final String operation;

  /// Recursively copied, immutable, and redacted event metadata.
  final Map<String, Object?> metadata;

  /// When the event was created.
  final DateTime timestamp;

  @override
  String toString() {
    return 'NearLogEvent('
        'level: $level, '
        'type: $type, '
        'operation: $operation, '
        'metadata: $metadata, '
        'timestamp: $timestamp)';
  }
}

/// Recursively copies metadata and replaces values with sensitive key names.
///
/// Key names are compared after lowercasing and removing underscores and
/// hyphens. Maps and lists in safe metadata are copied into immutable values.
Map<String, Object?> redactNearMetadata(Map<String, Object?> metadata) {
  return Map<String, Object?>.unmodifiable(
    metadata.map(
      (key, value) => MapEntry<String, Object?>(key, _redactValue(key, value)),
    ),
  );
}

/// Invokes [logger] without letting a logger failure affect SDK behavior.
void emitNearLog(NearLogger? logger, NearLogEvent event) {
  if (logger == null) return;
  try {
    logger(event);
  } catch (_) {
    return;
  }
}

Object? _redactValue(String? key, Object? value) {
  if (key != null && _isSensitiveKey(key)) return _redactedValue;

  if (value is Map<Object?, Object?>) {
    return Map<Object?, Object?>.unmodifiable(
      value.map(
        (nestedKey, nestedValue) => MapEntry<Object?, Object?>(
          nestedKey,
          _redactValue(nestedKey is String ? nestedKey : null, nestedValue),
        ),
      ),
    );
  }

  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(
      value.map((item) => _redactValue(null, item)),
    );
  }

  return value;
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp('[_-]'), '');
  return normalized == 'message' ||
      _isSignedTransactionKey(key) ||
      _sensitiveKeyFragments.any(normalized.contains);
}

bool _isSignedTransactionKey(String key) {
  final boundaryNormalized = key
      .replaceAllMapped(
        RegExp(r'([A-Z]+)([A-Z][a-z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return _signedTransactionKeyPattern.hasMatch(boundaryNormalized);
}
