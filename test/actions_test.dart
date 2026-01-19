import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('Action', () {
    group('CreateAccountAction', () {
      test('serializes to JSON correctly', () {
        final action = CreateAccountAction();
        expect(action.toJson(), equals({'CreateAccount': {}}));
      });

      test('has correct type', () {
        final action = CreateAccountAction();
        expect(action.type, equals(ActionType.createAccount));
      });
    });

    group('DeployContractAction', () {
      test('serializes to JSON correctly', () {
        final code = [1, 2, 3, 4, 5];
        final action = DeployContractAction(code: code);
        expect(action.toJson(), equals({
          'DeployContract': {'code': code},
        }));
      });

      test('has correct type', () {
        final action = DeployContractAction(code: []);
        expect(action.type, equals(ActionType.deployContract));
      });
    });

    group('FunctionCallAction', () {
      test('serializes to JSON with empty args', () {
        final action = FunctionCallAction(
          methodName: 'get_balance',
          gas: BigInt.from(30000000000000),
          deposit: NearToken.zero(),
        );

        final json = action.toJson();
        expect(json['FunctionCall']['method_name'], equals('get_balance'));
        expect(json['FunctionCall']['gas'], equals('30000000000000'));
        expect(json['FunctionCall']['deposit'], equals('0'));
        expect(json['FunctionCall']['args'], equals(''));
      });

      test('serializes to JSON with JSON args', () {
        final action = FunctionCallAction(
          methodName: 'ft_transfer',
          args: {'receiver_id': 'bob.near', 'amount': '1000'},
          gas: BigInt.from(30000000000000),
          deposit: NearToken.oneYocto(),
        );

        final json = action.toJson();
        expect(json['FunctionCall']['method_name'], equals('ft_transfer'));
        expect(json['FunctionCall']['args'], isNotEmpty);
        expect(json['FunctionCall']['deposit'], equals('1'));
      });

      test('has correct type', () {
        final action = FunctionCallAction(
          methodName: 'test',
          gas: BigInt.zero,
          deposit: NearToken.zero(),
        );
        expect(action.type, equals(ActionType.functionCall));
      });

      test('default gas is 30 TGas', () {
        final action = FunctionCallAction(
          methodName: 'test',
          deposit: NearToken.zero(),
        );
        expect(action.gas, equals(BigInt.from(30) * BigInt.from(10).pow(12)));
      });
    });

    group('TransferAction', () {
      test('serializes to JSON correctly', () {
        final action = TransferAction(
          deposit: NearToken.fromNear(1),
        );

        final json = action.toJson();
        expect(json['Transfer']['deposit'], equals('1000000000000000000000000'));
      });

      test('has correct type', () {
        final action = TransferAction(deposit: NearToken.zero());
        expect(action.type, equals(ActionType.transfer));
      });
    });

    group('StakeAction', () {
      test('serializes to JSON correctly', () {
        final action = StakeAction(
          stake: NearToken.fromNear(100),
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );

        final json = action.toJson();
        expect(json['Stake']['stake'], equals('100000000000000000000000000'));
        expect(json['Stake']['public_key'], contains('ed25519:'));
      });

      test('has correct type', () {
        final action = StakeAction(
          stake: NearToken.zero(),
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );
        expect(action.type, equals(ActionType.stake));
      });
    });

    group('AddKeyAction', () {
      test('serializes full access key to JSON', () {
        final action = AddKeyAction(
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
          accessKey: FullAccessKey(),
        );

        final json = action.toJson();
        expect(json['AddKey']['public_key'], contains('ed25519:'));
        expect(
          json['AddKey']['access_key']['permission'],
          equals('FullAccess'),
        );
      });

      test('serializes function call access key to JSON', () {
        final action = AddKeyAction(
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
          accessKey: FunctionCallAccessKey(
            receiverId: AccountId('contract.near'),
            methodNames: ['get_balance', 'ft_transfer'],
            allowance: NearToken.fromNear(1),
          ),
        );

        final json = action.toJson();
        final permission = json['AddKey']['access_key']['permission'];
        expect(permission['FunctionCall']['receiver_id'], equals('contract.near'));
        expect(permission['FunctionCall']['method_names'], contains('get_balance'));
        expect(permission['FunctionCall']['allowance'], equals('1000000000000000000000000'));
      });

      test('has correct type', () {
        final action = AddKeyAction(
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
          accessKey: FullAccessKey(),
        );
        expect(action.type, equals(ActionType.addKey));
      });
    });

    group('DeleteKeyAction', () {
      test('serializes to JSON correctly', () {
        final action = DeleteKeyAction(
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );

        final json = action.toJson();
        expect(json['DeleteKey']['public_key'], contains('ed25519:'));
      });

      test('has correct type', () {
        final action = DeleteKeyAction(
          publicKey: PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp'),
        );
        expect(action.type, equals(ActionType.deleteKey));
      });
    });

    group('DeleteAccountAction', () {
      test('serializes to JSON correctly', () {
        final action = DeleteAccountAction(
          beneficiaryId: AccountId('beneficiary.near'),
        );

        final json = action.toJson();
        expect(json['DeleteAccount']['beneficiary_id'], equals('beneficiary.near'));
      });

      test('has correct type', () {
        final action = DeleteAccountAction(
          beneficiaryId: AccountId('beneficiary.near'),
        );
        expect(action.type, equals(ActionType.deleteAccount));
      });
    });
  });
}
