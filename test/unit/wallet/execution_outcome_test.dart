/// Unit tests for ExecutionOutcome and ExecutionStatus types.
///
/// Tests pure logic - no network calls required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('ExecutionStatus', () {
    group('ExecutionStatusSuccessValue', () {
      test('creates with return value', () {
        final status = ExecutionStatus.successValue('base64encodeddata');

        expect(status, isA<ExecutionStatusSuccessValue>());
        expect(
          (status as ExecutionStatusSuccessValue).value,
          equals('base64encodeddata'),
        );
      });

      test('creates with empty value', () {
        final status = ExecutionStatus.successValue('');

        expect((status as ExecutionStatusSuccessValue).value, equals(''));
      });

      test('toJson format', () {
        final status = ExecutionStatus.successValue('data123');

        expect(status.toJson(), equals({'SuccessValue': 'data123'}));
      });

      test('equality', () {
        final s1 = ExecutionStatus.successValue('test');
        final s2 = ExecutionStatus.successValue('test');
        final s3 = ExecutionStatus.successValue('different');

        expect(s1, equals(s2));
        expect(s1, isNot(equals(s3)));
      });
    });

    group('ExecutionStatusSuccessReceiptIds', () {
      test('creates with receipt IDs', () {
        final status = ExecutionStatus.successReceiptIds(['id1', 'id2', 'id3']);

        expect(status, isA<ExecutionStatusSuccessReceiptIds>());
        expect(
          (status as ExecutionStatusSuccessReceiptIds).receiptIds,
          equals(['id1', 'id2', 'id3']),
        );
      });

      test('creates with empty list', () {
        final status = ExecutionStatus.successReceiptIds([]);

        expect(
          (status as ExecutionStatusSuccessReceiptIds).receiptIds,
          isEmpty,
        );
      });

      test('creates with single receipt ID', () {
        final status = ExecutionStatus.successReceiptIds(['single']);

        expect(
          (status as ExecutionStatusSuccessReceiptIds).receiptIds,
          equals(['single']),
        );
      });

      test('toJson format', () {
        final status = ExecutionStatus.successReceiptIds(['r1', 'r2']);

        expect(
          status.toJson(),
          equals({
            'SuccessReceiptId': ['r1', 'r2'],
          }),
        );
      });

      test('equality', () {
        final s1 = ExecutionStatus.successReceiptIds(['a', 'b']);
        final s2 = ExecutionStatus.successReceiptIds(['a', 'b']);
        final s3 = ExecutionStatus.successReceiptIds(['a', 'c']);

        expect(s1, equals(s2));
        expect(s1, isNot(equals(s3)));
      });
    });

    group('ExecutionStatusFailure', () {
      test('creates with error', () {
        const error = ExecutionError(
          errorType: 'ActionError',
          errorMessage: 'Action failed',
        );
        final status = ExecutionStatus.failure(error);

        expect(status, isA<ExecutionStatusFailure>());
        expect((status as ExecutionStatusFailure).error, equals(error));
      });

      test('toJson format', () {
        const error = ExecutionError(
          errorType: 'TestError',
          errorMessage: 'Test message',
        );
        final status = ExecutionStatus.failure(error);

        expect(
          status.toJson(),
          equals({
            'Failure': {
              'error_type': 'TestError',
              'error_message': 'Test message',
            },
          }),
        );
      });

      test('equality', () {
        const error1 = ExecutionError(errorType: 'E1', errorMessage: 'M1');
        const error2 = ExecutionError(errorType: 'E1', errorMessage: 'M1');
        const error3 = ExecutionError(errorType: 'E2', errorMessage: 'M2');

        final s1 = ExecutionStatus.failure(error1);
        final s2 = ExecutionStatus.failure(error2);
        final s3 = ExecutionStatus.failure(error3);

        expect(s1, equals(s2));
        expect(s1, isNot(equals(s3)));
      });
    });

    group('Pattern matching', () {
      test('matches success value', () {
        final status = ExecutionStatus.successValue('data');
        String result;

        switch (status) {
          case ExecutionStatusSuccessValue(:final value):
            result = 'success: $value';
          case ExecutionStatusSuccessReceiptIds(:final receiptIds):
            result = 'receipts: $receiptIds';
          case ExecutionStatusFailure(:final error):
            result = 'failure: ${error.errorMessage}';
        }

        expect(result, equals('success: data'));
      });

      test('matches success receipt IDs', () {
        final status = ExecutionStatus.successReceiptIds(['r1']);
        String result;

        switch (status) {
          case ExecutionStatusSuccessValue(:final value):
            result = 'success: $value';
          case ExecutionStatusSuccessReceiptIds(:final receiptIds):
            result = 'receipts: ${receiptIds.length}';
          case ExecutionStatusFailure(:final error):
            result = 'failure: ${error.errorMessage}';
        }

        expect(result, equals('receipts: 1'));
      });

      test('matches failure', () {
        final status = ExecutionStatus.failure(
          const ExecutionError(errorType: 'Test', errorMessage: 'Failed'),
        );
        String result;

        switch (status) {
          case ExecutionStatusSuccessValue(:final value):
            result = 'success: $value';
          case ExecutionStatusSuccessReceiptIds(:final receiptIds):
            result = 'receipts: $receiptIds';
          case ExecutionStatusFailure(:final error):
            result = 'failure: ${error.errorMessage}';
        }

        expect(result, equals('failure: Failed'));
      });
    });
  });

  group('ExecutionError', () {
    test('creates with required fields', () {
      const error = ExecutionError(
        errorType: 'ActionError',
        errorMessage: 'Execution failed',
      );

      expect(error.errorType, equals('ActionError'));
      expect(error.errorMessage, equals('Execution failed'));
    });

    test('toJson format', () {
      const error = ExecutionError(
        errorType: 'TestError',
        errorMessage: 'Test',
      );

      expect(
        error.toJson(),
        equals({'error_type': 'TestError', 'error_message': 'Test'}),
      );
    });

    test('equality', () {
      const e1 = ExecutionError(errorType: 'E', errorMessage: 'M');
      const e2 = ExecutionError(errorType: 'E', errorMessage: 'M');
      const e3 = ExecutionError(errorType: 'E', errorMessage: 'Different');

      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));
    });
  });

  group('ExecutionOutcome', () {
    test('creates with all fields', () {
      final status = ExecutionStatus.successValue('result');
      final outcome = ExecutionOutcome(
        status: status,
        gasBurnt: BigInt.from(1000000),
        logs: ['Log 1', 'Log 2'],
        receiptIds: ['receipt1', 'receipt2'],
      );

      expect(outcome.status, equals(status));
      expect(outcome.gasBurnt, equals(BigInt.from(1000000)));
      expect(outcome.logs, equals(['Log 1', 'Log 2']));
      expect(outcome.receiptIds, equals(['receipt1', 'receipt2']));
    });

    test('defaults for optional fields', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue(''),
        gasBurnt: BigInt.zero,
      );

      expect(outcome.logs, isEmpty);
      expect(outcome.receiptIds, isEmpty);
    });

    test('toJson format', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue('data'),
        gasBurnt: BigInt.from(500),
        logs: ['log1'],
        receiptIds: ['r1'],
      );

      expect(
        outcome.toJson(),
        equals({
          'status': {'SuccessValue': 'data'},
          'gas_burnt': '500',
          'logs': ['log1'],
          'receipt_ids': ['r1'],
        }),
      );
    });

    test('equality', () {
      final status = ExecutionStatus.successValue('test');
      final o1 = ExecutionOutcome(
        status: status,
        gasBurnt: BigInt.from(100),
        logs: ['a'],
        receiptIds: ['b'],
      );
      final o2 = ExecutionOutcome(
        status: status,
        gasBurnt: BigInt.from(100),
        logs: ['a'],
        receiptIds: ['b'],
      );
      final o3 = ExecutionOutcome(
        status: status,
        gasBurnt: BigInt.from(200),
        logs: ['a'],
        receiptIds: ['b'],
      );

      expect(o1, equals(o2));
      expect(o1, isNot(equals(o3)));
    });
  });

  group('TransactionResult', () {
    test('creates with hash and outcome', () {
      const hash = CryptoHash('txhash123');
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue(''),
        gasBurnt: BigInt.zero,
      );
      final result = TransactionResult(transactionHash: hash, outcome: outcome);

      expect(result.transactionHash, equals(hash));
      expect(result.outcome, equals(outcome));
    });

    test('toJson format', () {
      final result = TransactionResult(
        transactionHash: const CryptoHash('hash'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue('data'),
          gasBurnt: BigInt.from(100),
        ),
      );

      final json = result.toJson();

      expect(json['transaction_hash'], equals('hash'));
      expect(json['outcome'], isNotNull);
      expect(json['outcome']['status'], equals({'SuccessValue': 'data'}));
    });

    test('equality', () {
      const hash = CryptoHash('h');
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue(''),
        gasBurnt: BigInt.zero,
      );

      final r1 = TransactionResult(transactionHash: hash, outcome: outcome);
      final r2 = TransactionResult(transactionHash: hash, outcome: outcome);

      expect(r1, equals(r2));
    });
  });
}
