import 'dart:convert';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:near_dart/near_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NearSdkDemo());
}

// Callback URL scheme for wallet authentication
const String kCallbackScheme = 'nearsdk';

/// Formats an RPC error for display, including the node's `data` detail
/// (e.g. "State of contract X is too large to be viewed") which is far
/// more useful than the generic "Server error" message alone.
String describeRpcError(RpcError e) {
  final data = e.data;
  if (data != null && '$data'.isNotEmpty && '$data' != 'null') {
    return '${e.message}: $data';
  }
  return e.message;
}

// NEAR Official Colors
class NearTheme {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF00EC97);
  static const grey = Color(0xFF9CA3AF);
  static const greyLight = Color(0xFFF3F4F6);
  static const greyDark = Color(0xFF1F2937);
}

// App State
enum Network { mainnet, testnet }

class AppState extends ChangeNotifier {
  Network _network = Network.testnet;
  NearRpcClient? _client;

  // Wallet connection state
  String? _connectedAccountId;
  String? _publicKey;
  String? _lastCallbackUrl;
  String? _lastCallbackType;

  Network get network => _network;
  String get networkName => _network == Network.mainnet ? 'Mainnet' : 'Testnet';
  String? get connectedAccountId => _connectedAccountId;
  String? get publicKey => _publicKey;
  String? get lastCallbackUrl => _lastCallbackUrl;
  String? get lastCallbackType => _lastCallbackType;
  bool get isConnected => _connectedAccountId != null;

  NearRpcClient get client {
    _client ??= _network == Network.mainnet
        ? NearRpcClient.mainnet()
        : NearRpcClient.testnet();
    return _client!;
  }

  void switchNetwork(Network network) {
    if (_network != network) {
      _network = network;
      _client?.close();
      _client = null;
      // Clear connection when switching networks
      _connectedAccountId = null;
      _publicKey = null;
      notifyListeners();
    }
  }

  void handleWalletCallback(Uri uri) {
    _lastCallbackUrl = uri.toString();

    // Parse the callback
    final path = uri.path;
    final params = uri.queryParameters;

    if (path.contains('success')) {
      _lastCallbackType = 'success';
      // MyNearWallet returns account_id and public_key in success callback
      if (params.containsKey('account_id')) {
        _connectedAccountId = params['account_id'];
      }
      if (params.containsKey('public_key')) {
        _publicKey = params['public_key'];
      }
      // Sometimes the account_id is in all_keys format
      if (params.containsKey('all_keys')) {
        _publicKey = params['all_keys'];
      }
    } else if (path.contains('failure')) {
      _lastCallbackType = 'failure';
    } else if (path.contains('tx')) {
      _lastCallbackType = 'transaction';
      // Transaction callback may contain transactionHashes
    }

    notifyListeners();
  }

  void disconnect() {
    _connectedAccountId = null;
    _publicKey = null;
    _lastCallbackUrl = null;
    _lastCallbackType = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }
}

// Main App
class NearSdkDemo extends StatefulWidget {
  const NearSdkDemo({super.key});

  @override
  State<NearSdkDemo> createState() => _NearSdkDemoState();
}

class _NearSdkDemoState extends State<NearSdkDemo> {
  final _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'NEAR SDK Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: NearTheme.white,
            primaryColor: NearTheme.green,
            colorScheme: const ColorScheme.light(
              primary: NearTheme.green,
              onPrimary: NearTheme.black,
              surface: NearTheme.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: NearTheme.white,
              foregroundColor: NearTheme.black,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: NearTheme.greyLight),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: NearTheme.greyLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          // Constrain content to a phone-width column, centered, so the app
          // looks right on wide desktop/web screens instead of stretching
          // edge-to-edge.
          builder: (context, child) {
            return ColoredBox(
              color: const Color(0xFFE5E7EB),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          home: HomePage(appState: _appState),
        );
      },
    );
  }
}

// Home Page
class HomePage extends StatelessWidget {
  final AppState appState;

