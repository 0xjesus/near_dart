import 'package:flutter/material.dart';

import 'near_wallet_controller.dart';

/// A drop-in NEAR wallet connect button.
///
/// Wire it to a [NearWalletController] (call `controller.init()` once at app
/// start). When disconnected it shows a connect button; when connected it
/// shows the account with a disconnect action. Rebuilds automatically as the
/// controller's state changes.
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final account = controller.account;
        if (account != null) {
          onConnected?.call(account.accountId.value);
          return _ConnectedChip(controller: controller, accountId: account.accountId.value);
        }
        return FilledButton.icon(
          onPressed: controller.busy ? null : controller.connect,
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
        TextButton(
          onPressed: controller.disconnect,
          child: const Text('Disconnect'),
        ),
      ],
    );
  }
}
