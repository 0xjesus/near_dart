import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('Transaction', () {
    test('creates transaction with single action', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      expect(tx.signerId.value, equals('alice.near'));
      expect(tx.receiverId.value, equals('bob.near'));
      expect(tx.actions, hasLength(1));
    });

    test('creates transaction with multiple actions', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('contract.near'),
        actions: [
          FunctionCallAction(
            methodName: 'storage_deposit',
            deposit: NearToken.fromNear(1),
          ),
          FunctionCallAction(
            methodName: 'ft_transfer',
            args: {'receiver_id': 'bob.near', 'amount': '1000'},
            deposit: NearToken.oneYocto(),
          ),
        ],
      );

      expect(tx.actions, hasLength(2));
      expect(tx.actions[0].type, equals(ActionType.functionCall));
      expect(tx.actions[1].type, equals(ActionType.functionCall));
    });

    test('serializes to JSON correctly', () {
      final tx = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(5))],
      );

      final json = tx.toJson();
      expect(json['signerId'], equals('alice.near'));
      expect(json['receiverId'], equals('bob.near'));
      expect(json['actions'], hasLength(1));
      expect(json['actions'][0]['Transfer'], isNotNull);
    });

    test('value equality works correctly', () {
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

    test('different transactions are not equal', () {
      final tx1 = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(1))],
      );

      final tx2 = Transaction(
        signerId: AccountId('alice.near'),
        receiverId: AccountId('bob.near'),
        actions: [TransferAction(deposit: NearToken.fromNear(2))],
      );

      expect(tx1, isNot(equals(tx2)));
    });
  });

  group('SignedTransaction', () {
    test('creates signed transaction', () {
      final signedTx = SignedTransaction(
        transaction: Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
        ),
        signature: 'ed25519:abc123...',
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      expect(signedTx.transaction.signerId.value, equals('alice.near'));
      expect(signedTx.signature, equals('ed25519:abc123...'));
    });

    test('serializes to JSON correctly', () {
      final signedTx = SignedTransaction(
        transaction: Transaction(
          signerId: AccountId('alice.near'),
          receiverId: AccountId('bob.near'),
          actions: [TransferAction(deposit: NearToken.fromNear(1))],
        ),
        signature: 'ed25519:abc123...',
        publicKey: PublicKey(
          'ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp',
        ),
      );

      final json = signedTx.toJson();
      expect(json['transaction'], isNotNull);
      expect(json['signature'], equals('ed25519:abc123...'));
      expect(json['public_key'], contains('ed25519:'));
    });
  });
}
