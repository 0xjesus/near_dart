import 'dart:convert';

import '../../diagnostics/near_errors.dart';
import '../../encoding/base58.dart';
import '../../types/network.dart';
import '../../types/primitives.dart';
import '../wallet_adapter.dart' show WalletAccount;

/// Configuration for [HereWalletAdapter].
class HereWalletConfig {
  const HereWalletConfig({
    this.walletUrl = 'https://my.herewallet.app',
    required this.returnUrl,
    this.network = NearNetwork.mainnet,
    this.origin,
  });

  /// HERE universal-link origin.
  final String walletUrl;

  /// App callback URL (`?success=` / `?failure=`).
  ///
  /// HERE appends `?success=` / `?failure=` to this value. Do not include a
  /// query string; use a distinct path instead.
  final String returnUrl;

  /// Network encoded into HERE payloads.
  final NearNetwork network;

  /// Shown to HERE as the requesting app for connect/sign (`receiver`).
  final String? origin;

  /// Receiver used in `/sign` payloads.
  String get signReceiver {
    final configured = origin;
    if (configured != null && configured.isNotEmpty) return configured;
    return Uri.tryParse(returnUrl)?.host ?? 'app';
  }
}

/// HERE Wallet universal sign-link adapter.
///
/// Encodes wallet-selector-style JSON as base58 and opens
/// `https://my.herewallet.app/call/{payload}` or `/sign/{payload}`.
/// The wallet returns to [HereWalletConfig.returnUrl] with `success`
/// (comma-separated hashes or signature) or `failure`.
class HereWalletAdapter {
  HereWalletAdapter({required this.config, required this.launchUrl});

  final HereWalletConfig config;
  final Future<bool> Function(Uri uri) launchUrl;

  /// Transaction-signing universal link.
  Uri buildCallUrl({
    required List<Map<String, dynamic>> transactions,
    String? returnUrl,
  }) {
    if (transactions.isEmpty) {
      throw const HereWalletException.invalidInput();
    }
    return _link('call', {
      'transactions': transactions,
      'network': config.network.name,
    }, returnUrl ?? config.returnUrl);
  }

  /// Off-chain message-signing universal link.
  Uri buildSignUrl({
    required String message,
    required String receiver,
    String? returnUrl,
  }) {
    if (message.isEmpty || receiver.isEmpty) {
      throw const HereWalletException.invalidInput();
    }
    return _link('sign', {
      'receiver': receiver,
      'message': message,
      'network': config.network.name,
    }, returnUrl ?? config.returnUrl);
  }

  /// Opens HERE `/sign` so the wallet can attach `account_id` / `public_key`
  /// on [returnUrl]. Universal links do not provision a local function-call
  /// key; Instant Wallet login with an account is HOT Wallet (`h4n.app`).
  Future<void> signIn() async {
    final launched = await launchUrl(
      buildSignUrl(message: 'Connect', receiver: config.signReceiver),
    );
    if (!launched) throw const HereWalletException.deepLink();
  }

  /// Opens HERE to sign and send [transactions].
  Future<void> requestSignTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    final launched = await launchUrl(buildCallUrl(transactions: transactions));
    if (!launched) throw const HereWalletException.deepLink();
  }

  /// Opens HERE to sign [message] for [receiver].
  Future<void> requestSignMessage({
    required String message,
    required String receiver,
  }) async {
    final launched = await launchUrl(
      buildSignUrl(message: message, receiver: receiver),
    );
    if (!launched) throw const HereWalletException.deepLink();
  }

  /// Parses a HERE `returnUrl` callback.
  HereWalletCallback completeCallback(Uri callbackUri) {
    final callback = HereWalletCallback.fromUri(callbackUri);
    if (callback.isError) {
      throw HereWalletException.rejected(callback.failure);
    }
    if (callback.successValues.isEmpty) {
      throw const HereWalletException.invalidResponse();
    }
    return callback;
  }

  /// Parses a HERE connect callback into a visibility-only account.
  ///
  /// Requires `account_id` and `public_key` (query, fragment, or JSON inside
  /// `success`). Transaction hashes alone are not a session.
  WalletAccount completeConnect(Uri callbackUri) {
    final callback = HereWalletCallback.fromUri(callbackUri);
    if (callback.isError) {
      throw HereWalletException.rejected(callback.failure);
    }
    final accountId = callback.accountId;
    final publicKey = callback.publicKey;
    if (accountId == null || publicKey == null) {
      throw const HereWalletException.invalidResponse();
    }
    try {
      return WalletAccount(
        accountId: AccountId(accountId),
        publicKey: PublicKey(publicKey),
      );
    } catch (_) {
      throw const HereWalletException.invalidResponse();
    }
  }

  /// Transaction hashes from a `/call` callback.
  List<String> completeSignTransactions(Uri callbackUri) {
    final hashes = completeCallback(callbackUri).successValues;
    if (hashes.isEmpty) {
      throw const HereWalletException.invalidResponse();
    }
    return hashes;
  }

  Uri _link(String path, Map<String, dynamic> payload, String returnUrl) {
    final encoded = base58Encode(utf8.encode(jsonEncode(payload)));
    return Uri.parse(
      '${config.walletUrl}/$path/$encoded',
    ).replace(queryParameters: {'returnUrl': returnUrl});
  }
}

