// Minimal drop-in example: this is ALL the code a Flutter dev needs to add
// NEAR wallet connect + local contract calls to their app.
import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: HomeScreen(), debugShowCheckedModeBanner: false);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Create a controller for your contract + network.
  final wallet = NearWalletController(
    network: MyNearWalletNetwork.testnet,
    contractId: AccountId('guestbook.near-examples.testnet'),
    callbackScheme: 'nearsdk', // configure in AndroidManifest/Info.plist
  );
  String? _result;

  @override
  void initState() {
    super.initState();
    wallet.init(); // 2. Process any pending callback + restore session.
  }

  @override
  void dispose() {
    wallet.dispose();
    super.dispose();
  }

  // 3. After connect, sign a contract call LOCALLY — no redirect.
  Future<void> _addMessage() async {
    final signer = await wallet.signer();
    if (signer == null) return;
    final res = await signer.callFunction(
      contractId: AccountId('guestbook.near-examples.testnet'),
      methodName: 'add_message',
      args: {'text': 'hello from Flutter'},
      deposit: NearToken.zero(),
    );
    setState(() => _result = res.isSuccess ? 'Sent ✓' : 'Failed: $res');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NEAR wallet connect')),
      body: Center(
        child: ListenableBuilder(
          listenable: wallet,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4. Drop the button in. That's it.
              NearConnectButton(controller: wallet),
              const SizedBox(height: 24),
              if (wallet.isConnected)
                ElevatedButton(
                  onPressed: _addMessage,
                  child: const Text('Sign a contract call (local)'),
                ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_result!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
