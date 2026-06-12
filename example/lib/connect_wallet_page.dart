import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Action;
import 'package:near_dart/near_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wallet_keystore.dart';

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
  final _keyStore = SharedPrefsKeyStore();
  WalletAccount? _account;
  String? _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadConnected();
    // On web the redirect returns to this URL with the callback params.
    if (kIsWeb && _looksLikeCallback(Uri.base)) {
      _completeFromUri(Uri.base);
    }
  }

  MyNearWalletAdapter _adapter() {
    // On web, the callback returns to our own page URL; on mobile it returns
    // via the nearsdk:// deep link (configured in AndroidManifest/Info.plist).
    final callbackBase = kIsWeb
        ? Uri.base.replace(query: '').removeFragment().toString()
        : 'nearsdk://callback';
    return MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: AccountId(widget.contractId),
        successUrl: kIsWeb ? callbackBase : '$callbackBase/success',
        failureUrl: kIsWeb ? callbackBase : '$callbackBase/failure',
        network: widget.isTestnet
            ? MyNearWalletNetwork.testnet
            : MyNearWalletNetwork.mainnet,
      ),
      keyStore: _keyStore,
      launchUrl: (uri) => launchUrl(
        uri,
        // Full-page navigation on web; external browser on mobile.
        webOnlyWindowName: kIsWeb ? '_self' : null,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      ),
    );
  }

  static bool _looksLikeCallback(Uri uri) =>
      uri.queryParameters.containsKey('account_id') ||
      uri.queryParameters.containsKey('errorCode');

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
