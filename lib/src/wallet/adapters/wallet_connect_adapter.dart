import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:near_dart/near_dart.dart';

/// Configuration for WalletConnect adapter.
class WalletConnectConfig {
  const WalletConnectConfig({
    required this.projectId,
    required this.appName,
    required this.appDescription,
    required this.appUrl,
    this.appIconUrl,
    this.network = NearNetwork.mainnet,
  });

  /// WalletConnect project ID from cloud.walletconnect.com
  final String projectId;

  /// App name for wallet display.
  final String appName;

  /// App description.
  final String appDescription;

  /// App URL.
  final String appUrl;

  /// App icon URL.
  final String? appIconUrl;

  /// NEAR network to connect to.
  final NearNetwork network;
}

/// NEAR network configuration.
enum NearNetwork {
  mainnet('mainnet', 'near:mainnet'),
  testnet('testnet', 'near:testnet');

  const NearNetwork(this.name, this.chainId);
  final String name;
  final String chainId;
}

/// WalletConnect session data.
class WalletConnectSession {
  const WalletConnectSession({
    required this.topic,
    required this.accounts,
    this.expiry,
  });

  /// The session topic.
  final String topic;

  /// Connected account IDs.
  final List<String> accounts;

  /// Session expiry timestamp.
  final int? expiry;
}

/// Abstract WalletConnect adapter for NEAR Protocol.
///
/// This is an abstract class that defines the interface for WalletConnect
/// integration. Implement this class with your preferred WalletConnect library
/// (e.g., reown_appkit, walletconnect_flutter_v2).
///
/// Example implementation:
/// ```dart
/// class MyWalletConnectAdapter extends WalletConnectAdapterBase {
///   // Implement using reown_appkit or another WalletConnect library
///   @override
///   Future<String> createPairingUri() async {
///     // Use your WalletConnect library to create pairing
///   }
/// }
/// ```
abstract class WalletConnectAdapterBase implements WalletAdapter {
  WalletConnectAdapterBase({required this.config});

  /// Configuration for this adapter.
  final WalletConnectConfig config;

  /// Current session, if connected.
  WalletConnectSession? session;

  @override
  String get id => 'walletconnect';

  @override
  WalletType get type => WalletType.bridge;

  @override
  String get name => 'WalletConnect';

  @override
  String? get iconUrl =>
      'https://avatars.githubusercontent.com/u/37784886?s=200&v=4';

  /// Creates a pairing URI for connecting to a wallet.
  ///
  /// The returned URI can be displayed as a QR code or used with deep links.
  Future<String> createPairingUri();

  /// Waits for a wallet to connect.
  Future<void> waitForConnection({Duration? timeout});

  /// Sends a JSON-RPC request to the connected wallet.
  ///
  /// [method] - The RPC method name (e.g., 'near_signTransaction')
  /// [params] - The method parameters
  Future<dynamic> sendRequest(String method, dynamic params);

  @override
  Future<List<WalletAccount>> signIn({
    required AccountId contractId,
    List<String>? methodNames,
  }) async {
    if (session == null) {
      throw StateError(
        'No active WalletConnect session. Call createPairingUri first.',
      );
    }
    return getAccounts();
  }

  @override
  Future<void> signOut();

  @override
  Future<List<WalletAccount>> getAccounts() async {
    if (session == null) return [];

    return session!.accounts.map((account) {
      // Format may be: near:mainnet:alice.near or just alice.near
      final accountId = account.contains(':')
          ? account.split(':').last
          : account;

      return WalletAccount(
        accountId: AccountId(accountId),
        publicKey: PublicKey('ed25519:placeholder'),
      );
    }).toList();
  }

  @override
  Future<bool> isSignedIn() async => session != null;

  @override
  Future<TransactionResult> signAndSendTransaction({
    required Transaction transaction,
    String? callbackUrl,
  }) async {
    if (session == null) {
      throw StateError('No active WalletConnect session');
    }

    final response = await sendRequest('near_signTransaction', [
      transaction.toJson(),
    ]);

    return _parseTransactionResult(response);
  }

