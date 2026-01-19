## 0.1.0

Initial release of near_dart SDK.

### Features

- **RPC Client**
  - Multi-network support: Mainnet, Testnet, or custom RPC
  - Methods: `status`, `block`, `viewAccount`, `viewAccessKey`, `callFunction`, `validators`, `gasPrice`
  - Type-safe responses with sealed classes

- **Type-Safe Primitives**
  - `AccountId` with validation
  - `NearToken` for handling 24-decimal precision
  - `PublicKey` with key type detection
  - `CryptoHash` for block/transaction hashes
  - `BlockReference` for querying at specific points

- **Wallet Integration**
  - `WalletAdapter` interface for wallet integrations
  - `MyNearWalletAdapter` for deep link wallet connection
  - `WalletConnectAdapterBase` for WalletConnect 2.0

- **Transaction Building**
  - All action types: `CreateAccount`, `DeployContract`, `FunctionCall`, `Transfer`, `Stake`, `AddKey`, `DeleteKey`, `DeleteAccount`
  - Multi-action transaction support
  - NEP-413 message signing

- **Platform Support**
  - iOS, Android, Web, Desktop
  - Pure Dart with no platform-specific dependencies
