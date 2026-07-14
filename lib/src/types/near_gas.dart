/// Exact NEAR gas values represented in gas units.
///
/// NEAR commonly presents gas in teragas (TGas), where 1 TGas is 10^12 gas.
/// SDK transaction APIs continue to accept [BigInt], so these values can be
/// passed directly without conversion or precision loss.
abstract final class NearGas {
  /// One teragas in raw gas units.
  static final BigInt oneTeraGas = BigInt.from(10).pow(12);

  /// The SDK default for a function-call action: 30 TGas.
  static final BigInt defaultFunctionCall = teraGas(30);

  /// Converts a non-negative [amount] of TGas to raw gas units.
  static BigInt teraGas(int amount) {
    RangeError.checkNotNegative(amount, 'amount');
    return BigInt.from(amount) * oneTeraGas;
  }
}
