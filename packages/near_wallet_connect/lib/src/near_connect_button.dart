import 'package:flutter/material.dart';
import 'package:near_dart/near_dart.dart';

import 'near_wallet_controller.dart';
import 'wallet_option.dart';

/// Builds a disconnected connect button.
typedef NearConnectButtonBuilder =
    Widget Function(
      BuildContext context,
      NearWalletController controller,
      VoidCallback? onPressed,
    );

/// Builds the connected account view.
typedef NearConnectedBuilder =
    Widget Function(
      BuildContext context,
      NearWalletController controller,
      VoidCallback? onDisconnect,
    );

/// Builds an error view for the controller's last error.
typedef NearErrorBuilder =
    Widget Function(
      BuildContext context,
      NearWalletController controller,
      String error,
    );

/// Shows a wallet picker and returns the selected wallet.
typedef NearWalletPickerBuilder =
    Future<NearWalletOption?> Function(
      BuildContext context,
      NearWalletController controller,
      List<NearWalletOption> wallets,
    );

/// A drop-in NEAR wallet connect button with a built-in wallet picker.
///
/// The default UI is intentionally plain Material, but production apps can
/// replace each state with [connectBuilder], [connectedBuilder],
/// [errorBuilder], or [pickerBuilder].
class NearConnectButton extends StatelessWidget {
  const NearConnectButton({
    super.key,
    required this.controller,
    this.connectLabel = 'Connect NEAR wallet',
    this.disconnectLabel = 'Disconnect',
    this.compact = false,
    this.enabled = true,
    this.showError = true,
    this.onConnected,
    this.onWalletSelected,
    this.connectBuilder,
    this.connectedBuilder,
    this.errorBuilder,
    this.pickerBuilder,
  });

  /// The wallet controller driving the connection.
  final NearWalletController controller;

  /// Label shown while disconnected.
  final String connectLabel;

  /// Label shown on the default connected disconnect action.
  final String disconnectLabel;

  /// Uses tighter default sizing.
  final bool compact;

  /// Disables user interaction while keeping current state visible.
  final bool enabled;

  /// Whether the default widget renders [NearWalletController.error].
  final bool showError;

  /// Optional callback invoked when an account becomes connected.
  final void Function(String accountId)? onConnected;

  /// Optional callback invoked after the user picks a wallet.
  final void Function(NearWalletOption wallet)? onWalletSelected;

  /// Custom disconnected state.
  final NearConnectButtonBuilder? connectBuilder;

  /// Custom connected state.
  final NearConnectedBuilder? connectedBuilder;

  /// Custom error state.
  final NearErrorBuilder? errorBuilder;

  /// Custom wallet picker.
  final NearWalletPickerBuilder? pickerBuilder;

  Future<void> _pickAndConnect(BuildContext context) async {
    final wallets = controller.availableWallets;
    final choice = wallets.length == 1
        ? wallets.single
        : await (pickerBuilder ?? showNearWalletPicker)(
            context,
            controller,
            wallets,
          );
    if (choice == null) return;
    onWalletSelected?.call(choice);
    await controller.connect(wallet: choice);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final account = controller.account;
        if (account != null) {
          onConnected?.call(account.accountId.value);
          final onDisconnect = enabled && !controller.busy
              ? controller.disconnect
              : null;
          return connectedBuilder?.call(context, controller, onDisconnect) ??
              NearAccountBadge(
                accountId: account.accountId,
                wallet: controller.walletOption,
                onDisconnect: onDisconnect,
                disconnectLabel: disconnectLabel,
                compact: compact,
              );
        }

        final error = controller.error;
        final onPressed = enabled && !controller.busy
            ? () => _pickAndConnect(context)
            : null;
        final button =
            connectBuilder?.call(context, controller, onPressed) ??
            _DefaultConnectButton(
              label: connectLabel,
              busy: controller.busy,
              compact: compact,
              onPressed: onPressed,
            );

        if (!showError || error == null || error.isEmpty) return button;
        final errorWidget =
            errorBuilder?.call(context, controller, error) ??
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [button, errorWidget],
        );
      },
    );
  }
}

