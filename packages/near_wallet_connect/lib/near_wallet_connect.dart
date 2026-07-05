/// Drop-in NEAR wallet connection for Flutter.
///
/// Add the package, create a [NearWalletController], call `init()` once, and
/// drop a [NearConnectButton] in your UI. Connecting provisions a
/// function-call key so you then sign contract calls locally via
/// `controller.signer()` — no more redirects.
///
/// Re-exports the relevant `near_dart` types (AccountId, NearToken, Account,
/// MyNearWalletNetwork, …) so apps need a single import.
library near_wallet_connect;

export 'package:near_dart/near_dart.dart'
    show
        AccountId,
        NearToken,
        Account,
        KeyStore,
        WalletAccount,
        MyNearWalletNetwork,
        NearRpcClient,
        TxExecutionStatus,
        Nep413Payload,
        Nep413SignedMessage,
        IntearWalletAdapter,
        IntearWalletConfig,
        HotWalletAdapter,
        HotWalletConfig;

export 'src/near_connect_button.dart';
export 'src/near_wallet_controller.dart';
export 'src/secure_key_store.dart';
export 'src/shared_prefs_key_store.dart';
export 'src/wallet_option.dart';
