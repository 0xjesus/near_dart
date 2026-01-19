import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Response from the `gas_price` RPC method.
///
/// Contains the gas price at a specific block.
@immutable
class GasPriceResponse extends Equatable {
  const GasPriceResponse({
    required this.gasPrice,
  });

  factory GasPriceResponse.fromJson(Map<String, dynamic> json) {
    return GasPriceResponse(
      gasPrice: BigInt.parse(json['gas_price'] as String),
    );
  }

  /// The gas price in yoctoNEAR.
  final BigInt gasPrice;

  @override
  List<Object?> get props => [gasPrice];
}
