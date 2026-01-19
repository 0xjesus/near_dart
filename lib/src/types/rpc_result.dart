import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'json_rpc.dart';

/// Represents the result of an RPC call.
///
/// This is a sealed class with two variants:
/// - [RpcSuccess]: Contains the successful result
/// - [RpcFailure]: Contains error information
///
/// Use pattern matching to handle both cases:
/// ```dart
/// switch (result) {
///   case RpcSuccess(:final value):
///     print('Success: $value');
///   case RpcFailure(:final error):
///     print('Error: $error');
/// }
/// ```
@immutable
sealed class RpcResult<T> extends Equatable {
  const RpcResult();

  /// Creates a successful result.
  factory RpcResult.success(T value) = RpcSuccess<T>;

  /// Creates a failure result.
  factory RpcResult.failure(RpcError error) = RpcFailure<T>;

  /// Returns the value if this is a success, null otherwise.
  T? getOrNull();

  /// Returns the value if this is a success, throws otherwise.
  T getOrThrow();

  /// Returns true if this is a successful result.
  bool get isSuccess;

  /// Returns true if this is a failure result.
  bool get isFailure;

  /// Transforms the success value using the given function.
  RpcResult<U> map<U>(U Function(T value) transform);

  /// Transforms the success value using a function that returns a new result.
  RpcResult<U> flatMap<U>(RpcResult<U> Function(T value) transform);
}

/// Represents a successful RPC result.
@immutable
class RpcSuccess<T> extends RpcResult<T> {
  /// Creates a successful result with the given value.
  const RpcSuccess(this.value);

  /// The successful result value.
  final T value;

  @override
  T? getOrNull() => value;

  @override
  T getOrThrow() => value;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  RpcResult<U> map<U>(U Function(T value) transform) {
    return RpcSuccess(transform(value));
  }

  @override
  RpcResult<U> flatMap<U>(RpcResult<U> Function(T value) transform) {
    return transform(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'RpcSuccess($value)';
}

/// Represents a failed RPC result.
@immutable
class RpcFailure<T> extends RpcResult<T> {
  /// Creates a failure result with the given error.
  const RpcFailure(this.error);

  /// The error that caused the failure.
  final RpcError error;

  @override
  T? getOrNull() => null;

  @override
  T getOrThrow() {
    throw RpcException(error);
  }

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  RpcResult<U> map<U>(U Function(T value) transform) {
    return RpcFailure(error);
  }

  @override
  RpcResult<U> flatMap<U>(RpcResult<U> Function(T value) transform) {
    return RpcFailure(error);
  }

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'RpcFailure($error)';
}

/// Categorizes the type of RPC error.
enum RpcErrorKind {
  /// JSON-RPC protocol error.
  rpcError,

  /// HTTP transport error.
  httpError,

  /// Network connectivity error.
  networkError,

  /// Request timeout.
  timeout,

  /// Failed to parse response.
  parseError,

  /// Request was cancelled.
  cancelled,

  /// NEAR runtime error (e.g., account not found).
  runtimeError,

  /// Unknown error.
  unknown,
}

/// Represents an error from an RPC call.
@immutable
class RpcError extends Equatable {
  /// Creates an RPC error.
  const RpcError({
    required this.kind,
    required this.message,
    this.code,
    this.data,
    this.cause,
  });

  /// Creates an RPC error from a JSON-RPC error.
  factory RpcError.fromJsonRpcError(JsonRpcError error) {
    return RpcError(
      kind: RpcErrorKind.rpcError,
      message: error.message,
      code: error.code,
      data: error.data,
    );
  }

  /// Creates an HTTP error.
  factory RpcError.http(int statusCode, String message) {
    return RpcError(
      kind: RpcErrorKind.httpError,
      message: message,
      code: statusCode,
    );
  }

  /// Creates a network error.
  factory RpcError.network(String message, [Object? cause]) {
    return RpcError(
      kind: RpcErrorKind.networkError,
      message: message,
      cause: cause,
    );
  }

  /// Creates a timeout error.
  factory RpcError.timeout(String message) {
    return RpcError(
      kind: RpcErrorKind.timeout,
      message: message,
    );
  }

  /// Creates a parse error.
  factory RpcError.parse(String message, [Object? cause]) {
    return RpcError(
      kind: RpcErrorKind.parseError,
      message: message,
      cause: cause,
    );
  }

  /// The category of this error.
  final RpcErrorKind kind;

  /// Human-readable error message.
  final String message;

  /// Error code (if applicable).
  final int? code;

  /// Additional error data.
  final dynamic data;

  /// The underlying cause (if any).
  final Object? cause;

  @override
  List<Object?> get props => [kind, message, code, data];

  @override
  String toString() => 'RpcError($kind: $message)';
}

/// Exception thrown when accessing the value of a failed RPC result.
class RpcException implements Exception {
  /// Creates an RPC exception.
  const RpcException(this.error);

  /// The underlying RPC error.
  final RpcError error;

  @override
  String toString() => 'RpcException: ${error.message}';
}
