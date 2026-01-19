import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

/// The result of a transaction execution.
@immutable
class TransactionResult extends Equatable {
  const TransactionResult({
    required this.transactionHash,
    required this.outcome,
  });

  /// The hash of the transaction.
  final CryptoHash transactionHash;

  /// The outcome of the transaction execution.
  final ExecutionOutcome outcome;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'transaction_hash': transactionHash.value,
        'outcome': outcome.toJson(),
      };

  @override
  List<Object?> get props => [transactionHash, outcome];
}

/// The outcome of executing actions.
@immutable
class ExecutionOutcome extends Equatable {
  const ExecutionOutcome({
    required this.status,
    required this.gasBurnt,
    this.logs = const [],
    this.receiptIds = const [],
  });

  /// The status of the execution.
  final ExecutionStatus status;

  /// Gas burnt during execution.
  final BigInt gasBurnt;

  /// Logs produced during execution.
  final List<String> logs;

  /// Receipt IDs created during execution.
  final List<String> receiptIds;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'status': status.toJson(),
        'gas_burnt': gasBurnt.toString(),
        'logs': logs,
        'receipt_ids': receiptIds,
      };

  @override
  List<Object?> get props => [status, gasBurnt, logs, receiptIds];
}

/// Base class for execution status types.
@immutable
sealed class ExecutionStatus extends Equatable {
  const ExecutionStatus();

  /// Creates a success status with a return value.
  factory ExecutionStatus.successValue(String value) =
      ExecutionStatusSuccessValue;

  /// Creates a success status with receipt IDs.
  factory ExecutionStatus.successReceiptIds(List<String> receiptIds) =
      ExecutionStatusSuccessReceiptIds;

  /// Creates a failure status.
  factory ExecutionStatus.failure(ExecutionError error) =
      ExecutionStatusFailure;

  /// Serializes to JSON.
  Map<String, dynamic> toJson();
}

/// Execution succeeded with a return value.
@immutable
class ExecutionStatusSuccessValue extends ExecutionStatus {
  const ExecutionStatusSuccessValue(this.value);

  /// The return value (base64 encoded).
  final String value;

  @override
  Map<String, dynamic> toJson() => {'SuccessValue': value};

  @override
  List<Object?> get props => [value];
}

/// Execution succeeded with receipt IDs (for async actions).
@immutable
class ExecutionStatusSuccessReceiptIds extends ExecutionStatus {
  const ExecutionStatusSuccessReceiptIds(this.receiptIds);

  /// The receipt IDs generated.
  final List<String> receiptIds;

  @override
  Map<String, dynamic> toJson() => {'SuccessReceiptId': receiptIds};

  @override
  List<Object?> get props => [receiptIds];
}

/// Execution failed.
@immutable
class ExecutionStatusFailure extends ExecutionStatus {
  const ExecutionStatusFailure(this.error);

  /// The execution error.
  final ExecutionError error;

  @override
  Map<String, dynamic> toJson() => {'Failure': error.toJson()};

  @override
  List<Object?> get props => [error];
}

/// An execution error.
@immutable
class ExecutionError extends Equatable {
  const ExecutionError({
    required this.errorType,
    required this.errorMessage,
  });

  /// The type of error.
  final String errorType;

  /// Human-readable error message.
  final String errorMessage;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'error_type': errorType,
        'error_message': errorMessage,
      };

  @override
  List<Object?> get props => [errorType, errorMessage];
}
