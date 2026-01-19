import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Response from the `query` RPC method when calling a contract function.
///
/// Contains the result of a view function call on a smart contract.
@immutable
class CallFunctionResponse extends Equatable {
  const CallFunctionResponse({
    required this.result,
    required this.logs,
    required this.blockHeight,
    required this.blockHash,
  });

  factory CallFunctionResponse.fromJson(Map<String, dynamic> json) {
    final resultList = json['result'] as List<dynamic>;
    final resultBytes = Uint8List.fromList(
      resultList.map((e) => e as int).toList(),
    );

    return CallFunctionResponse(
      result: resultBytes,
      logs: (json['logs'] as List<dynamic>).map((e) => e as String).toList(),
      blockHeight: json['block_height'] as int,
      blockHash: json['block_hash'] as String,
    );
  }

  /// The raw result bytes from the contract call.
  final Uint8List result;

  /// Logs emitted during the function call.
  final List<String> logs;

  /// Block height at which this view was taken.
  final int blockHeight;

  /// Block hash at which this view was taken.
  final String blockHash;

  /// Decodes the result as a UTF-8 JSON string and parses it.
  ///
  /// Most NEAR contracts return JSON-encoded results.
  dynamic resultAsJson() {
    if (result.isEmpty) return null;
    final jsonStr = utf8.decode(result);
    return jsonDecode(jsonStr);
  }

  /// Decodes the result as a UTF-8 string.
  String resultAsString() {
    if (result.isEmpty) return '';
    return utf8.decode(result);
  }

  @override
  List<Object?> get props => [result, logs, blockHeight, blockHash];
}
