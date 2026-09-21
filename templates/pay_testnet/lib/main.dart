import 'package:flutter/material.dart';
import 'package:near_dart/near_dart.dart';

void main() => runApp(const PayTestnetApp());

class PayTestnetApp extends StatelessWidget {
  const PayTestnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PayPage(),
    );
  }
}

/// Sends 0.001 NEAR on testnet with a local full-access key.
class PayPage extends StatefulWidget {
  const PayPage({super.key});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final _account = TextEditingController();
  final _secret = TextEditingController();
  final _receiver = TextEditingController(text: 'testnet');
  final _amount = TextEditingController(text: '0.001');
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _account.dispose();
    _secret.dispose();
    _receiver.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final client = NearRpcClient.testnet();
    try {
      final accountId = AccountId(_account.text.trim());
      final keyPair = await KeyPairEd25519.fromString(_secret.text.trim());
      final signer = Account(
        accountId: accountId,
        keyPair: keyPair,
        client: client,
      );
      final sent = await signer.transfer(
        receiverId: AccountId(_receiver.text.trim()),
        amount: NearToken.parse(_amount.text.trim()),
        waitUntil: TxExecutionStatus.final_,
      );
      switch (sent) {
        case RpcSuccess(:final value):
          final hash = value.transaction.hash;
          setState(() {
            _status = 'https://testnet.nearblocks.io/txns/$hash';
          });
        case RpcFailure(:final error):
          setState(() => _status = error.message);
      }
    } catch (error) {
      setState(() => _status = '$error');
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay testnet')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Use a throwaway testnet full-access key from '
            '`near account export-account`. Never paste a mainnet key.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _account,
            decoration: const InputDecoration(
              labelText: 'Your account',
              hintText: 'alice.testnet',
            ),
            autocorrect: false,
          ),
          TextField(
            controller: _secret,
            decoration: const InputDecoration(
              labelText: 'Secret key (ed25519:…)',
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
          TextField(
            controller: _receiver,
            decoration: const InputDecoration(labelText: 'Receiver'),
            autocorrect: false,
          ),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Amount (NEAR)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'Sending…' : 'Send on testnet'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            SelectableText(_status!),
          ],
        ],
      ),
    );
  }
}
