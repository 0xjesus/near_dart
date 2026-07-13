import 'dart:async';

import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  test('maps RPC timeout and rate limit to stable codes', () {
    expect(RpcError.timeout('slow').nearErrorCode, NearErrorCode.rpcTimeout);
    expect(
      RpcError.http(429, 'limited').nearErrorCode,
      NearErrorCode.rateLimited,
    );
  });

  test('maps every RPC error kind to a stable code', () {
    final expectedCodes = <RpcErrorKind, NearErrorCode>{
      RpcErrorKind.rpcError: NearErrorCode.unknown,
      RpcErrorKind.httpError: NearErrorCode.rpcUnavailable,
      RpcErrorKind.networkError: NearErrorCode.rpcUnavailable,
      RpcErrorKind.timeout: NearErrorCode.rpcTimeout,
      RpcErrorKind.parseError: NearErrorCode.invalidResponse,
      RpcErrorKind.cancelled: NearErrorCode.cancelled,
      RpcErrorKind.runtimeError: NearErrorCode.unknown,
      RpcErrorKind.unknown: NearErrorCode.unknown,
    };

    for (final entry in expectedCodes.entries) {
      expect(
        RpcError(kind: entry.key, message: 'unclassified').nearErrorCode,
        entry.value,
      );
    }
  });

  test('maps specific error messages before generic access key messages', () {
    expect(
      nearErrorFrom(StateError('Access key mismatch for account')).code,
      NearErrorCode.accessKeyMismatch,
    );
    expect(
      nearErrorFrom(StateError('Access key was not found')).code,
      NearErrorCode.accessKeyNotFound,
    );
  });

  test(
    'maps known exception types and message fragments deterministically',
    () {
      final cases = <Object, NearErrorCode>{
        TimeoutException('slow'): NearErrorCode.rpcTimeout,
        UnsupportedError('unsupported'): NearErrorCode.unsupportedOperation,
        const FormatException('bad response'): NearErrorCode.invalidResponse,
        ArgumentError('bad argument'): NearErrorCode.invalidInput,
        StateError('User rejected request'): NearErrorCode.userRejected,
        StateError('Insufficient balance'): NearErrorCode.insufficientBalance,
        StateError('Wrong network'): NearErrorCode.wrongNetwork,
        StateError('Could not open wallet'): NearErrorCode.deepLinkUnavailable,
        StateError('Wallet response is invalid'):
            NearErrorCode.walletResponseInvalid,
        StateError('Account mismatch'): NearErrorCode.accountMismatch,
        StateError('Signature verification failed'):
            NearErrorCode.signatureVerificationFailed,
        StateError('Missing callback'): NearErrorCode.missingCallback,
        StateError('Not connected'): NearErrorCode.notConnected,
        StateError('Request cancelled'): NearErrorCode.cancelled,
        StateError('Transaction failed'): NearErrorCode.transactionFailed,
        StateError('Rate limit exceeded'): NearErrorCode.rateLimited,
        StateError('RPC unavailable'): NearErrorCode.rpcUnavailable,
      };

      for (final entry in cases.entries) {
        expect(nearErrorFrom(entry.key).code, entry.value);
      }
    },
  );

  test('preserves normalized exceptions and keeps their string form safe', () {
    const exception = NearSdkException(
      code: NearErrorCode.invalidResponse,
      message: 'Response body contained a signature',
      cause: 'private_key=secret',
    );

    expect(identical(nearErrorFrom(exception), exception), isTrue);
    expect(exception.toString(), isNot(contains('body')));
    expect(exception.toString(), isNot(contains('signature')));
    expect(exception.toString(), isNot(contains('private_key')));
    expect(exception.toString(), isNot(contains('secret')));
  });
}
