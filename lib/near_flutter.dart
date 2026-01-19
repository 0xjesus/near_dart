/// NEAR Protocol SDK for Flutter/Dart.
///
/// A complete SDK for building NEAR Protocol applications with Flutter.
///
/// ## Features
///
/// - **Type-safe primitives**: [AccountId], [NearToken], [PublicKey], [CryptoHash]
/// - **RPC Client**: [NearRpcClient] for blockchain queries
/// - **Wallet Integration**: [WalletAdapter] for signing transactions
///
/// ## Quick Start
///
/// ```dart
/// import 'package:near_flutter/near_flutter.dart';
///
/// void main() async {
///   // Create client
///   final client = NearRpcClient.mainnet();
///
///   // Query account
///   final result = await client.viewAccount(
///     accountId: AccountId('alice.near'),
///     blockReference: BlockReference.finality(Finality.final_),
///   );
///
///   if (result.isSuccess) {
///     print('Balance: ${result.getOrNull()!.amount.toNear()} NEAR');
///   }
///
///   client.close();
/// }
/// ```
library near_flutter;

// Types
export 'src/types/primitives.dart';
export 'src/types/block_reference.dart';
export 'src/types/json_rpc.dart';
export 'src/types/rpc_result.dart';

// Client
export 'src/client/near_rpc_client.dart';
export 'src/client/responses/status_response.dart';
export 'src/client/responses/block_response.dart';
export 'src/client/responses/account_response.dart';
export 'src/client/responses/call_function_response.dart';
export 'src/client/responses/validators_response.dart';
export 'src/client/responses/gas_price_response.dart';
// transaction_response.dart not exported to avoid ExecutionOutcome conflict
// Use TransactionResult from wallet module for transaction outcomes
export 'src/client/responses/chunk_response.dart';

// Wallet
export 'src/wallet/actions.dart';
export 'src/wallet/transaction.dart';
export 'src/wallet/execution_outcome.dart';
export 'src/wallet/wallet_adapter.dart';
export 'src/wallet/adapters/wallet_connect_adapter.dart';
export 'src/wallet/adapters/my_near_wallet_adapter.dart';
