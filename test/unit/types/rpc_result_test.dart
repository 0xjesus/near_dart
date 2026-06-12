/// Unit tests for RpcResult type and its variants.
///
/// Tests pure logic - no network calls required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('RpcResult', () {
    group('RpcSuccess', () {
      test('creates success with value', () {
        final result = RpcResult<String>.success('test value');

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.getOrNull(), equals('test value'));
        expect(result.getOrThrow(), equals('test value'));
      });

      test('success with null value', () {
        final result = RpcResult<String?>.success(null);

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('success with complex type', () {
        final result = RpcResult<Map<String, int>>.success({'a': 1, 'b': 2});

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals({'a': 1, 'b': 2}));
      });

      test('map transforms success value', () {
        final result = RpcResult<int>.success(5);
        final mapped = result.map((v) => v * 2);

        expect(mapped.isSuccess, isTrue);
        expect(mapped.getOrNull(), equals(10));
      });

      test('flatMap transforms to new result', () {
        final result = RpcResult<int>.success(5);
        final flatMapped = result.flatMap(
          (v) => RpcResult.success(v.toString()),
        );

        expect(flatMapped.isSuccess, isTrue);
        expect(flatMapped.getOrNull(), equals('5'));
      });

      test('flatMap can transform to failure', () {
        final result = RpcResult<int>.success(5);
        final flatMapped = result.flatMap<String>(
          (v) => RpcResult.failure(
            const RpcError(
              kind: RpcErrorKind.rpcError,
              message: 'Transformed to error',
            ),
          ),
        );

        expect(flatMapped.isFailure, isTrue);
      });

      test('equality works for success', () {
        final result1 = RpcResult<String>.success('test');
        final result2 = RpcResult<String>.success('test');
        final result3 = RpcResult<String>.success('different');

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString includes value', () {
        final result = RpcResult<String>.success('hello');
        expect(result.toString(), contains('hello'));
      });
    });

    group('RpcFailure', () {
      test('creates failure with error', () {
        const error = RpcError(
          kind: RpcErrorKind.rpcError,
          message: 'Something went wrong',
        );
        final result = RpcResult<String>.failure(error);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('getOrThrow throws RpcException', () {
        const error = RpcError(
          kind: RpcErrorKind.rpcError,
          message: 'Test error',
        );
        final result = RpcResult<String>.failure(error);

        expect(result.getOrThrow, throwsA(isA<RpcException>()));
      });

      test('RpcException contains error details', () {
        const error = RpcError(
          kind: RpcErrorKind.networkError,
          message: 'Connection failed',
        );
        final result = RpcResult<String>.failure(error);

        try {
          result.getOrThrow();
          fail('Should have thrown');
        } on RpcException catch (e) {
          expect(e.error.kind, equals(RpcErrorKind.networkError));
          expect(e.error.message, equals('Connection failed'));
          expect(e.toString(), contains('Connection failed'));
        }
      });

      test('map preserves failure', () {
        const error = RpcError(kind: RpcErrorKind.rpcError, message: 'Error');
        final result = RpcResult<int>.failure(error);
        final mapped = result.map((v) => v * 2);

        expect(mapped.isFailure, isTrue);
        expect((mapped as RpcFailure).error, equals(error));
      });

      test('flatMap preserves failure', () {
        const error = RpcError(kind: RpcErrorKind.rpcError, message: 'Error');
        final result = RpcResult<int>.failure(error);
        final flatMapped = result.flatMap(
          (v) => RpcResult.success(v.toString()),
        );

        expect(flatMapped.isFailure, isTrue);
      });

      test('equality works for failure', () {
        const error = RpcError(kind: RpcErrorKind.rpcError, message: 'Error');
        final result1 = RpcResult<String>.failure(error);
        final result2 = RpcResult<String>.failure(error);

        expect(result1, equals(result2));
      });

      test('toString includes error', () {
        const error = RpcError(kind: RpcErrorKind.rpcError, message: 'Test');
        final result = RpcResult<String>.failure(error);
        expect(result.toString(), contains('RpcFailure'));
      });
    });

    group('Pattern matching', () {
      test('switch exhaustively matches success', () {
        final result = RpcResult<int>.success(42);
        String output;

        switch (result) {
          case RpcSuccess(:final value):
            output = 'Success: $value';
          case RpcFailure(:final error):
            output = 'Failure: ${error.message}';
        }

        expect(output, equals('Success: 42'));
      });

      test('switch exhaustively matches failure', () {
        final result = RpcResult<int>.failure(
          const RpcError(kind: RpcErrorKind.rpcError, message: 'Failed'),
        );
        String output;

        switch (result) {
          case RpcSuccess(:final value):
            output = 'Success: $value';
          case RpcFailure(:final error):
            output = 'Failure: ${error.message}';
        }

        expect(output, equals('Failure: Failed'));
      });
    });
  });

  group('RpcError', () {
    test('creates basic error', () {
      const error = RpcError(
        kind: RpcErrorKind.rpcError,
        message: 'Test message',
      );

      expect(error.kind, equals(RpcErrorKind.rpcError));
      expect(error.message, equals('Test message'));
      expect(error.code, isNull);
      expect(error.data, isNull);
      expect(error.cause, isNull);
    });

    test('creates error with all fields', () {
      final error = RpcError(
        kind: RpcErrorKind.httpError,
        message: 'HTTP failed',
        code: 500,
        data: {'details': 'Internal error'},
        cause: Exception('Original'),
      );

      expect(error.kind, equals(RpcErrorKind.httpError));
      expect(error.message, equals('HTTP failed'));
      expect(error.code, equals(500));
      expect(error.data, isNotNull);
      expect(error.cause, isNotNull);
    });

    test('fromJsonRpcError creates correct error', () {
      const jsonError = JsonRpcError(
        code: -32600,
        message: 'Invalid Request',
        data: 'Missing params',
      );
      final error = RpcError.fromJsonRpcError(jsonError);

      expect(error.kind, equals(RpcErrorKind.rpcError));
      expect(error.message, equals('Invalid Request'));
      expect(error.code, equals(-32600));
      expect(error.data, equals('Missing params'));
    });

    test('http factory creates HTTP error', () {
      final error = RpcError.http(404, 'Not Found');

      expect(error.kind, equals(RpcErrorKind.httpError));
      expect(error.code, equals(404));
      expect(error.message, equals('Not Found'));
    });

    test('network factory creates network error', () {
      final cause = Exception('Connection refused');
      final error = RpcError.network('Network unavailable', cause);

      expect(error.kind, equals(RpcErrorKind.networkError));
      expect(error.message, equals('Network unavailable'));
      expect(error.cause, equals(cause));
    });

    test('timeout factory creates timeout error', () {
      final error = RpcError.timeout('Request timed out');

      expect(error.kind, equals(RpcErrorKind.timeout));
      expect(error.message, equals('Request timed out'));
    });

    test('parse factory creates parse error', () {
      const cause = FormatException('Invalid JSON');
      final error = RpcError.parse('Failed to parse', cause);

      expect(error.kind, equals(RpcErrorKind.parseError));
      expect(error.message, equals('Failed to parse'));
      expect(error.cause, equals(cause));
    });

    test('equality includes kind, message, code, data', () {
      const error1 = RpcError(
        kind: RpcErrorKind.rpcError,
        message: 'Test',
        code: 100,
        data: 'info',
      );
      const error2 = RpcError(
        kind: RpcErrorKind.rpcError,
        message: 'Test',
        code: 100,
        data: 'info',
      );
      const error3 = RpcError(
        kind: RpcErrorKind.rpcError,
        message: 'Different',
        code: 100,
        data: 'info',
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });

    test('toString includes kind and message', () {
      const error = RpcError(kind: RpcErrorKind.timeout, message: 'Timed out');
      final str = error.toString();

      expect(str, contains('timeout'));
      expect(str, contains('Timed out'));
    });
  });

  group('RpcErrorKind', () {
    test('all error kinds exist', () {
      expect(RpcErrorKind.values, contains(RpcErrorKind.rpcError));
      expect(RpcErrorKind.values, contains(RpcErrorKind.httpError));
      expect(RpcErrorKind.values, contains(RpcErrorKind.networkError));
      expect(RpcErrorKind.values, contains(RpcErrorKind.timeout));
      expect(RpcErrorKind.values, contains(RpcErrorKind.parseError));
      expect(RpcErrorKind.values, contains(RpcErrorKind.cancelled));
      expect(RpcErrorKind.values, contains(RpcErrorKind.runtimeError));
      expect(RpcErrorKind.values, contains(RpcErrorKind.unknown));
    });
  });

  group('RpcException', () {
    test('wraps RpcError correctly', () {
      const error = RpcError(
        kind: RpcErrorKind.rpcError,
        message: 'Test error',
      );
      const exception = RpcException(error);

      expect(exception.error, equals(error));
      expect(exception.toString(), contains('Test error'));
    });
  });
}