  const HomePage({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset('assets/near_logo.svg', height: 28),
            const SizedBox(width: 12),
            const Text(
              'SDK Demo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          _NetworkSwitch(appState: appState),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Text(
              'Test all SDK features',
              style: TextStyle(color: NearTheme.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Local Signing - Featured (works fully on web!)
            _FeatureCard(
              icon: Icons.bolt,
              title: 'Sign & Send (local key)',
              subtitle: 'Generate a key, fund via faucet, send a real transfer',
              onTap: () => _push(context, LocalSigningPage(appState: appState)),
              featured: true,
            ),
            const SizedBox(height: 8),

            // Wallet Connection - Featured
            _FeatureCard(
              icon: Icons.account_balance_wallet,
              title: 'Wallet Connect',
              subtitle: 'Connect to MyNearWallet & sign transactions',
              onTap: () =>
                  _push(context, WalletConnectPage(appState: appState)),
              featured: true,
            ),
            const SizedBox(height: 8),

            // Feature Cards
            _FeatureCard(
              icon: Icons.wifi,
              title: 'Network Status',
              subtitle: 'status() - Node info, sync status, protocol version',
              onTap: () =>
                  _push(context, NetworkStatusPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.account_circle_outlined,
              title: 'Account Explorer',
              subtitle: 'viewAccount() - Balance, storage, code hash',
              onTap: () =>
                  _push(context, AccountExplorerPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.key_outlined,
              title: 'Access Keys',
              subtitle:
                  'viewAccessKeyList() - Full access & function call keys',
              onTap: () => _push(context, AccessKeysPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.code,
              title: 'Contract Calls',
              subtitle:
                  'callFunction() - ft_metadata, ft_balance_of, ft_total_supply',
              onTap: () =>
                  _push(context, ContractCallsPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.how_to_vote_outlined,
              title: 'Validators',
              subtitle: 'validators() - Current epoch, stake distribution',
              onTap: () => _push(context, ValidatorsPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.view_in_ar_outlined,
              title: 'Block Explorer',
              subtitle: 'block() - Latest block, header, chunks',
              onTap: () =>
                  _push(context, BlockExplorerPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.local_gas_station_outlined,
              title: 'Gas Price',
              subtitle: 'gasPrice() - Current gas price in yoctoNEAR',
              onTap: () => _push(context, GasPricePage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.data_object,
              title: 'Contract Code & State',
              subtitle: 'viewCode(), viewState() - WASM code, storage',
              onTap: () => _push(context, CodeStatePage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.send_outlined,
              title: 'Transaction Builder',
              subtitle: 'Build & serialize transactions, actions',
              onTap: () =>
                  _push(context, TransactionBuilderPage(appState: appState)),
            ),
            _FeatureCard(
              icon: Icons.link,
              title: 'Wallet URLs',
              subtitle: 'MyNearWallet URL building & parsing',
              onTap: () => _push(context, WalletUrlPage(appState: appState)),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// Network Switch
class _NetworkSwitch extends StatelessWidget {
  final AppState appState;

  const _NetworkSwitch({required this.appState});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appState.switchNetwork(
          appState.network == Network.mainnet
              ? Network.testnet
              : Network.mainnet,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: appState.network == Network.mainnet
              ? NearTheme.green.withValues(alpha: 0.1)
              : NearTheme.greyLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appState.network == Network.mainnet
                    ? NearTheme.green
                    : NearTheme.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              appState.networkName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: appState.network == Network.mainnet
                    ? NearTheme.green
                    : NearTheme.greyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Feature Card
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool featured;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: featured ? NearTheme.green : NearTheme.greyLight,
            width: featured ? 2 : 1,
          ),
          color: featured
              ? NearTheme.green.withValues(alpha: 0.05)
              : NearTheme.white,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: featured
                        ? NearTheme.green.withValues(alpha: 0.15)
                        : NearTheme.greyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: featured ? NearTheme.green : NearTheme.black,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: featured ? NearTheme.green : NearTheme.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: NearTheme.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: featured ? NearTheme.green : NearTheme.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Base Page Template - Rebuilds when network changes
class _BasePage extends StatelessWidget {
  final String title;
  final AppState appState;
  final Widget child;

  const _BasePage({
    required this.title,
    required this.appState,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(title),
                const SizedBox(width: 8),
                // Network badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: appState.network == Network.mainnet
                        ? NearTheme.green.withValues(alpha: 0.2)
                        : NearTheme.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    appState.networkName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: appState.network == Network.mainnet
                          ? NearTheme.green
                          : NearTheme.grey,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              _NetworkSwitch(appState: appState),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(child: child),
        );
      },
    );
  }
}

// Result Display Widget
class _ResultCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const _ResultCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: const JsonEncoder.withIndent('  ').convert(data),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        e.key,
                        style: TextStyle(color: NearTheme.grey, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Loading Button
class _LoadButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NearTheme.black,
          foregroundColor: NearTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NearTheme.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// Error Display
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 0. LOCAL SIGNING PAGE — generate key, fund via faucet, sign & send.
//    This is the flagship demo: the whole flow runs locally (incl. on web),
//    no external wallet redirect needed.
// ============================================================================
class LocalSigningPage extends StatefulWidget {
  final AppState appState;

  const LocalSigningPage({super.key, required this.appState});

  @override
  State<LocalSigningPage> createState() => _LocalSigningPageState();
}

class _LocalSigningPageState extends State<LocalSigningPage> {
  final _accountCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _receiverCtrl = TextEditingController(text: 'testnet');
  final _amountCtrl = TextEditingController(text: '0.001');

  KeyPairEd25519? _keyPair;
  bool _busy = false;
  String? _status;
  String? _error;
  Map<String, dynamic>? _result;
  String? _txHash;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _secretCtrl.dispose();
    _receiverCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isTestnet => widget.appState.network == Network.testnet;

  void _set({bool? busy, String? status, String? error}) {
    setState(() {
      if (busy != null) _busy = busy;
      _status = status;
      _error = error;
    });
  }

  Future<void> _generateKey() async {
    _set(busy: true, status: 'Generating ed25519 key pair…');
    try {
      final kp = await KeyPairEd25519.generate();
      setState(() {
        _keyPair = kp;
        _secretCtrl.text = kp.toString();
      });
      _set(busy: false, status: 'Key generated. Now create a funded account.');
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  Future<void> _createFaucetAccount() async {
    final kp = _keyPair;
    if (kp == null) {
      _set(error: 'Generate a key first.');
      return;
    }
    _set(busy: true, status: 'Requesting a funded testnet account…');
    try {
      final accountId =
          'near-dart-demo-${DateTime.now().millisecondsSinceEpoch}.testnet';
      final response = await http.post(
        Uri.parse('https://helper.testnet.near.org/account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'newAccountId': accountId,
          'newAccountPublicKey': kp.publicKey.value,
        }),
      );
      if (response.statusCode != 200) {
        _set(busy: false, error: 'Faucet failed (HTTP ${response.statusCode})');
        return;
      }
      _accountCtrl.text = accountId;

      // The faucet account is only optimistically executed; wait until its
      // access key is final-queryable so the next Sign & Send won't race.
      _set(busy: true, status: 'Account created — waiting for it to be ready…');
      var ready = false;
      for (var i = 0; i < 15; i++) {
        final check = await widget.appState.client.viewAccessKey(
          accountId: AccountId(accountId),
          publicKey: kp.publicKey,
          blockReference: BlockReference.finality(Finality.final_),
        );
        if (check.isSuccess) {
          ready = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
      _set(
        busy: false,
        status: ready
            ? 'Funded $accountId is ready. Sign & send now.'
            : 'Account created but not visible yet — try Sign & Send shortly.',
      );
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  Future<void> _signAndSend() async {
    final accountId = _accountCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    final receiver = _receiverCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    if (accountId.isEmpty || secret.isEmpty || receiver.isEmpty) {
      _set(error: 'Account, secret key and receiver are required.');
      return;
    }
    setState(() {
      _result = null;
      _txHash = null;
    });
    _set(busy: true, status: 'Signing locally and broadcasting via send_tx…');
    try {
      final keyPair = await KeyPairEd25519.fromString(secret);
      final account = Account(
        accountId: AccountId(accountId),
        keyPair: keyPair,
        client: widget.appState.client,
      );
      final result = await account.transfer(
        receiverId: AccountId(receiver),
        amount: NearToken.parse(amount),
      );

      switch (result) {
        case RpcSuccess(:final value):
          setState(() {
            _txHash = value.transaction.hash;
            _result = {
              'status': _statusLabel(value.status),
              'tx_hash': value.transaction.hash,
              'signer': value.transaction.signerId,
              'gas_burnt': value.transactionOutcome.outcome.gasBurnt,
            };
          });
          _set(busy: false, status: 'Executed on-chain ✓');
        case RpcFailure(:final error):
          _set(
            busy: false,
            error: 'send_tx failed: ${describeRpcError(error)}',
          );
      }
    } catch (e) {
      _set(busy: false, error: '$e');
    }
  }

  // Don't use runtimeType.toString() — it returns minified garbage like
  // "minified:anL" in release/web builds. Match the sealed type instead.
  String _statusLabel(TransactionStatus s) => switch (s) {
    TransactionStatusSuccess() => 'Success',
    TransactionStatusSuccessReceipt() => 'Success (receipt pending)',
    TransactionStatusFailure() => 'Failure',
    TransactionStatusUnknown() => 'Unknown',
  };

  Future<void> _openExplorer() async {
    final hash = _txHash;
    if (hash == null) return;
    final base = _isTestnet
        ? 'https://testnet.nearblocks.io'
        : 'https://nearblocks.io';
    await launchUrl(
      Uri.parse('$base/txns/$hash'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Sign & Send',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'The full flow runs locally — key generation, Borsh '
            'serialization, ed25519 signing and broadcasting. No wallet '
            'redirect. Works on web, mobile and desktop.',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          _stepLabel('1', 'Generate a key pair'),
          const SizedBox(height: 8),
          _LoadButton(
            label: 'Generate ed25519 key',
            isLoading: _busy,
            onPressed: _generateKey,
          ),
          if (_keyPair != null) ...[
            const SizedBox(height: 8),
            _ResultCard(
              title: 'Key pair',
              data: {
                'public_key': _keyPair!.publicKey.value,
                'secret_key': '${_keyPair!.toString().substring(0, 20)}…',
              },
            ),
          ],
          const SizedBox(height: 20),

          _stepLabel('2', 'Get a funded account'),
          const SizedBox(height: 8),
          if (_isTestnet)
            _LoadButton(
              label: 'Create funded testnet account (faucet)',
              isLoading: _busy,
              onPressed: _createFaucetAccount,
            )
          else
            Text(
              'Faucet is testnet-only. On mainnet, import an existing '
              'account + secret key below.',
              style: TextStyle(color: NearTheme.grey, fontSize: 12),
            ),
          const SizedBox(height: 12),
          _field(_accountCtrl, 'Account ID', 'alice.testnet'),
          const SizedBox(height: 8),
          _field(_secretCtrl, 'Secret key', 'ed25519:…', mono: true),
          const SizedBox(height: 20),

          _stepLabel('3', 'Sign & send a transfer'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _field(_receiverCtrl, 'Receiver', 'bob.testnet'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(_amountCtrl, 'NEAR', '0.001', number: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LoadButton(
            label: 'Sign & Send',
            isLoading: _busy,
            onPressed: _signAndSend,
          ),

          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(
              _status!,
              style: TextStyle(
                color: NearTheme.greyDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: _error!),
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            _ResultCard(title: 'Transaction result', data: _result!),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openExplorer,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('View on explorer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepLabel(String n, String text) => Row(
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: NearTheme.green,
        child: Text(
          n,
          style: const TextStyle(
            color: NearTheme.black,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ],
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool mono = false,
    bool number = false,
  }) => TextField(
    controller: ctrl,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    style: TextStyle(fontSize: 13, fontFamily: mono ? 'monospace' : null),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
  );
}

// ============================================================================
// 1. NETWORK STATUS PAGE
// ============================================================================
class NetworkStatusPage extends StatefulWidget {
  final AppState appState;
  const NetworkStatusPage({super.key, required this.appState});

  @override
  State<NetworkStatusPage> createState() => _NetworkStatusPageState();
}

class _NetworkStatusPageState extends State<NetworkStatusPage> {
  bool _loading = false;
  String? _error;
  StatusResponse? _status;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      // Clear data when network changes
      if (mounted) {
        setState(() {
          _status = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.status();

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _status = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Network Status',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: status()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _LoadButton(
            label: 'Fetch Status',
            isLoading: _loading,
            onPressed: _fetch,
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_status != null) ...[
            _ResultCard(
              title: 'Node Info',
              data: {
                'chain_id': _status!.chainId,
                'protocol_version': _status!.protocolVersion,
                'node_version': _status!.version.version,
                'build': _status!.version.build ?? 'N/A',
              },
            ),
            const SizedBox(height: 12),
            _ResultCard(
              title: 'Sync Info',
              data: {
                'latest_block_height': _status!.syncInfo.latestBlockHeight,
                'latest_block_hash': _status!.syncInfo.latestBlockHash,
                'syncing': _status!.syncInfo.syncing,
                'earliest_block_height': _status!.syncInfo.earliestBlockHeight,
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 2. ACCOUNT EXPLORER PAGE
// ============================================================================
class AccountExplorerPage extends StatefulWidget {
  final AppState appState;
  const AccountExplorerPage({super.key, required this.appState});

  @override
  State<AccountExplorerPage> createState() => _AccountExplorerPageState();
}

class _AccountExplorerPageState extends State<AccountExplorerPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  AccountView? _account;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    _controller.text = widget.appState.network == Network.mainnet
        ? 'near'
        : 'testnet';
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    _controller.dispose();
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _account = null;
          _error = null;
          _controller.text = widget.appState.network == Network.mainnet
              ? 'near'
              : 'testnet';
        });
      }
    }
  }

  Future<void> _fetch() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.viewAccount(
      accountId: AccountId(_controller.text),
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _account = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Account Explorer',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: viewAccount()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Account ID'),
            onSubmitted: (_) => _fetch(),
          ),
          const SizedBox(height: 12),
          _LoadButton(
            label: 'Fetch Account',
            isLoading: _loading,
            onPressed: _fetch,
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_account != null)
            _ResultCard(
              title: 'Account: ${_controller.text}',
              data: {
                'balance':
                    '${_account!.amount.toNear().toStringAsFixed(4)} NEAR',
                'balance_yocto': _account!.amount.yoctoNear.toString(),
                'locked':
                    '${_account!.locked.toNear().toStringAsFixed(4)} NEAR',
                'storage_usage': '${_account!.storageUsage} bytes',
                'has_contract': _account!.hasContract,
                'code_hash': _account!.codeHash.value,
                'block_height': _account!.blockHeight,
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ACCESS KEYS PAGE
// ============================================================================
class AccessKeysPage extends StatefulWidget {
  final AppState appState;
  const AccessKeysPage({super.key, required this.appState});

  @override
  State<AccessKeysPage> createState() => _AccessKeysPageState();
}

class _AccessKeysPageState extends State<AccessKeysPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<AccessKeyInfoView>? _keys;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    _controller.text = widget.appState.network == Network.mainnet
        ? 'near'
        : 'testnet';
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    _controller.dispose();
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _keys = null;
          _error = null;
          _controller.text = widget.appState.network == Network.mainnet
              ? 'near'
              : 'testnet';
        });
      }
    }
  }

  Future<void> _fetch() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.viewAccessKeyList(
      accountId: AccountId(_controller.text),
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _keys = result.getOrThrow().keys;
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Access Keys',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: viewAccessKeyList()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Account ID'),
            onSubmitted: (_) => _fetch(),
          ),
          const SizedBox(height: 12),
          _LoadButton(
            label: 'Fetch Keys',
            isLoading: _loading,
            onPressed: _fetch,
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_keys != null) ...[
            Text(
              'Found ${_keys!.length} key(s)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._keys!.map((key) {
              final isFullAccess =
                  key.accessKey.permission is FullAccessPermissionView;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFullAccess ? Icons.key : Icons.vpn_key_outlined,
                            size: 16,
                            color: isFullAccess
                                ? Colors.orange
                                : NearTheme.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFullAccess ? 'Full Access' : 'Function Call',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isFullAccess
                                  ? Colors.orange
                                  : NearTheme.green,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Nonce: ${key.accessKey.nonce}',
                            style: TextStyle(
                              color: NearTheme.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        key.publicKey,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 4. CONTRACT CALLS PAGE
// ============================================================================
class ContractCallsPage extends StatefulWidget {
  final AppState appState;
  const ContractCallsPage({super.key, required this.appState});

  @override
  State<ContractCallsPage> createState() => _ContractCallsPageState();
}

class _ContractCallsPageState extends State<ContractCallsPage> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _metadata;
  String? _totalSupply;
  String? _balance;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _metadata = null;
          _totalSupply = null;
          _balance = null;
          _error = null;
        });
      }
    }
  }

  String get _wrapContract =>
      widget.appState.network == Network.mainnet ? 'wrap.near' : 'wrap.testnet';

  Future<void> _fetchMetadata() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.callFunction(
      accountId: AccountId(_wrapContract),
      methodName: 'ft_metadata',
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _metadata = result.getOrThrow().resultAsJson() as Map<String, dynamic>;
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  Future<void> _fetchTotalSupply() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.callFunction(
      accountId: AccountId(_wrapContract),
      methodName: 'ft_total_supply',
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _totalSupply = result.getOrThrow().resultAsJson() as String;
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final checkAccount = widget.appState.network == Network.mainnet
        ? 'near'
        : 'testnet';

    final result = await widget.appState.client.callFunction(
      accountId: AccountId(_wrapContract),
      methodName: 'ft_balance_of',
      args: {'account_id': checkAccount},
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _balance = result.getOrThrow().resultAsJson() as String;
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Contract Calls',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: callFunction() on $_wrapContract',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ft_metadata
          _LoadButton(
            label: 'Call ft_metadata()',
            isLoading: _loading,
            onPressed: _fetchMetadata,
          ),
          if (_metadata != null) ...[
            const SizedBox(height: 12),
            _ResultCard(title: 'ft_metadata', data: _metadata!),
          ],

          const SizedBox(height: 16),

          // ft_total_supply
          _LoadButton(
            label: 'Call ft_total_supply()',
            isLoading: _loading,
            onPressed: _fetchTotalSupply,
          ),
          if (_totalSupply != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              title: 'ft_total_supply',
              data: {'supply': _totalSupply},
            ),
          ],

          const SizedBox(height: 16),

          // ft_balance_of
          _LoadButton(
            label: 'Call ft_balance_of()',
            isLoading: _loading,
            onPressed: _fetchBalance,
          ),
          if (_balance != null) ...[
            const SizedBox(height: 12),
            _ResultCard(title: 'ft_balance_of', data: {'balance': _balance}),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: _error!),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 5. VALIDATORS PAGE
// ============================================================================
class ValidatorsPage extends StatefulWidget {
  final AppState appState;
  const ValidatorsPage({super.key, required this.appState});

  @override
  State<ValidatorsPage> createState() => _ValidatorsPageState();
}

class _ValidatorsPageState extends State<ValidatorsPage> {
  bool _loading = false;
  String? _error;
  ValidatorsResponse? _validators;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _validators = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.validators();

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _validators = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Validators',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: validators()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _LoadButton(
            label: 'Fetch Validators',
            isLoading: _loading,
            onPressed: _fetch,
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_validators != null) ...[
            _ResultCard(
              title: 'Epoch Info',
              data: {
                'epoch_height': _validators!.epochHeight,
                'epoch_start_height': _validators!.epochStartHeight,
                'current_validators': _validators!.currentValidators.length,
                'next_validators': _validators!.nextValidators.length,
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Top 10 Validators',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._validators!.currentValidators.take(10).map((v) {
              final stakeNear = v.stake.toNear();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.accountId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${(stakeNear / 1000000).toStringAsFixed(2)}M NEAR staked',
                              style: TextStyle(
                                color: NearTheme.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 6. BLOCK EXPLORER PAGE
// ============================================================================
class BlockExplorerPage extends StatefulWidget {
  final AppState appState;
  const BlockExplorerPage({super.key, required this.appState});

  @override
  State<BlockExplorerPage> createState() => _BlockExplorerPageState();
}

class _BlockExplorerPageState extends State<BlockExplorerPage> {
  bool _loading = false;
  String? _error;
  BlockResponse? _block;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _block = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.block(
      BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _block = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Block Explorer',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: block()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _LoadButton(
            label: 'Fetch Latest Block',
            isLoading: _loading,
            onPressed: _fetch,
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_block != null) ...[
            _ResultCard(
              title: 'Block Header',
              data: {
                'height': _block!.header.height,
                'hash': _block!.header.hash,
                'prev_hash': _block!.header.prevHash,
                'timestamp': DateTime.fromMillisecondsSinceEpoch(
                  _block!.header.timestamp ~/ 1000000,
                ).toIso8601String(),
                'author': _block!.author,
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Chunks (${_block!.chunks.length})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._block!.chunks.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shard ${c.shardId}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Hash: ${c.chunkHash.substring(0, 20)}...',
                        style: TextStyle(
                          color: NearTheme.grey,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 7. GAS PRICE PAGE
// ============================================================================
class GasPricePage extends StatefulWidget {
  final AppState appState;
  const GasPricePage({super.key, required this.appState});

  @override
  State<GasPricePage> createState() => _GasPricePageState();
}

class _GasPricePageState extends State<GasPricePage> {
  bool _loading = false;
  String? _error;
  GasPriceResponse? _gasPrice;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _gasPrice = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.gasPrice();

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _gasPrice = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Gas Price',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: gasPrice()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _LoadButton(
            label: 'Fetch Gas Price',
            isLoading: _loading,
            onPressed: _fetch,
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_gasPrice != null)
            _ResultCard(
              title: 'Current Gas Price',
              data: {
                'gas_price': '${_gasPrice!.gasPrice} yoctoNEAR/gas',
                'gas_price_readable':
                    '${(_gasPrice!.gasPrice.toDouble() / 1e12).toStringAsFixed(6)} TGas',
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. CODE & STATE PAGE
// ============================================================================
class CodeStatePage extends StatefulWidget {
  final AppState appState;
  const CodeStatePage({super.key, required this.appState});

  @override
  State<CodeStatePage> createState() => _CodeStatePageState();
}

class _CodeStatePageState extends State<CodeStatePage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  ContractCodeResponse? _code;
  ContractStateResponse? _state;
  Network? _lastNetwork;

  @override
  void initState() {
    super.initState();
    _lastNetwork = widget.appState.network;
    _controller.text = widget.appState.network == Network.mainnet
        ? 'wrap.near'
        : 'wrap.testnet';
    widget.appState.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onNetworkChange);
    _controller.dispose();
    super.dispose();
  }

  void _onNetworkChange() {
    if (widget.appState.network != _lastNetwork) {
      _lastNetwork = widget.appState.network;
      if (mounted) {
        setState(() {
          _code = null;
          _state = null;
          _error = null;
          _controller.text = widget.appState.network == Network.mainnet
              ? 'wrap.near'
              : 'wrap.testnet';
        });
      }
    }
  }

  Future<void> _fetchCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.viewCode(
      accountId: AccountId(_controller.text),
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _code = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  Future<void> _fetchState() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.appState.client.viewState(
      accountId: AccountId(_controller.text),
      prefixBase64: '',
      blockReference: BlockReference.finality(Finality.final_),
    );

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _state = result.getOrThrow();
      } else {
        _error = describeRpcError((result as RpcFailure).error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Code & State',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'RPC: viewCode(), viewState()',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Contract Account ID'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LoadButton(
                  label: 'Fetch Code',
                  isLoading: _loading,
                  onPressed: _fetchCode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LoadButton(
                  label: 'Fetch State',
                  isLoading: _loading,
                  onPressed: _fetchState,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorCard(message: _error!),
          if (_code != null)
            _ResultCard(
              title: 'Contract Code',
              data: {
                'hash': _code!.hash,
                'code_size': '${_code!.codeBase64.length} bytes (base64)',
              },
            ),
          if (_state != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              title: 'Contract State',
              data: {
                'entries': _state!.values.length,
                'block_height': _state!.blockHeight,
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 9. TRANSACTION BUILDER PAGE
// ============================================================================
class TransactionBuilderPage extends StatefulWidget {
  final AppState appState;
  const TransactionBuilderPage({super.key, required this.appState});

  @override
  State<TransactionBuilderPage> createState() => _TransactionBuilderPageState();
}

class _TransactionBuilderPageState extends State<TransactionBuilderPage> {
  final _signer = TextEditingController(text: 'alice.testnet');
  final _receiver = TextEditingController(text: 'bob.testnet');
  final _amount = TextEditingController(text: '1');
  String? _json;

  void _build() {
    final tx = Transaction(
      signerId: AccountId(_signer.text),
      receiverId: AccountId(_receiver.text),
      actions: [
        TransferAction(
          deposit: NearToken.fromNear(int.tryParse(_amount.text) ?? 1),
        ),
      ],
    );

    setState(() {
      _json = const JsonEncoder.withIndent('  ').convert(tx.toJson());
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Transaction Builder',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Build & serialize transactions',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signer,
            decoration: const InputDecoration(labelText: 'Signer ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiver,
            decoration: const InputDecoration(labelText: 'Receiver ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Amount (NEAR)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _LoadButton(
            label: 'Build Transaction',
            isLoading: false,
            onPressed: _build,
          ),
          if (_json != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction JSON',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _json!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _json!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// NEAR WALLET DATA
// ============================================================================
class NearWallet {
  final String id;
  final String name;
  final String icon;
  final String mainnetUrl;
  final String? testnetUrl;
  final bool supportsTestnet;

  const NearWallet({
    required this.id,
    required this.name,
    required this.icon,
    required this.mainnetUrl,
    this.testnetUrl,
    this.supportsTestnet = false,
  });

  String getUrl(bool isMainnet) {
    if (isMainnet) return mainnetUrl;
    return testnetUrl ?? mainnetUrl;
  }
}

const _nearWallets = [
  NearWallet(
    id: 'mynearwallet',
    name: 'MyNearWallet',
    icon: '🌐',
    mainnetUrl: 'https://app.mynearwallet.com',
    testnetUrl: 'https://testnet.mynearwallet.com',
    supportsTestnet: true,
  ),
  NearWallet(
    id: 'hot',
    name: 'HOT Wallet',
    icon: '🔥',
    mainnetUrl: 'https://wallet.hot.tg',
    supportsTestnet: false,
  ),
  NearWallet(
    id: 'meteor',
    name: 'Meteor Wallet',
    icon: '☄️',
    mainnetUrl: 'https://wallet.meteorwallet.app',
    supportsTestnet: false,
  ),
  NearWallet(
    id: 'here',
    name: 'HERE Wallet',
    icon: '📍',
    mainnetUrl: 'https://my.herewallet.app',
    supportsTestnet: false,
  ),
  NearWallet(
    id: 'sender',
    name: 'Sender Wallet',
    icon: '📤',
    mainnetUrl: 'https://sender.org',
    supportsTestnet: false,
  ),
  NearWallet(
    id: 'bitte',
    name: 'Bitte Wallet',
    icon: '💎',
    mainnetUrl: 'https://wallet.bitte.ai',
    supportsTestnet: false,
  ),
  NearWallet(
    id: 'mintbase',
    name: 'Mintbase Wallet',
    icon: '🎨',
    mainnetUrl: 'https://wallet.mintbase.xyz',
    testnetUrl: 'https://testnet.wallet.mintbase.xyz',
    supportsTestnet: true,
  ),
  NearWallet(
    id: 'nightly',
    name: 'Nightly Wallet',
    icon: '🌙',
    mainnetUrl: 'https://wallet.nightly.app',
    supportsTestnet: false,
  ),
  NearWallet(
    id: 'welldone',
    name: 'WELLDONE Wallet',
    icon: '✅',
    mainnetUrl: 'https://welldonestudio.io',
    supportsTestnet: false,
  ),
];

// ============================================================================
// 10. WALLET CONNECT PAGE
// ============================================================================
class WalletConnectPage extends StatefulWidget {
  final AppState appState;
  const WalletConnectPage({super.key, required this.appState});

  @override
  State<WalletConnectPage> createState() => _WalletConnectPageState();
}

class _WalletConnectPageState extends State<WalletConnectPage> {
  final _contractController = TextEditingController(text: 'wrap.testnet');
  final _receiverController = TextEditingController(text: 'testnet');
  final _amountController = TextEditingController(text: '0.1');
  NearWallet _selectedWallet = _nearWallets.first;
  bool _sending = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _updateContractHint();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    _contractController.dispose();
    _receiverController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {
        _updateContractHint();
      });
    }
  }

  void _updateContractHint() {
    _contractController.text = widget.appState.network == Network.mainnet
        ? 'wrap.near'
        : 'wrap.testnet';
    _receiverController.text = widget.appState.network == Network.mainnet
        ? 'near'
        : 'testnet';
  }

  String get _walletBaseUrl =>
      _selectedWallet.getUrl(widget.appState.network == Network.mainnet);

  /// Opens an in-app WebView to handle wallet login with callback interception
  Future<void> _connectWallet() async {
    setState(() => _connecting = true);

    try {
      final contract = _contractController.text.isNotEmpty
          ? _contractController.text
          : (widget.appState.network == Network.mainnet
                ? 'wrap.near'
                : 'wrap.testnet');

      // Build the login URL with our custom callback scheme
      final successUrl = '$kCallbackScheme://callback/success';
      final failureUrl = '$kCallbackScheme://callback/failure';

      final loginUrl = Uri.parse('$_walletBaseUrl/login').replace(
        queryParameters: {
          'contract_id': contract,
          'success_url': successUrl,
          'failure_url': failureUrl,
        },
      );

      debugPrint('[WALLET] Opening WebView: ${loginUrl.toString()}');

      // Navigate to the WebView page and wait for result
      final result = await Navigator.push<Map<String, String>?>(
        context,
        MaterialPageRoute(
          builder: (_) => _WalletWebViewPage(
            url: loginUrl.toString(),
            title: 'Connect ${_selectedWallet.name}',
            callbackScheme: kCallbackScheme,
          ),
        ),
      );

      debugPrint('[WALLET] WebView returned: $result');

      if (result != null && mounted) {
        // Successfully got callback data
        final accountId = result['account_id'];
        final publicKey = result['public_key'] ?? result['all_keys'];

        if (accountId != null) {
          widget.appState.handleWalletCallback(
            Uri.parse(
              '$kCallbackScheme://callback/success?account_id=$accountId${publicKey != null ? '&all_keys=$publicKey' : ''}',
            ),
          );

          if (mounted) {
            _showSnack('Connected: $accountId', NearTheme.green);
          }
        } else {
          if (mounted) {
            _showSnack('No account returned from wallet', Colors.orange);
          }
        }
      } else if (mounted) {
        debugPrint('[WALLET] User closed WebView without completing login');
      }
    } catch (e) {
      debugPrint('[WALLET] Error: $e');
      if (mounted) {
        _showSnack('Connection error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  void _showManualConnectDialog() {
    final accountController = TextEditingController();
    bool verifying = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: NearTheme.green, size: 24),
              const SizedBox(width: 12),
              const Text('Manual Connect'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your NEAR account ID:'),
              const SizedBox(height: 16),
              TextField(
                controller: accountController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.appState.network == Network.mainnet
                      ? 'your-account.near'
                      : 'your-account.testnet',
                ),
                onSubmitted: (_) async {
                  if (accountController.text.isNotEmpty) {
                    setDialogState(() => verifying = true);
                    await _verifyAndConnect(
                      ctx,
                      accountController.text,
                      setDialogState,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'We will verify this account exists',
                style: TextStyle(color: NearTheme.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                      if (accountController.text.isNotEmpty) {
                        setDialogState(() => verifying = true);
                        await _verifyAndConnect(
                          ctx,
                          accountController.text,
                          setDialogState,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: NearTheme.green,
                foregroundColor: NearTheme.black,
              ),
              child: verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NearTheme.black,
                      ),
                    )
                  : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyAndConnect(
    BuildContext dialogContext,
    String accountId,
    void Function(void Function()) setDialogState,
  ) async {
    try {
      final result = await widget.appState.client.viewAccount(
        accountId: AccountId(accountId),
        blockReference: BlockReference.finality(Finality.final_),
      );

      if (result.isSuccess) {
        widget.appState.handleWalletCallback(
          Uri.parse(
            '$kCallbackScheme://callback/success?account_id=$accountId',
          ),
        );

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected: $accountId'),
              backgroundColor: NearTheme.green,
            ),
          );
        }
      } else {
        setDialogState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account not found on ${widget.appState.networkName}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setDialogState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendTransaction() async {
    if (!widget.appState.isConnected) {
      _showSnack('Please connect a wallet first', Colors.orange);
      return;
    }

    final receiver = _receiverController.text.trim();
    if (receiver.isEmpty) {
      _showSnack('Please enter a receiver account ID', Colors.orange);
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnack('Please enter a valid amount', Colors.orange);
      return;
    }

    setState(() => _sending = true);

    try {
      final accountId = widget.appState.connectedAccountId!;
      var publicKeyStr = widget.appState.publicKey;
      final client = widget.appState.client;

      // --- Step 1: Resolve public key if we don't have one ---
      if (publicKeyStr == null ||
          publicKeyStr.isEmpty ||
          !publicKeyStr.contains(':')) {
        final keysResult = await client.viewAccessKeyList(
          accountId: AccountId(accountId),
          blockReference: BlockReference.finality(Finality.final_),
        );
        if (keysResult.isFailure) {
          _showSnack('Failed to fetch access keys for $accountId', Colors.red);
          return;
        }
        final keys = keysResult.getOrThrow().keys;
        if (keys.isEmpty) {
          _showSnack('No access keys found for $accountId', Colors.red);
          return;
        }
        // Pick first available key
        publicKeyStr = keys.first.publicKey;
      }

      // Handle comma-separated all_keys (take first)
      if (publicKeyStr.contains(',')) {
        publicKeyStr = publicKeyStr.split(',').first.trim();
      }

      // --- Step 2: Get nonce for this key ---
      final keyResult = await client.viewAccessKey(
        accountId: AccountId(accountId),
        publicKey: PublicKey(publicKeyStr),
        blockReference: BlockReference.finality(Finality.final_),
      );
      if (keyResult.isFailure) {
        _showSnack('Failed to get access key nonce', Colors.red);
        return;
      }
      final nonce = keyResult.getOrThrow().nonce + 1;

      // --- Step 3: Get latest block hash ---
      final statusResult = await client.status();
      if (statusResult.isFailure) {
        _showSnack('Failed to get network status', Colors.red);
        return;
      }
      final blockHashBase58 = statusResult
          .getOrThrow()
          .syncInfo
          .latestBlockHash;

      // --- Step 4: Build yoctoNEAR amount ---
      // amount * 10^24 = yoctoNEAR
      // Use BigInt arithmetic to avoid floating point issues
      final parts = amountText.split('.');
      final wholePart = BigInt.parse(parts[0].isEmpty ? '0' : parts[0]);
      BigInt fracPart = BigInt.zero;
      int fracDigits = 0;
      if (parts.length > 1) {
        final frac = parts[1].length > 24
            ? parts[1].substring(0, 24)
            : parts[1];
        fracPart = BigInt.parse(frac.isEmpty ? '0' : frac);
        fracDigits = frac.length;
      }
      final yoctoPerNear = BigInt.from(10).pow(24);
      final amountYocto =
          wholePart * yoctoPerNear +
          fracPart * BigInt.from(10).pow(24 - fracDigits);

      // --- Step 5: Borsh-serialize the transaction (using the SDK) ---
      final txBytes = serializeTransaction(
        Transaction(
          signerId: AccountId(accountId),
          receiverId: AccountId(receiver),
          publicKey: PublicKey(publicKeyStr),
          nonce: BigInt.from(nonce),
          blockHash: CryptoHash(blockHashBase58),
          actions: [
            TransferAction(
              deposit: NearToken.fromYocto(amountYocto.toString()),
            ),
          ],
        ),
      );

      // --- Step 6: Build /sign URL (base64 tx, comma-separated) ---
      final signUrl = Uri.parse('$_walletBaseUrl/sign')
          .replace(
            queryParameters: {
              'transactions': base64Encode(txBytes),
              'callbackUrl': '$kCallbackScheme://callback/tx',
            },
          )
          .toString();

      // --- Step 7: Open WebView ---
      if (!mounted) return;
      final result = await Navigator.push<Map<String, String>?>(
        context,
        MaterialPageRoute(
          builder: (_) => _WalletWebViewPage(
            url: signUrl,
            title: 'Confirm Transaction',
            callbackScheme: kCallbackScheme,
          ),
        ),
      );

      if (mounted) {
        if (result != null && result['transactionHashes'] != null) {
          final txHash = result['transactionHashes']!;
          _showSnack(
            'Sent! Hash: ${txHash.length > 16 ? '${txHash.substring(0, 16)}...' : txHash}',
            NearTheme.green,
          );
        } else if (result != null && result['errorCode'] == null) {
          _showSnack('Transaction submitted', NearTheme.green);
        } else if (result != null && result['errorCode'] != null) {
          _showSnack(
            'Transaction rejected: ${result['errorMessage'] ?? result['errorCode']}',
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isMainnet = widget.appState.network == Network.mainnet;
    final availableWallets = isMainnet
        ? _nearWallets
        : _nearWallets.where((w) => w.supportsTestnet).toList();

    // Reset to first available wallet if current doesn't support testnet
    if (!availableWallets.contains(_selectedWallet)) {
      _selectedWallet = availableWallets.first;
    }

    return _BasePage(
      title: 'Wallet Connect',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Wallet Selector
          Text(
            'SELECT WALLET',
            style: TextStyle(
              color: NearTheme.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Wallet Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availableWallets.length,
            itemBuilder: (context, index) {
              final wallet = availableWallets[index];
              final isSelected = wallet.id == _selectedWallet.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedWallet = wallet),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NearTheme.green.withValues(alpha: 0.1)
                        : NearTheme.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? NearTheme.green : NearTheme.greyLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(wallet.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wallet.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 13,
                            color: isSelected
                                ? NearTheme.green
                                : NearTheme.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: NearTheme.green,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          if (!isMainnet) ...[
            const SizedBox(height: 8),
            Text(
              'Only wallets supporting Testnet are shown',
              style: TextStyle(
                color: NearTheme.grey,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Connection Status (if connected)
          ListenableBuilder(
            listenable: widget.appState,
            builder: (context, _) {
              if (widget.appState.isConnected) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NearTheme.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NearTheme.green, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: NearTheme.green,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Connected',
                                      style: TextStyle(
                                        color: NearTheme.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      widget.appState.connectedAccountId ??
                                          'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                onPressed: () => widget.appState.disconnect(),
                                tooltip: 'Disconnect',
                              ),
                            ],
                          ),
                          if (widget.appState.publicKey != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NearTheme.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.key,
                                    size: 14,
                                    color: NearTheme.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.appState.publicKey!,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Selected Wallet Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NearTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NearTheme.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  _selectedWallet.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedWallet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isMainnet ? 'Mainnet' : 'Testnet',
                        style: TextStyle(color: NearTheme.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: NearTheme.green),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // MAIN CONNECT BUTTON - Opens WebView
          _GreenButton(
            label: _connecting
                ? 'Opening Wallet...'
                : (widget.appState.isConnected
                      ? 'Reconnect Wallet'
                      : 'Connect with ${_selectedWallet.name}'),
            icon: Icons.account_balance_wallet,
            isLoading: _connecting,
            onPressed: _connecting ? () {} : _connectWallet,
          ),

          const SizedBox(height: 12),

          // Manual connect option
          OutlinedButton.icon(
            onPressed: _showManualConnectDialog,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Enter Account ID manually'),
            style: OutlinedButton.styleFrom(
              foregroundColor: NearTheme.black,
              side: BorderSide(color: NearTheme.greyLight),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),

          const SizedBox(height: 24),

          // Optional contract ID (collapsed by default)
          ExpansionTile(
            title: Text(
              'Advanced Options',
              style: TextStyle(color: NearTheme.grey, fontSize: 13),
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              TextField(
                controller: _contractController,
                decoration: InputDecoration(
                  labelText: 'Contract ID (optional)',
                  hintText: isMainnet ? 'wrap.near' : 'wrap.testnet',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Send Section
          Text(
            'SEND NEAR',
            style: TextStyle(
              color: NearTheme.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiverController,
            decoration: const InputDecoration(labelText: 'Receiver Account ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (NEAR)',
              suffixText: 'NEAR',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          _LoadButton(
            label: _sending ? 'Preparing Transaction...' : 'Send Transaction',
            isLoading: _sending,
            onPressed: _sending ? () {} : _sendTransaction,
          ),

          const SizedBox(height: 32),

          // Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: NearTheme.grey),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: NearTheme.greyDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Select a wallet and tap "Connect Wallet"\n'
                    '2. Complete login in the wallet browser\n'
                    '3. Return to this app (auto or manually)\n'
                    '4. Or use "Enter Account ID manually"',
                    style: TextStyle(
                      color: NearTheme.grey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Green Button Widget
class _GreenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _GreenButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NearTheme.black,
                ),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: NearTheme.green,
          foregroundColor: NearTheme.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ============================================================================
// 11. WALLET URL PAGE
// ============================================================================
class WalletUrlPage extends StatefulWidget {
  final AppState appState;
  const WalletUrlPage({super.key, required this.appState});

  @override
  State<WalletUrlPage> createState() => _WalletUrlPageState();
}

class _WalletUrlPageState extends State<WalletUrlPage> {
  String? _signInUrl;
  String? _txUrl;

  MyNearWalletAdapter _createAdapter() {
    final network = widget.appState.network == Network.mainnet
        ? MyNearWalletNetwork.mainnet
        : MyNearWalletNetwork.testnet;

    return MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: AccountId('example.near'),
        successUrl: 'https://myapp.com/success',
        failureUrl: 'https://myapp.com/failure',
        network: network,
      ),
      launchUrl: (uri) async => true,
    );
  }

  void _buildSignInUrl() {
    final adapter = _createAdapter();

    // /login provisions a function-call key — its REAL public key goes in
    // the URL (example value; signIn() generates one for you).
    setState(() {
      _signInUrl = adapter
          .buildSignInUrl(
            contractId: AccountId('example.near'),
            publicKey: PublicKey(
              'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
            ),
            methodNames: ['ft_transfer', 'ft_transfer_call'],
          )
          .toString();
    });
  }

  Future<void> _launchSignInUrl() async {
    if (_signInUrl == null) return;
    final uri = Uri.parse(_signInUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _buildTxUrl() {
    final adapter = _createAdapter();

    // MyNearWallet signs the transaction, but it still needs a complete,
    // Borsh-serializable Transaction: publicKey, nonce and a recent
    // blockHash. (Example values — a real app fetches nonce via
    // viewAccessKey and blockHash via block().)
    final tx = Transaction(
      signerId: AccountId('alice.near'),
      receiverId: AccountId('bob.near'),
      publicKey: PublicKey(
        'ed25519:9C6hybhQ6Aycep9jaUnP6uL9ZYvDjUp1aSkFWPUFJtpj',
      ),
      nonce: BigInt.from(1),
      blockHash: const CryptoHash(
        '244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM',
      ),
      actions: [TransferAction(deposit: NearToken.fromNear(1))],
    );

    setState(() {
      _txUrl = adapter
          .buildTransactionUrl(
            transactions: [tx],
            callbackUrl: 'https://myapp.com/callback',
          )
          .toString();
    });
  }

  Future<void> _launchTxUrl() async {
    if (_txUrl == null) return;
    final uri = Uri.parse(_txUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BasePage(
      title: 'Wallet URLs',
      appState: widget.appState,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'MyNearWallet URL building',
            style: TextStyle(color: NearTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          _LoadButton(
            label: 'Build Sign-In URL',
            isLoading: false,
            onPressed: _buildSignInUrl,
          ),
          if (_signInUrl != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign-In URL',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _signInUrl!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _signInUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _launchSignInUrl,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Launch'),
                          style: TextButton.styleFrom(
                            foregroundColor: NearTheme.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          _LoadButton(
            label: 'Build Transaction URL',
            isLoading: false,
            onPressed: _buildTxUrl,
          ),
          if (_txUrl != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction URL',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txUrl!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _txUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _launchTxUrl,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Launch'),
                          style: TextButton.styleFrom(
                            foregroundColor: NearTheme.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// WALLET WEBVIEW PAGE - Embedded browser for wallet authentication
// ============================================================================
class _WalletWebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final String callbackScheme;

  const _WalletWebViewPage({
    required this.url,
    required this.title,
    required this.callbackScheme,
  });

  @override
  State<_WalletWebViewPage> createState() => _WalletWebViewPageState();
}

class _WalletWebViewPageState extends State<_WalletWebViewPage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _checkingAccount = false;
  bool _foundAccount = false;
  bool _popped = false;

  // JavaScript to extract account from MyNearWallet's localStorage
  // Key format: {prefix}_wallet_auth_key with value {accountId, allKeys}
  static const String _extractAccountScript = '''
    (function() {
      try {
        var keys = Object.keys(localStorage);

        // First: Look for any key ending with _wallet_auth_key
        for (var i = 0; i < keys.length; i++) {
          var key = keys[i];
          if (key.endsWith('_wallet_auth_key')) {
            try {
              var data = JSON.parse(localStorage.getItem(key));
              if (data && data.accountId) {
                return JSON.stringify({accountId: data.accountId, allKeys: data.allKeys || null, source: 'wallet_auth_key'});
              }
            } catch(e) {}
          }
        }

        // Second: Look for near-api-js standard keys
        for (var i = 0; i < keys.length; i++) {
          var key = keys[i];
          if (key.startsWith('near-api-js:keystore:')) {
            // Key format: near-api-js:keystore:{accountId}:{network}
            var parts = key.split(':');
            if (parts.length >= 3 && parts[2]) {
              return JSON.stringify({accountId: parts[2], source: 'keystore'});
            }
          }
        }

        // Third: Check URL for account_id parameter
        var url = window.location.href;
        var match = url.match(/account_id=([^&]+)/);
        if (match) {
          return JSON.stringify({accountId: decodeURIComponent(match[1]), source: 'url'});
        }

        // Fourth: Look for account in page DOM
        var selectors = [
          '[data-test-id="currentAccount"]',
          '[data-testid="currentAccount"]',
          '.account-id',
          '.user-account',
          '[class*="accountId"]',
          '[class*="AccountId"]',
          '[class*="account-name"]',
          '.wallet-account-id'
        ];
        for (var j = 0; j < selectors.length; j++) {
          var el = document.querySelector(selectors[j]);
          if (el && el.textContent) {
            var text = el.textContent.trim();
            if (text.includes('.near') || text.includes('.testnet') || /^[0-9a-f]{64}\$/.test(text)) {
              return JSON.stringify({accountId: text, source: 'dom'});
            }
          }
        }

        // Fifth: Search all text content for .near or .testnet pattern
        var bodyText = document.body ? document.body.innerText : '';
        var accountMatch = bodyText.match(/([a-z0-9_-]+\\.(?:near|testnet))/i);
        if (accountMatch) {
          return JSON.stringify({accountId: accountMatch[1], source: 'body'});
        }

        // Sixth: Search for implicit (hex) account IDs in body
        var hexMatch = bodyText.match(/\\b([0-9a-f]{64})\\b/);
        if (hexMatch) {
          return JSON.stringify({accountId: hexMatch[1], source: 'body_hex'});
        }

        return null;
      } catch(e) {
        return JSON.stringify({error: e.toString()});
      }
    })();
  ''';

  Future<void> _checkForAccount() async {
    if (_controller == null || _checkingAccount || _foundAccount) return;

    _checkingAccount = true;
    try {
      final result = await _controller!.evaluateJavascript(
        source: _extractAccountScript,
      );

      if (result != null && result != 'null' && result.toString().isNotEmpty) {
        try {
          final data = jsonDecode(result.toString());
          if (data['accountId'] != null &&
              data['accountId'].toString().isNotEmpty) {
            final accountId = data['accountId'].toString();
            // Validate it looks like a NEAR account (named or implicit hex)
            if (accountId.contains('.near') ||
                accountId.contains('.testnet') ||
                RegExp(r'^[0-9a-f]{64}$').hasMatch(accountId)) {
              _foundAccount = true;
              if (mounted) {
                // Show quick confirmation and return
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found account: $accountId'),
                    backgroundColor: NearTheme.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  Navigator.pop(context, {
                    'account_id': accountId,
                    'all_keys': data['allKeys']?.toString(),
                  });
                }
              }
              return;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    _checkingAccount = false;
  }

  // Periodically check for account after login
  void _startPeriodicCheck() {
    Future.doWhile(() async {
      if (!mounted || _foundAccount) return false;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _foundAccount) return false;
      await _checkForAccount();
      return mounted && !_foundAccount;
    });
  }

  /// Single-entry callback handler - defers pop to next event loop to avoid _debugLocked
  void _handleCallback(String urlString) {
    if (_popped) return;
    _popped = true;
    debugPrint('[WEBVIEW] CALLBACK INTERCEPTED: $urlString');
    final callbackUri = Uri.parse(urlString);
    final params = Map<String, String>.from(callbackUri.queryParameters);
    debugPrint('[WEBVIEW] Params: $params');
    // Schedule pop on next event loop iteration - completely outside the current frame
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.pop(context, params);
      }
    });
  }

  void _forceCheckNow() async {
    // Force immediate check
    _checkingAccount = false;
    await _checkForAccount();

    if (!_foundAccount && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not detected yet. Complete login first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: NearTheme.white,
        foregroundColor: NearTheme.black,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        actions: [
          // Button to force check for account
          TextButton.icon(
            onPressed: _forceCheckNow,
            icon: const Icon(Icons.refresh, color: NearTheme.green, size: 20),
            label: const Text(
              'Detect Account',
              style: TextStyle(
                color: NearTheme.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: NearTheme.greyLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    NearTheme.green,
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: NearTheme.green.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: NearTheme.green),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Login to your wallet - account will be detected automatically',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: InAppWebViewSettings(
                  useShouldOverrideUrlLoading: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  clearCache: false,
                  cacheEnabled: true,
                  resourceCustomSchemes: [widget.callbackScheme],
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStart: (controller, url) {
                  debugPrint('[WEBVIEW] onLoadStart: $url');
                  setState(() => _isLoading = true);
                },
                onLoadStop: (controller, url) async {
                  debugPrint('[WEBVIEW] onLoadStop: $url');
                  setState(() => _isLoading = false);

                  // Always try to check for account after page loads
                  await Future.delayed(const Duration(milliseconds: 800));
                  await _checkForAccount();

                  // Start periodic checking if not found yet
                  if (!_foundAccount) {
                    _startPeriodicCheck();
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100);
                },
                onUpdateVisitedHistory: (controller, url, isReload) {
                  final urlStr = url?.toString() ?? '';
                  if (urlStr.startsWith('${widget.callbackScheme}://')) {
                    _handleCallback(urlStr);
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri != null) {
                    final urlString = uri.toString();
                    debugPrint(
                      '[WEBVIEW] shouldOverrideUrlLoading: $urlString',
                    );

                    if (urlString.startsWith('${widget.callbackScheme}://')) {
                      _handleCallback(urlString);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) {
                  final url = request.url.toString();
                  debugPrint(
                    '[WEBVIEW] onReceivedError: $url - ${error.description}',
                  );
                  if (url.startsWith('${widget.callbackScheme}://')) {
                    _handleCallback(url);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
