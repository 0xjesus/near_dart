import 'package:flutter/material.dart';

import 'near_wallet_controller.dart';
import 'wallet_option.dart';

/// A drop-in NEAR wallet connect button with a built-in wallet picker.
///
/// Wire it to a [NearWalletController] (call `controller.init()` once at app
/// start). When disconnected it shows a connect button — tapping it opens a
/// picker with every wallet available on the current network (MyNearWallet,
/// Intear, HOT on mainnet, …). When connected it shows the account with a
/// disconnect action. Rebuilds automatically as the controller changes.
///
/// ```dart
/// NearConnectButton(controller: wallet)
/// ```
class NearConnectButton extends StatelessWidget {
  const NearConnectButton({
    super.key,
    required this.controller,
    this.connectLabel = 'Connect NEAR wallet',
    this.onConnected,
  });

  /// The wallet controller driving the connection.
  final NearWalletController controller;

  /// Label shown while disconnected.
  final String connectLabel;

  /// Optional callback invoked when an account becomes connected.
  final void Function(String accountId)? onConnected;

  Future<void> _pickAndConnect(BuildContext context) async {
    final wallets = controller.availableWallets;
    if (wallets.length == 1) {
      await controller.connect(wallet: wallets.single);
      return;
    }
    final choice = await showModalBottomSheet<NearWalletOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(
                'Choose a wallet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final wallet in wallets)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(wallet.label),
                subtitle: Text(wallet.description),
                onTap: () => Navigator.of(context).pop(wallet),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice != null) await controller.connect(wallet: choice);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final account = controller.account;
        if (account != null) {
          onConnected?.call(account.accountId.value);
          return _ConnectedChip(
            controller: controller,
            accountId: account.accountId.value,
          );
        }
        return FilledButton.icon(
          onPressed: controller.busy ? null : () => _pickAndConnect(context),
          icon: controller.busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.account_balance_wallet_outlined),
          label: Text(connectLabel),
        );
      },
    );
  }
}

class _ConnectedChip extends StatelessWidget {
  const _ConnectedChip({required this.controller, required this.accountId});

  final NearWalletController controller;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            accountId,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (controller.walletOption != null) ...[
          const SizedBox(width: 6),
          Text(
            controller.walletOption!.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        TextButton(
          onPressed: controller.disconnect,
          child: const Text('Disconnect'),
        ),
      ],
    );
  }
}
