import 'package:flutter/material.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  runApp(const NearFlutterExampleApp());
}

class NearFlutterExampleApp extends StatelessWidget {
  const NearFlutterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEAR Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00EC97), // NEAR green
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _client = NearRpcClient.mainnet();
  final _accountController = TextEditingController(text: 'near');

  NetworkInfo? _networkInfo;
  AccountInfo? _accountInfo;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  @override
  void dispose() {
    _client.close();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final statusResult = await _client.status();

    switch (statusResult) {
      case RpcSuccess(:final value):
        setState(() {
          _networkInfo = NetworkInfo(
            chainId: value.chainId,
            version: value.version.version,
            latestBlock: value.syncInfo.latestBlockHeight,
            syncing: value.syncInfo.syncing,
          );
          _isLoading = false;
        });
      case RpcFailure(:final error):
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
    }
  }

  Future<void> _loadAccountInfo() async {
    final accountId = _accountController.text.trim();
    if (accountId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _accountInfo = null;
    });

    final accountResult = await _client.viewAccount(
      accountId: AccountId(accountId),
      blockReference: BlockReference.finality(Finality.final_),
    );

    switch (accountResult) {
      case RpcSuccess(:final value):
        setState(() {
          _accountInfo = AccountInfo(
            accountId: accountId,
            balance: value.amount.toNear(),
            lockedBalance: value.locked.toNear(),
            storageUsage: value.storageUsage,
            hasContract: value.hasContract,
          );
          _isLoading = false;
        });
      case RpcFailure(:final error):
        setState(() {
          _error = 'Account not found: ${error.message}';
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEAR Flutter Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNetworkInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNetworkCard(),
              const SizedBox(height: 16),
              _buildAccountLookup(),
              if (_accountInfo != null) ...[
                const SizedBox(height: 16),
                _buildAccountCard(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading && _networkInfo == null)
              const Center(child: CircularProgressIndicator())
            else if (_networkInfo != null) ...[
              _InfoRow(label: 'Chain ID', value: _networkInfo!.chainId),
              _InfoRow(label: 'Node Version', value: _networkInfo!.version),
              _InfoRow(
                label: 'Latest Block',
                value: '#${_networkInfo!.latestBlock}',
              ),
              _InfoRow(
                label: 'Syncing',
                value: _networkInfo!.syncing ? 'Yes' : 'No',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountLookup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Lookup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'Account ID',
                hintText: 'e.g., alice.near',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loadAccountInfo(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _loadAccountInfo,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Look Up Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _accountInfo!.accountId,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Balance',
              value: '${_accountInfo!.balance.toStringAsFixed(4)} NEAR',
            ),
            _InfoRow(
              label: 'Locked (Staked)',
              value: '${_accountInfo!.lockedBalance.toStringAsFixed(4)} NEAR',
            ),
            _InfoRow(
              label: 'Storage Used',
              value: '${_accountInfo!.storageUsage} bytes',
            ),
            _InfoRow(
              label: 'Has Contract',
              value: _accountInfo!.hasContract ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkInfo {
  const NetworkInfo({
    required this.chainId,
    required this.version,
    required this.latestBlock,
    required this.syncing,
  });

  final String chainId;
  final String version;
  final int latestBlock;
  final bool syncing;
}

class AccountInfo {
  const AccountInfo({
    required this.accountId,
    required this.balance,
    required this.lockedBalance,
    required this.storageUsage,
    required this.hasContract,
  });

  final String accountId;
  final double balance;
  final double lockedBalance;
  final int storageUsage;
  final bool hasContract;
}