/// Parsed HERE redirect.
class HereWalletCallback {
  const HereWalletCallback({
    required this.successValues,
    this.failure,
    this.accountId,
    this.publicKey,
  });

  factory HereWalletCallback.fromUri(Uri uri) {
    final params = {
      ...uri.queryParameters,
      if (uri.fragment.isNotEmpty) ...Uri.splitQueryString(uri.fragment),
    };
    final failure = params['failure'];
    final success = params['success'];
    final successValues = success == null || success.isEmpty
        ? const <String>[]
        : success.split(',').where((value) => value.isNotEmpty).toList();
    final extracted = _accountFromSuccess(success);
    final accountId =
        params['account_id'] ?? params['accountId'] ?? extracted.$1;
    final publicKey =
        params['public_key'] ?? params['publicKey'] ?? extracted.$2;
    return HereWalletCallback(
      successValues: successValues,
      failure: failure == null || failure.isEmpty ? null : failure,
      accountId: accountId == null || accountId.isEmpty ? null : accountId,
      publicKey: publicKey == null || publicKey.isEmpty ? null : publicKey,
    );
  }

  /// Transaction hashes or signed-message payload fragments.
  final List<String> successValues;
  final String? failure;
  final String? accountId;
  final String? publicKey;

  bool get isError => failure != null;
}

(String?, String?) _accountFromSuccess(String? success) {
  if (success == null || success.isEmpty) return (null, null);
  Map<String, dynamic>? json;
  try {
    final decoded = jsonDecode(success);
    if (decoded is Map) {
      json = decoded.cast<String, dynamic>();
    }
  } catch (_) {
    try {
      final decoded = jsonDecode(utf8.decode(base58Decode(success)));
      if (decoded is Map) {
        json = decoded.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }
  }
  if (json != null) {
    final accountId = json['account_id'] ?? json['accountId'];
    final publicKey = json['public_key'] ?? json['publicKey'];
    return (
      accountId is String && accountId.isNotEmpty ? accountId : null,
      publicKey is String && publicKey.isNotEmpty ? publicKey : null,
    );
  }
  final values = success.split(',').where((value) => value.isNotEmpty).toList();
  if (values.length >= 2 && values[1].startsWith('ed25519:')) {
    return (values[0], values[1]);
  }
  return (null, null);
}

/// Failures from HERE Wallet universal links.
class HereWalletException extends NearSdkException {
  const HereWalletException._({
    required super.code,
    required super.message,
    super.retryable,
  });

  const HereWalletException.invalidInput()
    : this._(
        code: NearErrorCode.invalidInput,
        message: 'HERE Wallet request is invalid.',
      );

  const HereWalletException.deepLink()
    : this._(
        code: NearErrorCode.deepLinkUnavailable,
        message: 'HERE Wallet could not be opened.',
      );

  HereWalletException.rejected([String? reason])
    : this._(
        code: NearErrorCode.userRejected,
        message: reason == null || reason.isEmpty
            ? 'HERE Wallet rejected the request.'
            : 'HERE Wallet rejected the request: $reason',
      );

  const HereWalletException.invalidResponse()
    : this._(
        code: NearErrorCode.walletResponseInvalid,
        message: 'HERE Wallet returned an invalid callback.',
      );
}
