import 'dart:async';

/// Stable, machine-readable categories for SDK failures.
enum NearErrorCode {
  /// The caller supplied invalid input.
  invalidInput,

  /// The selected wallet or operation does not support the active network.
  wrongNetwork,

  /// An operation requires a connected wallet or session.
  notConnected,

  /// A required wallet callback was absent.
  missingCallback,

  /// The platform could not open the required deep link.
  deepLinkUnavailable,

  /// The user declined the wallet request.
  userRejected,

  /// A wallet returned an invalid response.
  walletResponseInvalid,

  /// The returned account does not match the expected account.
  accountMismatch,

  /// A returned wallet signature could not be verified.
  signatureVerificationFailed,

  /// The requested access key does not exist.
  accessKeyNotFound,

  /// The returned access key does not match the expected key.
  accessKeyMismatch,

  /// An RPC endpoint could not be reached or used.
  rpcUnavailable,

  /// An RPC request timed out.
  rpcTimeout,

  /// An endpoint rejected the request due to rate limiting.
  rateLimited,

  /// A transaction was rejected or failed on chain.
  transactionFailed,

  /// The account lacks funds for the requested operation.
  insufficientBalance,

  /// The requested operation is not supported.
  unsupportedOperation,

  /// A service returned a response with an invalid shape or content.
  invalidResponse,

  /// The caller or transport cancelled the operation.
  cancelled,

  /// The error could not be classified more specifically.
  unknown,
}

/// A normalized SDK exception with a stable [code].
class NearSdkException implements Exception {
  /// Creates a normalized SDK exception.
  const NearSdkException({
    required this.code,
    required this.message,
    this.retryable = false,
    this.cause,
  });

  /// Stable category for this error.
  final NearErrorCode code;

  /// A human-readable description intended for application handling.
  final String message;

  /// Whether retrying the operation may succeed without user intervention.
  final bool retryable;

  /// The original error, retained for programmatic inspection.
  final Object? cause;

  @override
  String toString() => 'NearSdkException(code: $code, retryable: $retryable)';
}

/// Converts an arbitrary error into a normalized SDK exception.
NearSdkException nearErrorFrom(Object error) {
  if (error is NearSdkException) return error;

  if (error is TimeoutException) {
    return NearSdkException(
      code: NearErrorCode.rpcTimeout,
      message: _messageFor(error),
      retryable: true,
      cause: error,
    );
  }
  if (error is UnsupportedError) {
    return NearSdkException(
      code: NearErrorCode.unsupportedOperation,
      message: _messageFor(error),
      cause: error,
    );
  }
  if (error is FormatException) {
    return NearSdkException(
      code: NearErrorCode.invalidResponse,
      message: _messageFor(error),
      cause: error,
    );
  }
  if (error is ArgumentError) {
    return NearSdkException(
      code: NearErrorCode.invalidInput,
      message: _messageFor(error),
      cause: error,
    );
  }

  final message = _messageFor(error);
  final code = _codeFromMessage(message);
  return NearSdkException(
    code: code,
    message: message,
    retryable: _isRetryable(code),
    cause: error,
  );
}

String _messageFor(Object error) {
  if (error is String) return error;
  return error.toString();
}

NearErrorCode _codeFromMessage(String message) {
  final normalized = message.toLowerCase().replaceAll(RegExp('[_-]+'), ' ');

  if (normalized.contains('signature') && normalized.contains('verif')) {
    return NearErrorCode.signatureVerificationFailed;
  }
  if (normalized.contains('access key mismatch')) {
    return NearErrorCode.accessKeyMismatch;
  }
  if (normalized.contains('access key')) {
    return NearErrorCode.accessKeyNotFound;
  }
  if (normalized.contains('insufficient balance')) {
    return NearErrorCode.insufficientBalance;
  }
  if (normalized.contains('wrong network')) return NearErrorCode.wrongNetwork;
  if (normalized.contains('could not open')) {
    return NearErrorCode.deepLinkUnavailable;
  }
  if (normalized.contains('reject')) return NearErrorCode.userRejected;
  if (normalized.contains('wallet response') &&
      (normalized.contains('invalid') || normalized.contains('unexpected'))) {
    return NearErrorCode.walletResponseInvalid;
  }
  if (normalized.contains('account mismatch')) {
    return NearErrorCode.accountMismatch;
  }
  if (normalized.contains('missing callback')) {
    return NearErrorCode.missingCallback;
  }
  if (normalized.contains('not connected')) return NearErrorCode.notConnected;
  if (normalized.contains('cancel')) return NearErrorCode.cancelled;
  if (normalized.contains('transaction') && normalized.contains('fail')) {
    return NearErrorCode.transactionFailed;
  }
  if (normalized.contains('rate limit') ||
      normalized.contains('too many request')) {
    return NearErrorCode.rateLimited;
  }
  if (normalized.contains('timed out') || normalized.contains('timeout')) {
    return NearErrorCode.rpcTimeout;
  }
  if (normalized.contains('rpc unavailable') ||
      normalized.contains('network unavailable')) {
    return NearErrorCode.rpcUnavailable;
  }
  if (normalized.contains('unsupported')) {
    return NearErrorCode.unsupportedOperation;
  }
  if (normalized.contains('invalid response')) {
    return NearErrorCode.invalidResponse;
  }
  if (normalized.contains('invalid input')) return NearErrorCode.invalidInput;
  return NearErrorCode.unknown;
}

bool _isRetryable(NearErrorCode code) {
  return switch (code) {
    NearErrorCode.rpcUnavailable ||
    NearErrorCode.rpcTimeout ||
    NearErrorCode.rateLimited => true,
    _ => false,
  };
}
