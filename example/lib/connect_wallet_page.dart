import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Action;
import 'package:near_dart/near_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wallet_keystore.dart';

/// Shared persistent key store, so the pending key set before the redirect
/// is the same one read on return (web) or at startup (mobile).
final SharedPrefsKeyStore appKeyStore = SharedPrefsKeyStore();

/// Builds a MyNearWallet adapter wired for the current platform: a full-page
/// redirect on web, an external browser launch on mobile, and a callback URL
/// that returns to our app (web) or via the `nearsdk://` deep link (mobile).
MyNearWalletAdapter buildWalletAdapter({
  required bool isTestnet,
  required String contractId,
}) {
  final callbackBase = kIsWeb
      ? Uri.base.replace(query: '').removeFragment().toString()
      : 'nearsdk://callback';
  return MyNearWalletAdapter(
    config: MyNearWalletConfig(
      contractId: AccountId(contractId),
      successUrl: kIsWeb ? callbackBase : '$callbackBase/success',
      failureUrl: kIsWeb ? callbackBase : '$callbackBase/failure',
      network: isTestnet
          ? MyNearWalletNetwork.testnet
          : MyNearWalletNetwork.mainnet,
    ),
    keyStore: appKeyStore,
    launchUrl: (uri) => launchUrl(
      uri,
      webOnlyWindowName: kIsWeb ? '_self' : null,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    ),
  );
}

/// Whether [uri] looks like a MyNearWallet sign-in callback.
bool looksLikeWalletCallback(Uri uri) =>
    uri.queryParameters.containsKey('account_id') ||
    uri.queryParameters.containsKey('errorCode');

/// Completes a wallet sign-in from a callback [uri] (promotes the pending
/// key into the shared store) and returns the connected account, or null.
///
/// Call this at app startup (web: `Uri.base`; mobile: the `app_links` deep
/// link) so the connection registers no matter which screen the redirect
/// lands on.
Future<WalletAccount?> handleWalletCallback(Uri uri) {
  if (!looksLikeWalletCallback(uri)) return Future.value();
  // completeSignIn only needs the key store; the config is irrelevant here.
  return buildWalletAdapter(
    isTestnet: true,
    contractId: 'placeholder.testnet',
  ).completeSignIn(uri);
}

/// Demonstrates the real MyNearWallet connect flow (no embedded WebView):
///
/// 1. `signIn` generates a function-call key and redirects to MNW `/login`.
/// 2. The wallet adds the key and redirects back with the account id.
/// 3. `completeSignIn` promotes the key into secure storage.
/// 4. Afterward, contract calls are signed **locally** with that key — no
///    further redirects.
///
/// Works on web (full-page redirect) and mobile (deep-link `nearsdk://`).
class ConnectWalletPage extends StatefulWidget {
  const ConnectWalletPage({
    super.key,
    required this.isTestnet,
    required this.contractId,
  });

  final bool isTestnet;

  /// The contract whose methods the provisioned key may call.
  final String contractId;

  @override
  State<ConnectWalletPage> createState() => _ConnectWalletPageState();
}

class _ConnectWalletPageState extends State<ConnectWalletPage> {
  WalletAccount? _account;
  String? _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadConnected();
  }

  MyNearWalletAdapter _adapter() => buildWalletAdapter(
    isTestnet: widget.isTestnet,
    contractId: widget.contractId,
  );

  Future<void> _loadConnected() async {
    final accounts = await _adapter().getAccounts();
    if (mounted) {
      setState(() => _account = accounts.isEmpty ? null : accounts.first);
    }
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Redirecting to MyNearWallet…';
    });
    try {
      // Generates a function-call key, persists it as pending, and redirects.
      // On web the page navigates away here and returns via initState.
      await _adapter().signIn(
        contractId: AccountId(widget.contractId),
        methodNames: const [],
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  // Kept for reference / manual completion; the app root now processes the
  // callback at startup (see handleWalletCallback), so this is unused in the
  // normal flow.
  // ignore: unused_element
  Future<void> _completeFromUri(Uri uri) async {
    setState(() => _busy = true);
    try {
      final account = await _adapter().completeSignIn(uri);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _account = account;
        _status = account != null
            ? 'Connected ${account.accountId.value} — key stored, '
                  'you can now sign locally.'
            : 'Sign-in was cancelled or failed.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _adapter().signOut();
    if (mounted) {
      setState(() {
        _account = null;
        _status = 'Disconnected.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MyNearWallet connect via redirect (no embedded WebView). On '
            'connect we provision a function-call key and store it, so '
            'afterward you sign locally with no more redirects.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (account == null)
            FilledButton.icon(
              onPressed: _busy ? null : _connect,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Connect with MyNearWallet'),
            )
          else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(account.accountId.value),
                subtitle: Text(
                  '${account.publicKey.value.substring(0, 24)}…',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                trailing: TextButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The function-call key is in secure storage. Use '
              'adapter.keyFor(account) + Account.callFunction to sign '
              'contract calls locally.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: const TextStyle(fontSize: 13)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
