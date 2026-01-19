import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents a JSON-RPC 2.0 request to the NEAR Protocol RPC.
///
/// The JSON-RPC 2.0 specification requires:
/// - `jsonrpc`: Always "2.0"
/// - `method`: The RPC method name
/// - `params`: Method parameters (can be empty)
/// - `id`: Request identifier for matching responses
@immutable
class JsonRpcRequest extends Equatable {
  /// Creates a new JSON-RPC request.
  ///
  /// If [id] is not provided, a unique identifier is generated.
  JsonRpcRequest({
    required this.method,
    required this.params,
    String? id,
  }) : id = id ?? _generateId();

  /// The JSON-RPC version. Always "2.0".
  static const String jsonrpcVersion = '2.0';

  /// The RPC method to call.
  final String method;

  /// The parameters for the RPC method.
  final Map<String, dynamic> params;

  /// Unique identifier for this request.
  final String id;

  static int _idCounter = 0;

  static String _generateId() {
    _idCounter++;
    return 'near-dart-${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
  }

  /// Converts this request to a JSON map.
  Map<String, dynamic> toJson() => {
        'jsonrpc': jsonrpcVersion,
        'method': method,
        'params': params,
        'id': id,
      };

  @override
  List<Object?> get props => [method, params, id];

  @override
  String toString() => 'JsonRpcRequest(method: $method, id: $id)';
}

/// Represents a JSON-RPC 2.0 response from the NEAR Protocol RPC.
///
/// A response contains either a `result` (on success) or an `error` (on failure),
/// but never both.
@immutable
class JsonRpcResponse extends Equatable {
  /// Creates a successful response.
  const JsonRpcResponse.success({
    required this.id,
    required this.result,
  }) : error = null;

  /// Creates an error response.
  const JsonRpcResponse.error({
    required this.id,
    required this.error,
  }) : result = null;

  /// Creates a response from a JSON map.
  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;

    if (json.containsKey('error') && json['error'] != null) {
      return JsonRpcResponse.error(
        id: id,
        error: JsonRpcError.fromJson(json['error'] as Map<String, dynamic>),
      );
    }

    return JsonRpcResponse.success(
      id: id,
      result: json['result'],
    );
  }

  /// The request identifier this response is for.
  final String? id;

  /// The result of the RPC call. Null if this is an error response.
  final dynamic result;

  /// The error if the RPC call failed. Null if this is a success response.
  final JsonRpcError? error;

  /// Returns true if this is a successful response.
  bool get isSuccess => error == null;

  /// Returns true if this is an error response.
  bool get isError => error != null;

  @override
  List<Object?> get props => [id, result, error];

  @override
  String toString() {
    if (isSuccess) {
      return 'JsonRpcResponse.success(id: $id)';
    }
    return 'JsonRpcResponse.error(id: $id, error: $error)';
  }
}

/// Represents a JSON-RPC 2.0 error.
///
/// Standard JSON-RPC error codes:
/// - `-32700`: Parse error
/// - `-32600`: Invalid request
/// - `-32601`: Method not found
/// - `-32602`: Invalid params
/// - `-32603`: Internal error
/// - `-32000` to `-32099`: Server errors (NEAR-specific)
@immutable
class JsonRpcError extends Equatable {
  /// Creates a JSON-RPC error.
  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  /// Creates an error from a JSON map.
  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'],
    );
  }

  /// The error code.
  final int code;

  /// A short description of the error.
  final String message;

  /// Additional error data. May contain NEAR-specific error details.
  final dynamic data;

  /// Converts this error to a JSON map.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  List<Object?> get props => [code, message, data];

  @override
  String toString() => 'JsonRpcError(code: $code, message: $message)';
}
