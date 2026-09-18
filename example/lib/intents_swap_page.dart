import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:near_dart/near_dart.dart';

import 'glass.dart';

/// Hits the live NEAR Intents 1Click API from the example app.
///
/// Intents settlement is mainnet-only. Dry quotes still go to production
/// 1Click; they return a route without creating a deposit address. A live
/// quote (`dry: false`) creates a deposit address the user must fund.
class IntentsSwapPage extends StatefulWidget {
  const IntentsSwapPage({
    super.key,
    this.connectedAccountId,
    this.isMainnet = false,
  });

  final String? connectedAccountId;
  final bool isMainnet;

  @override
  State<IntentsSwapPage> createState() => _IntentsSwapPageState();
}

class _IntentsSwapPageState extends State<IntentsSwapPage> {
  final _account = TextEditingController(text: 'near');
  late final OneClickClient _client;
  late final OneClickSwapController _swap;
  String _amount = '0.1';
  bool _busy = false;
  String? _error;
  OneClickSwapState? _state;

  @override
  void initState() {
    super.initState();
    _client = OneClickClient();
    _swap = OneClickSwapController(client: _client);
    _swap.states.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    final connected = widget.connectedAccountId;
    if (connected != null && connected.isNotEmpty) {
      _account.text = connected;
    }
  }

  @override
  void dispose() {
    _account.dispose();
    _client.close();
    _swap.dispose();
    super.dispose();
  }

  Future<void> _quote({required bool dry}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final catalog = OneClickAssetCatalog(client: _client);
      final wnear = await catalog.requireByAssetId('nep141:wrap.near');
      final usdcs = await catalog.search(symbol: 'USDC', blockchain: 'near');
      if (usdcs.isEmpty) {
        throw const FormatException('1Click catalog has no USDC on NEAR.');
      }
      final usdc = usdcs.first;
      final account = _account.text.trim();
      if (account.isEmpty) {
        throw const FormatException('Set a NEAR account for refund/recipient.');
      }
      final request = const OneClickQuoteBuilder().exactInput(
        originToken: wnear,
        destinationToken: usdc,
        amount: _amount,
        refundTo: account,
        recipient: account,
        dry: dry,
      );
      await _swap.quote(request);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _state?.quote?.quote;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('NEAR Intents', style: Near.display(18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Live 1Click quote: 0.1 wNEAR → USDC on mainnet. '
              'Dry hits production and does not create a deposit. '
              'Open swap creates a deposit address — fund it only with money '
              'you can lose.',
              style: TextStyle(color: Near.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: 'Refund / recipient account',
                hintText: 'alice.near',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final value in const ['0.05', '0.1', '0.25'])
                  ChoiceChip(
                    label: Text('$value wNEAR'),
                    selected: _amount == value,
                    onSelected: (_) => setState(() => _amount = value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _quote(dry: true),
              child: Text(_busy ? 'Quoting…' : 'Live dry quote'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _quote(dry: false),
              child: const Text('Open live swap (deposit address)'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
            if (_state != null) ...[
              Text('Stage: ${_state!.stage.name}', style: Near.display(16)),
              if (quote != null) ...[
                const SizedBox(height: 12),
                _kv('in', quote.amountInFormatted ?? quote.amountIn),
                _kv('out', quote.amountOutFormatted ?? quote.amountOut),
                _kv('out USD', quote.amountOutUsd),
                _kv('eta s', quote.timeEstimate?.toString()),
                _kv('deposit', quote.depositAddress),
                if (quote.depositAddress != null)
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: quote.depositAddress!),
                      );
                    },
                    child: const Text('Copy deposit address'),
                  ),
              ],
            ],
            if (!widget.isMainnet) ...[
              const SizedBox(height: 16),
              Text(
                'Quotes talk to mainnet 1Click even if the rest of the demo '
                'is on testnet. Settlement is mainnet-only.',
                style: TextStyle(color: Near.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(key, style: TextStyle(color: Near.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