  @override
  Future<List<TransactionResult>> signAndSendTransactions({
    required List<Transaction> transactions,
    String? callbackUrl,
  }) async {
    if (session == null) {
      throw StateError('No active WalletConnect session');
    }

    final response = await sendRequest(
      'near_signTransactions',
      transactions.map((t) => t.toJson()).toList(),
    );

    if (response is List) {
      return response.map(_parseTransactionResult).toList();
    }

    return [_parseTransactionResult(response)];
  }

  @override
  Future<SignedMessage> signMessage(SignMessageParams params) async {
    if (session == null) {
      throw StateError('No active WalletConnect session');
    }

    final response = await sendRequest('near_signMessage', {
      'message': params.message,
      'recipient': params.recipient,
      'nonce': base64Encode(params.nonce),
      if (params.callbackUrl != null) 'callbackUrl': params.callbackUrl,
      if (params.state != null) 'state': params.state,
    });

    final json = response as Map<String, dynamic>;
    return SignedMessage(
      accountId: AccountId(json['accountId'] as String),
      publicKey: PublicKey(json['publicKey'] as String),
      signature: json['signature'] as String,
      state: json['state'] as String?,
    );
  }

  @override
  Future<SignedMessage> verifyOwner({
    required String message,
    String? callbackUrl,
  }) async {
    final random = Random.secure();
    final nonce = List<int>.generate(32, (_) => random.nextInt(256));

    return signMessage(
      SignMessageParams(
        message: message,
        recipient: 'verify-owner',
        nonce: nonce,
        callbackUrl: callbackUrl,
      ),
    );
  }

  /// Parses a transaction result from WalletConnect response.
  TransactionResult _parseTransactionResult(dynamic response) {
    final json = response as Map<String, dynamic>;

    final statusJson = json['status'] ?? json['outcome']?['status'];
    ExecutionStatus status;

    if (statusJson is Map) {
      if (statusJson.containsKey('SuccessValue')) {
        status = ExecutionStatus.successValue(
          statusJson['SuccessValue'] as String,
        );
      } else if (statusJson.containsKey('SuccessReceiptId')) {
        final ids = statusJson['SuccessReceiptId'];
        status = ExecutionStatus.successReceiptIds(
          ids is List ? ids.cast<String>() : [ids as String],
        );
      } else if (statusJson.containsKey('Failure')) {
        final failure = statusJson['Failure'] as Map<String, dynamic>;
        status = ExecutionStatus.failure(
          ExecutionError(
            errorType: failure['error_type'] as String? ?? 'Unknown',
            errorMessage:
                failure['error_message'] as String? ?? 'Unknown error',
          ),
        );
      } else {
        status = ExecutionStatus.successValue('');
      }
    } else {
      status = ExecutionStatus.successValue('');
    }

    return TransactionResult(
      transactionHash: CryptoHash(json['transaction_hash'] as String? ?? ''),
      outcome: ExecutionOutcome(
        status: status,
        gasBurnt:
            BigInt.tryParse(json['gas_burnt']?.toString() ?? '0') ??
            BigInt.zero,
        logs: (json['logs'] as List?)?.cast<String>() ?? [],
      ),
    );
  }

  @override
  void dispose();
}

/// NEAR-specific RPC methods for WalletConnect.
class NearWalletConnectMethods {
  /// Sign a single transaction.
  static const signTransaction = 'near_signTransaction';

  /// Sign multiple transactions.
  static const signTransactions = 'near_signTransactions';

  /// Sign a message (NEP-413).
  static const signMessage = 'near_signMessage';

  /// Get connected accounts.
  static const getAccounts = 'near_getAccounts';
}

/// Required namespaces for NEAR WalletConnect connection.
class NearWalletConnectNamespace {
  /// Creates the required namespace for NEAR.
  static Map<String, dynamic> create(NearNetwork network) {
    return {
      'near': {
        'chains': [network.chainId],
        'methods': [
          NearWalletConnectMethods.signTransaction,
          NearWalletConnectMethods.signTransactions,
          NearWalletConnectMethods.signMessage,
          NearWalletConnectMethods.getAccounts,
        ],
        'events': ['chainChanged', 'accountsChanged'],
      },
    };
  }
}
