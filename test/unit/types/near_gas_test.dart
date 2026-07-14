import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  test('exposes exact TGas and default function-call gas values', () {
    final oneTeraGas = BigInt.from(10).pow(12);

    expect(NearGas.oneTeraGas, oneTeraGas);
    expect(NearGas.defaultFunctionCall, oneTeraGas * BigInt.from(30));
    expect(NearGas.teraGas(100), oneTeraGas * BigInt.from(100));
  });

  test('rejects negative TGas amounts', () {
    expect(() => NearGas.teraGas(-1), throwsRangeError);
  });

  test('FunctionCallAction uses the public default gas value', () {
    final action = FunctionCallAction(
      methodName: 'ping',
      args: const {},
      deposit: NearToken.zero(),
    );

    expect(action.gas, NearGas.defaultFunctionCall);
  });
}
