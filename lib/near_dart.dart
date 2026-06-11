/// NEAR Protocol SDK for Flutter/Dart.
///
/// A complete SDK for building NEAR Protocol applications with Flutter.
///
/// ## Features
///
/// - **Local signing & sending**: [KeyPairEd25519], [signTransaction],
///   [Account] — Borsh + ed25519, byte-for-byte compatible with near-api-js
/// - **Type-safe primitives**: [AccountId], [NearToken], [PublicKey], [CryptoHash]
/// - **RPC Client**: [NearRpcClient] for queries and `send_tx` broadcasting
/// - **Wallet Integration**: [WalletAdapter] for external wallet flows
///
/// ## Quick Start
///
/// ```dart
/// import 'package:near_dart/near_dart.dart';
///
/// void main() async {
///   final client = NearRpcClient.testnet();
///
///   // Query state (no key needed)
///   final result = await client.viewAccount(
///     accountId: AccountId('alice.testnet'),
///     blockReference: BlockReference.finality(Finality.final_),
///   );
///   if (result.isSuccess) {
///     print('Balance: ${result.getOrNull()!.amount.toNear()} NEAR');
///   }
///
///   // Execute transactions with a local key
///   final account = Account(
///     accountId: AccountId('alice.testnet'),
///     keyPair: await KeyPairEd25519.fromString('ed25519:...'),
///     client: client,
///   );
///   await account.transfer(
///     receiverId: AccountId('bob.testnet'),
///     amount: NearToken.fromNear(1),
///   );
///
///   client.close();
/// }
/// ```
library near_dart;

// Types
export 'src/types/primitives.dart';
export 'src/types/block_reference.dart';
export 'src/types/json_rpc.dart';
export 'src/types/rpc_result.dart';

// Encoding
export 'src/encoding/base58.dart';

// Crypto
export 'src/crypto/key_pair.dart';
export 'src/crypto/sign.dart';

// High-level account API
export 'src/account/account.dart';

// Borsh serialization
export 'src/borsh/borsh_writer.dart';
export 'src/borsh/transaction_serializer.dart';

// Client
export 'src/client/near_rpc_client.dart';
export 'src/client/responses/status_response.dart';
export 'src/client/responses/block_response.dart';
export 'src/client/responses/account_response.dart';
export 'src/client/responses/call_function_response.dart';
export 'src/client/responses/validators_response.dart';
export 'src/client/responses/gas_price_response.dart';
// ExecutionOutcome is hidden to avoid a conflict with the wallet module;
// access receipt outcomes through ExecutionOutcomeWithId.outcome.
export 'src/client/responses/transaction_response.dart' hide ExecutionOutcome;
export 'src/client/responses/chunk_response.dart';

// Wallet
export 'src/wallet/actions.dart';
export 'src/wallet/transaction.dart';
export 'src/wallet/execution_outcome.dart';
export 'src/wallet/wallet_adapter.dart';
export 'src/wallet/adapters/wallet_connect_adapter.dart';
export 'src/wallet/adapters/my_near_wallet_adapter.dart';
