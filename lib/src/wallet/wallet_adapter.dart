import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:near_dart/near_dart.dart';

import 'execution_outcome.dart';
import 'transaction.dart';

/// Types of wallet connections.
enum WalletType {
  /// Web browser wallet (redirects for signing).
  browser,

  /// Injected wallet (browser extension).
  injected,

  /// Hardware wallet (Ledger, etc.).
  hardware,

  /// Bridge wallet (WalletConnect, etc.).
  bridge,

  /// Instant link wallet.
  instantLink,
}

/// A connected wallet account.
@immutable
class WalletAccount extends Equatable {
  const WalletAccount({
    required this.accountId,
    required this.publicKey,
  });

  /// The account ID.
  final AccountId accountId;

  /// The public key for this account.
  final PublicKey publicKey;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'accountId': accountId.value,
        'publicKey': publicKey.value,
      };

  @override
  List<Object?> get props => [accountId, publicKey];
}

/// Parameters for signing a message (NEP-413).
@immutable
class SignMessageParams extends Equatable {
  SignMessageParams({
    required this.message,
    required this.recipient,
    required this.nonce,
    this.callbackUrl,
    this.state,
  }) {
    if (nonce.length != 32) {
      throw ArgumentError('Nonce must be exactly 32 bytes');
    }
  }

  /// The message to sign.
  final String message;

  /// The intended recipient (e.g., "myapp.com" or "alice.near").
  final String recipient;

  /// A 32-byte unique nonce.
  final List<int> nonce;

  /// Optional callback URL for browser wallets.
  final String? callbackUrl;

  /// Optional state for CSRF protection.
  final String? state;

  @override
  List<Object?> get props => [message, recipient, nonce, callbackUrl, state];
}

/// A signed message (NEP-413 response).
@immutable
class SignedMessage extends Equatable {
  const SignedMessage({
    required this.accountId,
    required this.publicKey,
    required this.signature,
    this.state,
  });

  /// The signing account.
  final AccountId accountId;

  /// The public key used.
  final PublicKey publicKey;

  /// The base64-encoded signature.
  final String signature;

  /// Optional state echoed from request.
  final String? state;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'accountId': accountId.value,
        'publicKey': publicKey.value,
        'signature': signature,
        if (state != null) 'state': state,
      };

  @override
  List<Object?> get props => [accountId, publicKey, signature, state];
}

/// Abstract interface for wallet adapters.
///
/// Implementations include:
/// - [WalletConnectAdapter] for WalletConnect protocol
/// - [DeepLinkWalletAdapter] for mobile deep links
abstract class WalletAdapter {
  /// Unique identifier for this wallet.
  String get id;

  /// The type of wallet.
  WalletType get type;

  /// Human-readable name.
  String get name;

  /// Icon URL for the wallet.
  String? get iconUrl;

  /// Signs in to the wallet.
  ///
  /// [contractId] - The contract to request access for.
  /// [methodNames] - Optional list of methods to restrict access to.
  ///
  /// Returns the connected accounts.
  Future<List<WalletAccount>> signIn({
    required AccountId contractId,
    List<String>? methodNames,
  });

  /// Signs out from the wallet.
  Future<void> signOut();

  /// Gets the currently connected accounts.
  Future<List<WalletAccount>> getAccounts();

  /// Checks if there is an active session.
  Future<bool> isSignedIn();

  /// Signs and sends a single transaction.
  ///
  /// [transaction] - The transaction to sign and send.
  /// [callbackUrl] - Optional callback URL for browser wallets.
  ///
  /// Returns the transaction result.
  Future<TransactionResult> signAndSendTransaction({
    required Transaction transaction,
    String? callbackUrl,
  });

  /// Signs and sends multiple transactions.
  ///
  /// [transactions] - The transactions to sign and send.
  /// [callbackUrl] - Optional callback URL for browser wallets.
  ///
  /// Returns the results for each transaction.
  Future<List<TransactionResult>> signAndSendTransactions({
    required List<Transaction> transactions,
    String? callbackUrl,
  });

  /// Signs a message according to NEP-413.
  ///
  /// This can be used for authentication without blockchain interaction.
  ///
  /// [params] - The message parameters.
  ///
  /// Returns the signed message.
  Future<SignedMessage> signMessage(SignMessageParams params);

  /// Verifies account ownership.
  ///
  /// This signs a message to prove the user owns the account.
  ///
  /// [message] - Custom message to sign.
  ///
  /// Returns the verification result.
  Future<SignedMessage> verifyOwner({
    required String message,
    String? callbackUrl,
  });

  /// Cleans up resources.
  void dispose();
}
