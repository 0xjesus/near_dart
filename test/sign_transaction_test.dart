/// Tests for transaction signing and execution outcome types.
///
/// Pure unit tests - no mocks, no network required.
library;

import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('Transaction', () {
    test('creates transfer transaction', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      expect(tx.signerId.value, equals('alice.near'));
      expect(tx.receiverId.value, equals('bob.near'));
      expect(tx.actions.length, equals(1));
      expect(tx.actions.first, isA<TransferAction>());
    });

    test('creates function call transaction', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('contract.near'),
        actions: [
          FunctionCallAction(
            methodName: 'ft_transfer',
            args: {'receiver_id': 'bob.near', 'amount': '1000000'},
            deposit: NearToken.oneYocto(),
          ),
        ],
      );

      expect(tx.receiverId.value, equals('contract.near'));
      final action = tx.actions.first as FunctionCallAction;
      expect(action.methodName, equals('ft_transfer'));
    });

    test('creates multi-action transaction', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [
          TransferAction(deposit: NearToken.fromNear(1)),
          TransferAction(deposit: NearToken.fromNear(2)),
        ],
      );

      expect(tx.actions.length, equals(2));
    });

    test('serializes to JSON correctly', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      final json = tx.toJson();
      expect(json['signerId'], equals('alice.near'));
      expect(json['receiverId'], equals('bob.near'));
      expect(json['actions'], isA<List>());
    });

    test('equality works correctly', () {
      final tx1 = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      final tx2 = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      expect(tx1, equals(tx2));
    });
  });

  group('ExecutionOutcome', () {
    test('creates success value outcome', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue('result_data'),
        gasBurnt: BigInt.from(2500000000000),
      );

      expect(outcome.status, isA<ExecutionStatusSuccessValue>());
      expect(outcome.gasBurnt, equals(BigInt.from(2500000000000)));
    });

    test('creates success receipt ids outcome', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successReceiptIds(['receipt1', 'receipt2']),
        gasBurnt: BigInt.from(3000000000000),
      );

      expect(outcome.status, isA<ExecutionStatusSuccessReceiptIds>());
      final status = outcome.status as ExecutionStatusSuccessReceiptIds;
      expect(status.receiptIds, hasLength(2));
    });

    test('creates failure outcome', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.failure(
          const ExecutionError(
            errorType: 'ActionError',
            errorMessage: 'Account does not exist',
          ),
        ),
        gasBurnt: BigInt.from(1000000000000),
      );

      expect(outcome.status, isA<ExecutionStatusFailure>());
    });

    test('includes logs', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue(''),
        gasBurnt: BigInt.zero,
        logs: ['Log entry 1', 'Log entry 2'],
      );

      expect(outcome.logs, hasLength(2));
    });

    test('includes receipt IDs', () {
      final outcome = ExecutionOutcome(
        status: ExecutionStatus.successValue(''),
        gasBurnt: BigInt.zero,
        receiptIds: ['receipt1', 'receipt2'],
      );

      expect(outcome.receiptIds, hasLength(2));
    });
  });

  group('TransactionResult', () {
    test('creates with hash and outcome', () {
      final result = TransactionResult(
        transactionHash: const CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(2500000000000),
        ),
      );

      expect(result.transactionHash.value, equals('abc123'));
      expect(result.outcome.status, isA<ExecutionStatusSuccessValue>());
    });

    test('serializes to JSON correctly', () {
      final result = TransactionResult(
        transactionHash: const CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(2500000000000),
        ),
      );

      final json = result.toJson();
      expect(json['transaction_hash'], equals('abc123'));
      expect(json['outcome']['gas_burnt'], equals('2500000000000'));
    });

    test('value equality works', () {
      final result1 = TransactionResult(
        transactionHash: const CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(1000),
        ),
      );

      final result2 = TransactionResult(
        transactionHash: const CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(1000),
        ),
      );

      expect(result1, equals(result2));
    });
  });

  group('ExecutionError', () {
    test('creates with type and message', () {
      const error = ExecutionError(
        errorType: 'NotEnoughBalance',
        errorMessage: 'Insufficient funds for transfer',
      );

      expect(error.errorType, equals('NotEnoughBalance'));
      expect(error.errorMessage, equals('Insufficient funds for transfer'));
    });

    test('serializes to JSON', () {
      const error = ExecutionError(
        errorType: 'TestError',
        errorMessage: 'Test message',
      );

      final json = error.toJson();
      expect(json['error_type'], equals('TestError'));
      expect(json['error_message'], equals('Test message'));
    });
  });
}
