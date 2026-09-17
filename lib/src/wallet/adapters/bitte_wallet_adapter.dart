import 'dart:convert';

import '../../diagnostics/near_errors.dart';
import '../../types/network.dart';
import '../../types/primitives.dart';
import '../wallet_adapter.dart' show WalletAccount;

/// Configuration for [BitteWalletAdapter].
class BitteWalletConfig {
  const BitteWalletConfig({
    required this.successUrl,
    required this.failureUrl,
    this.network = NearNetwork.mainnet,
  });

  /// Redirect after a successful connect or sign.
  final String successUrl;

  /// Redirect after a failed connect.
  final String failureUrl;

  /// Network whose Bitte wallet URL is used.
  final NearNetwork network;

  /// Bitte wallet origin for [network].
  String get walletUrl => network.name == 'testnet'
      ? 'https://testnet.wallet.bitte.ai'
      : 'https://wallet.bitte.ai';
}

/// Bitte Wallet (Mintbase) redirect adapter.
///
/// Connect uses `/connect?success_url=` and returns `account_id` +
/// `public_key`. Transactions use `/sign-transaction?transactions_data=`
/// with wallet-selector JSON and return `transactionHashes`.
///
/// Unlike MyNearWallet, Bitte connect does **not** provision a local
/// function-call key — later payments stay in the wallet.
class BitteWalletAdapter {
  BitteWalletAdapter({required this.config, required this.launchUrl});

  final BitteWalletConfig config;
  final Future<bool> Function(Uri uri) launchUrl;

  /// `/connect` URL Bitte documents for account visibility.
  Uri buildConnectUrl({String? successUrl, String? failureUrl}) {
    return Uri.parse(config.walletUrl).replace(
      path: '/connect',
      queryParameters: {
        'success_url': successUrl ?? config.successUrl,
        if ((failureUrl ?? config.failureUrl).isNotEmpty)
          'failure_url': failureUrl ?? config.failureUrl,
      },
    );
  }

  /// `/sign-transaction` URL with wallet-selector JSON transactions.
  Uri buildSignTransactionUrl({
    required List<Map<String, dynamic>> transactions,
    String? callbackUrl,
  }) {
    if (transactions.isEmpty) {
      throw const BitteWalletException.invalidInput();
    }
    return Uri.parse(config.walletUrl).replace(
      path: '/sign-transaction',
      queryParameters: {
        'transactions_data': jsonEncode(transactions),
        'callback_url': callbackUrl ?? config.successUrl,
      },
    );
  }

  /// Opens Bitte connect. The account arrives on [completeConnect].
  Future<void> signIn() async {
    final launched = await launchUrl(buildConnectUrl());
    if (!launched) throw const BitteWalletException.deepLink();
  }

  /// Opens Bitte to sign [transactions]. Hashes arrive on
  /// [completeSignTransactions].
  Future<void> requestSignTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    final launched = await launchUrl(
      buildSignTransactionUrl(transactions: transactions),
    );
    if (!launched) throw const BitteWalletException.deepLink();
  }

  /// Parses a Bitte connect callback.
  WalletAccount completeConnect(Uri callbackUri) {
    final callback = BitteWalletCallback.fromUri(callbackUri);
    if (callback.isError) throw const BitteWalletException.rejected();
    final accountId = callback.accountId;
    final publicKey = callback.publicKey;
    if (accountId == null || publicKey == null) {
      throw const BitteWalletException.invalidResponse();
    }
    try {
      return WalletAccount(
        accountId: AccountId(accountId),
        publicKey: PublicKey(publicKey),
      );
    } catch (_) {
      throw const BitteWalletException.invalidResponse();
    }
  }

  /// Parses Bitte `transactionHashes` from a sign callback.
  List<String> completeSignTransactions(Uri callbackUri) {
    final callback = BitteWalletCallback.fromUri(callbackUri);
    if (callback.isError) throw const BitteWalletException.rejected();
    final hashes = callback.transactionHashes;
    if (hashes == null || hashes.isEmpty) {
      throw const BitteWalletException.invalidResponse();
    }
    return hashes;
  }
}

/// Parsed Bitte redirect query.
class BitteWalletCallback {
  const BitteWalletCallback({
    this.accountId,
    this.publicKey,
    this.transactionHashes,
    this.errorCode,
    this.errorMessage,
  });

  factory BitteWalletCallback.fromUri(Uri uri) {
    final params = {
      ...uri.queryParameters,
      if (uri.fragment.isNotEmpty) ...Uri.splitQueryString(uri.fragment),
    };
    final hashes = params['transactionHashes'];
    return BitteWalletCallback(
      accountId: params['account_id'],
      publicKey: params['public_key'],
      transactionHashes: hashes == null || hashes.isEmpty
          ? null
          : hashes.split(',').where((hash) => hash.isNotEmpty).toList(),
      errorCode: params['errorCode'] ?? params['error'],
      errorMessage: params['errorMessage'] ?? params['error_message'],
    );
  }

  final String? accountId;
  final String? publicKey;
  final List<String>? transactionHashes;
  final String? errorCode;
  final String? errorMessage;

  bool get isError =>
      (errorCode != null && errorCode!.isNotEmpty) ||
      (errorMessage != null && errorMessage!.isNotEmpty);
}

/// Failures from Bitte Wallet redirects.
class BitteWalletException extends NearSdkException {
  const BitteWalletException._({
    required super.code,
    required super.message,
    super.retryable,
  });

  const BitteWalletException.invalidInput()
    : this._(
        code: NearErrorCode.invalidInput,
        message: 'Bitte Wallet request is invalid.',
      );

  const BitteWalletException.deepLink()
    : this._(
        code: NearErrorCode.deepLinkUnavailable,
        message: 'Bitte Wallet could not be opened.',
      );

  const BitteWalletException.rejected()
    : this._(
        code: NearErrorCode.userRejected,
        message: 'Bitte Wallet rejected the request.',
      );

  const BitteWalletException.invalidResponse()
    : this._(
        code: NearErrorCode.walletResponseInvalid,
        message: 'Bitte Wallet returned an invalid callback.',
      );
}