class _DefaultConnectButton extends StatelessWidget {
  const _DefaultConnectButton({
    required this.label,
    required this.busy,
    required this.compact,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = compact
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          )
        : null;
    return FilledButton.icon(
      style: style,
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.account_balance_wallet_outlined),
      label: Text(label),
    );
  }
}

/// Opens the default Material wallet picker.
Future<NearWalletOption?> showNearWalletPicker(
  BuildContext context,
  NearWalletController controller,
  List<NearWalletOption> wallets,
) {
  return showModalBottomSheet<NearWalletOption>(
    context: context,
    showDragHandle: true,
    builder: (context) => NearWalletPicker(wallets: wallets),
  );
}

/// A reusable wallet picker list.
class NearWalletPicker extends StatelessWidget {
  const NearWalletPicker({super.key, required this.wallets, this.onSelected});

  final List<NearWalletOption> wallets;
  final void Function(NearWalletOption wallet)? onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              trailing: wallet.supportsTestnet
                  ? null
                  : const Tooltip(
                      message: 'Mainnet only',
                      child: Icon(Icons.public, size: 18),
                    ),
              onTap: () {
                onSelected?.call(wallet);
                Navigator.of(context).pop(wallet);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Default connected-account chip used by [NearConnectButton].
class NearAccountBadge extends StatelessWidget {
  const NearAccountBadge({
    super.key,
    required this.accountId,
    this.wallet,
    this.onDisconnect,
    this.disconnectLabel = 'Disconnect',
    this.compact = false,
  });

  final AccountId accountId;
  final NearWalletOption? wallet;
  final VoidCallback? onDisconnect;
  final String disconnectLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final short = _shortAccount(accountId.value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Tooltip(
            message: accountId.value,
            child: Text(
              compact ? short : accountId.value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (wallet != null) ...[
          const SizedBox(width: 6),
          Text(wallet!.label, style: Theme.of(context).textTheme.bodySmall),
        ],
        TextButton(onPressed: onDisconnect, child: Text(disconnectLabel)),
      ],
    );
  }
}

/// Small balance text widget for NEAR balances.
class NearBalanceText extends StatelessWidget {
  const NearBalanceText({
    super.key,
    required this.balance,
    this.fractionDigits = 4,
    this.suffix = 'NEAR',
  });

  final NearToken balance;
  final int fractionDigits;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${balance.toNearString(fractionDigits: fractionDigits)} $suffix',
    );
  }
}

/// Displays a transaction status/result in a compact Material row.
class NearTransactionStatusView extends StatelessWidget {
  const NearTransactionStatusView({
    super.key,
    required this.state,
    this.transactionHash,
    this.error,
  });

  final NearTransactionViewState state;
  final String? transactionHash;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      NearTransactionViewState.idle => Theme.of(context).disabledColor,
      NearTransactionViewState.pending => Theme.of(context).colorScheme.primary,
      NearTransactionViewState.success => const Color(0xFF00A870),
      NearTransactionViewState.failure => Colors.red.shade700,
    };
    final icon = switch (state) {
      NearTransactionViewState.idle => Icons.radio_button_unchecked,
      NearTransactionViewState.pending => Icons.hourglass_top,
      NearTransactionViewState.success => Icons.check_circle,
      NearTransactionViewState.failure => Icons.error,
    };
    final text = switch (state) {
      NearTransactionViewState.idle => 'No transaction',
      NearTransactionViewState.pending => 'Transaction pending',
      NearTransactionViewState.success =>
        transactionHash == null
            ? 'Transaction confirmed'
            : 'Transaction confirmed: ${_shortHash(transactionHash!)}',
      NearTransactionViewState.failure => error ?? 'Transaction failed',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// State shown by [NearTransactionStatusView].
enum NearTransactionViewState { idle, pending, success, failure }

String _shortAccount(String value) => value.length <= 18
    ? value
    : '${value.substring(0, 8)}...${value.substring(value.length - 6)}';

String _shortHash(String value) => value.length <= 16
    ? value
    : '${value.substring(0, 8)}...${value.substring(value.length - 6)}';
