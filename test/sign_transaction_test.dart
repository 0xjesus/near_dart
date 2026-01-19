import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:near_dart/near_dart.dart';
import 'package:near_dart/near_dart.dart';

class MockWalletAdapter extends Mock implements WalletAdapter {}

class FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransaction());
  });

  group('signAndSendTransaction', () {
    late MockWalletAdapter adapter;

    setUp(() {
      adapter = MockWalletAdapter();
    });

    test('signs and sends transfer transaction', () async {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      when(() => adapter.signAndSendTransaction(
        transaction: any(named: 'transaction'),
      )).thenAnswer((_) async => TransactionResult(
        transactionHash: CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(1000000000000),
        ),
      ));

      final result = await adapter.signAndSendTransaction(transaction: tx);

      expect(result.transactionHash.value, equals('abc123'));
      expect(result.outcome.status, isA<ExecutionStatusSuccessValue>());
    });

    test('signs and sends function call transaction', () async {
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

      when(() => adapter.signAndSendTransaction(
        transaction: any(named: 'transaction'),
      )).thenAnswer((_) async => TransactionResult(
        transactionHash: CryptoHash('def456'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successReceiptIds(['receipt1']),
          gasBurnt: BigInt.from(5000000000000),
        ),
      ));

      final result = await adapter.signAndSendTransaction(transaction: tx);

      expect(result.transactionHash.value, equals('def456'));
    });

    test('handles transaction failure', () async {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1000000))],
      );

      when(() => adapter.signAndSendTransaction(
        transaction: any(named: 'transaction'),
      )).thenAnswer((_) async => TransactionResult(
        transactionHash: CryptoHash('failed123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.failure(
            ExecutionError(errorType: 'NotEnoughBalance', errorMessage: 'Insufficient funds'),
          ),
          gasBurnt: BigInt.from(1000000000000),
        ),
      ));

      final result = await adapter.signAndSendTransaction(transaction: tx);

      expect(result.outcome.status, isA<ExecutionStatusFailure>());
      final failure = result.outcome.status as ExecutionStatusFailure;
      expect(failure.error.errorType, equals('NotEnoughBalance'));
    });
  });

  group('signAndSendTransactions', () {
    late MockWalletAdapter adapter;

    setUp(() {
      adapter = MockWalletAdapter();
    });

    test('signs and sends multiple transactions', () async {
      final transactions = [
        Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
        ),
        Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('carol.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(2))],
        ),
      ];

      when(() => adapter.signAndSendTransactions(
        transactions: any(named: 'transactions'),
      )).thenAnswer((_) async => [
        TransactionResult(
          transactionHash: CryptoHash('tx1'),
          outcome: ExecutionOutcome(
            status: ExecutionStatus.successValue(''),
            gasBurnt: BigInt.from(1000000000000),
          ),
        ),
        TransactionResult(
          transactionHash: CryptoHash('tx2'),
          outcome: ExecutionOutcome(
            status: ExecutionStatus.successValue(''),
            gasBurnt: BigInt.from(1000000000000),
          ),
        ),
      ]);

      final results = await adapter.signAndSendTransactions(
        transactions: transactions,
      );

      expect(results, hasLength(2));
      expect(results[0].transactionHash.value, equals('tx1'));
      expect(results[1].transactionHash.value, equals('tx2'));
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
          ExecutionError(
            errorType: 'ActionError',
            errorMessage: 'Account does not exist',
          ),
        ),
        gasBurnt: BigInt.from(1000000000000),
      );

      expect(outcome.status, isA<ExecutionStatusFailure>());
    });
  });

  group('TransactionResult', () {
    test('serializes to JSON correctly', () {
      final result = TransactionResult(
        transactionHash: CryptoHash('abc123'),
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
        transactionHash: CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(1000),
        ),
      );

      final result2 = TransactionResult(
        transactionHash: CryptoHash('abc123'),
        outcome: ExecutionOutcome(
          status: ExecutionStatus.successValue(''),
          gasBurnt: BigInt.from(1000),
        ),
      );

      expect(result1, equals(result2));
    });
  });
}
