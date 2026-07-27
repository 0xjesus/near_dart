# near_dart

SDK completo de NEAR Protocol para Flutter/Dart.

[![pub package](https://img.shields.io/pub/v/near_dart.svg)](https://pub.dev/packages/near_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Un SDK seguro en tipos (type-safe) y agnóstico a la plataforma para construir aplicaciones de NEAR Protocol con Flutter y Dart. Funciona en iOS, Android, Web y Escritorio.

<p align="center">
  <img src="https://raw.githubusercontent.com/0xjesus/near_dart/main/docs/demo/glass-android.gif" alt="NEAR Flutter SDK demo on Android" width="240"/>
</p>

<p align="center"><em>La aplicación de ejemplo — firma y envío local y conexión de wallet — ejecutándose en Android.</em></p>

## Características

- **Firma y Envío Local**: pares de claves ed25519, serialización Borsh, difusión de `send_tx` — compatible byte por byte con near-api-js.
- **API de `Account` de Alto Nivel**: `transfer()` / `callFunction()` en una sola llamada (nonce + hash de bloque resueltos automáticamente).
- **Cliente RPC**: Consulta el estado de la blockchain, cuentas, contratos y validadores — endpoints de FastNear por defecto, con failover automático.
- **Integración de Wallets**: Conecta wallets a través de WalletConnect o deep links.
- **NEAR Intents**: Descubrimiento de activos 1Click, constructor de cotizaciones, monitoreo del ciclo de vida de swaps, historial del Explorer, ayudantes de intents firmados y JSON-RPC de Message Bus para integraciones de solvers asociados.
- **Configuración de Red Tipada**: `NearNetwork.mainnet`, `NearNetwork.testnet` y `NearNetwork.custom(...)` con metadatos de RPC, wallet, explorer y cadena.
- **Primitivas Seguras en Tipos**: `AccountId`, `NearToken`, `PublicKey`, `CryptoHash`.
- **Construcción de Transacciones**: Todas las acciones de NEAR, incluyendo Contratos Globales NEP-591.
- **Soporte NEP-413**: Firma de mensajes para autenticación.
- **Probado contra la cadena real**: cada lanzamiento ejecuta un E2E real de firma y envío en testnet.

## Soporte de Plataforma

| Característica | Android | iOS | Web | macOS | Windows | Linux |
|---|---|---|---|---|---|---|
| Consultas RPC | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Firma local (Borsh + ed25519) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Firma / verificación NEP-413 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Redirección MyNearWallet | ✅ | ✅ | ✅ | ⚠️ no probado | ⚠️ no probado | ⚠️ no probado |
| Intear Wallet (bridge + deep link) | ✅ | ✅ | ⚠️ requiere app nativa | ⚠️ no probado | ⚠️ no probado | ⚠️ no probado |
| HOT Wallet (relay) | ✅ solo mainnet | ✅ solo mainnet | ✅ solo mainnet | ⚠️ no probado | ⚠️ no probado | ⚠️ no probado |
| Almacenamiento seguro de claves | ✅ Keystore | ✅ Keychain | ⚠️ almacenamiento simple (sin secretos de OS en web) | ✅ Keychain | ✅ DPAPI | ✅ libsecret |

Las filas marcadas como *no probado* deberían funcionar (Dart puro + url_launcher) pero aún no tienen una ejecución end-to-end verificada. Detalles de seguridad: [docs/security.md](https://github.com/0xjesus/near_dart/blob/main/docs/security.md). Guía de NEAR Intents: [docs/intents.md](https://github.com/0xjesus/near_dart/blob/main/docs/intents.md). Evidencia de la aplicación de referencia: [NearCoffee SDK + Intents tutorial](https://raw.githubusercontent.com/0xjesus/near-coffee/main/docs/demo/nearcoffee-sdk-intents-tutorial.mp4).

## Guías

- [Primera transacción en 5 minutos](https://github.com/0xjesus/near_dart/blob/main/docs/5-minute-guide.md)
- [Recetas de Wallets](https://github.com/0xjesus/near_dart/blob/main/docs/wallet-recipes.md)
- [Recetas de arquitectura de Flutter](https://github.com/0xjesus/near_dart/blob/main/docs/flutter-architectures.md)
- [NEAR Intents](https://github.com/0xjesus/near_dart/blob/main/docs/intents.md)
- [NEAR AI](https://github.com/0xjesus/near_dart/blob/main/docs/near-ai.md)
- [Modelo de seguridad](https://github.com/0xjesus/near_dart/blob/main/docs/security.md)
- [Solución de problemas](https://github.com/0xjesus/near_dart/blob/main/docs/troubleshooting.md)
- [Lista de verificación de lanzamiento](https://github.com/0xjesus/near_dart/blob/main/docs/release.md)

## Instalación

```yaml
dependencies:
  near_dart: ^0.5.0
```

## Inicio Rápido

```dart
import 'package:near_dart/near_dart.dart';

void main() async {
  // Crear cliente (mainnet o testnet)
  final client = NearRpcClient.mainnet();

  // Obtener estado de la red
  final status = await client.status();
  switch (status) {
    case RpcSuccess(:final value):
      print('Chain: ${value.chainId}');
      print('Block: ${value.syncInfo.latestBlockHeight}');
    case RpcFailure(:final error):
      print('Error: ${error.message}');
  }

  // Consultar cuenta
  final result = await client.viewAccount(
    accountId: AccountId('alice.near'),
    blockReference: BlockReference.finality(Finality.final_),
  );

  if (result.isSuccess) {
    final account = result.getOrNull()!;
    print('Balance: ${account.amount.toNear()} NEAR');
  }

  client.close();
}
```

## Firmar y Enviar Transacciones (claves locales)

La forma más rápida de ejecutar transacciones, sin necesidad de redirección de wallet:

```dart
import 'package:near_dart/near_dart.dart';

void main() async {
  final client = NearRpcClient.testnet();

  final account = Account(
    accountId: AccountId('alice.testnet'),
    keyPair: await KeyPairEd25519.fromString('ed25519:<tu clave secreta>'),
    client: client,
  );

  // Transferir NEAR
  final result = await account.transfer(
    receiverId: AccountId('bob.testnet'),
    amount: NearToken.fromNear(1),
  );

  switch (result) {
    case RpcSuccess(:final value):
      print('Ejecutado! https://testnet.nearblocks.io/txns/${value.transaction.hash}');
    case RpcFailure(:final error):
      print('Falló: ${error.message}');
  }

  // Llamar a un método de contrato que cambie el estado
  await account.callFunction(
    contractId: AccountId('wrap.testnet'),
    methodName: 'near_deposit',
    deposit: NearToken.fromNear(1),
  );

  client.close();
}
```

¿Necesitas control de más bajo nivel? Firma y difunde manualmente:

```dart
final signed = await signTransaction(
  Transaction(
    signerId: AccountId('alice.testnet'),
    receiverId: AccountId('bob.testnet'),
    nonce: nonce,                 // nonce de la clave de acceso + 1
    blockHash: recentBlockHash,   // obtenido de viewAccessKey o block()
    actions: [TransferAction(deposit: NearToken.fromNear(1))],
  ),
  keyPair,
);
print(signed.hash);               // hash de la transacción (base58)
await client.sendTransaction(signed, waitUntil: TxExecutionStatus.final_);
```

La serialización y las firmas se validan byte por byte frente a los vectores canónicos de near-api-js, y el pipeline completo se ejecuta end-to-end contra la testnet real en CI.

## Cliente RPC

### Estado de la Red

```dart
final result = await client.status();
```

### Información de Cuenta

```dart
final result = await client.viewAccount(
  accountId: AccountId('alice.near'),
  blockReference: BlockReference.finality(Finality.final_),
);
```

### Llamar a Función View de Contrato

```dart
final result = await client.callFunction(
  accountId: AccountId('token.near'),
  methodName: 'ft_balance_of',
  args: {'account_id': 'alice.near'},
  blockReference: BlockReference.finality(Finality.final_),
);

if (result.isSuccess) {
  final balance = result.getOrNull()!.resultAsJson();
  print('Balance de token: $balance');
}
```

### Validadores

```dart
final result = await client.validators();
if (result.isSuccess) {
  final validators = result.getOrNull()!;
  print('Validadores actuales: ${validators.currentValidators.length}');
}
```

### Configuración de Red Tipada

```dart
final network = NearNetwork.custom(
  name: 'localnet',
  rpcUrl: 'http://127.0.0.1:3030',
  explorerUrl: 'http://127.0.0.1:4000',
);

final client = NearRpcClient.forNetwork(network);
print(network.transactionUrl('tx-hash'));
```

## NEAR Intents

Construye una UX de swap cross-chain con la API 1Click sin tener que rutear manualmente las transacciones del solver:

```dart
final intents = OneClickClient();
final catalog = OneClickAssetCatalog(client: intents);
final builder = OneClickQuoteBuilder();

final wnear = await catalog.requireByAssetId('nep141:wrap.near');
final usdc = await catalog.requireByAssetId('nep141:usdc.near');

final request = builder.exactInput(
  originToken: wnear,
  destinationToken: usdc,
  amount: '0.1', // convertido exactamente desde decimales, sin matemáticas de punto flotante
  refundTo: 'alice.near',
  recipient: 'alice.near',
);

final swap = OneClickSwapController(client: intents);
final quote = await swap.quote(request);

print(quote.quote.amountOutFormatted);
```

Para swaps reales, establece `dry: false`, envía los fondos a la dirección de depósito devuelta, luego usa `submitDeposit()` y `pollStatus()` hasta que el estado sea `success`, `refunded` o `failed`. La actividad histórica de 1Click está disponible a través de `OneClickExplorerClient` para paneles de control y herramientas de soporte.

## Integración de Wallet

### Construcción de Transacciones

```dart
// Transferencia simple
final tx = Transaction(
  signerId: AccountId('alice.near'),
  receiverId: AccountId('bob.near'),
  actions: [
    TransferAction(deposit: NearToken.fromNear(1)),
  ],
);

// Llamada a función de contrato
final tx = Transaction(
  signerId: AccountId('alice.near'),
  receiverId: AccountId('token.near'),
  actions: [
    FunctionCallAction(
      methodName: 'ft_transfer',
      args: {'receiver_id': 'bob.near', 'amount': '1000000'},
      deposit: NearToken.oneYocto(),
    ),
  ],
);
```

### Tipos de Acciones

```dart
CreateAccountAction()
DeployContractAction(code: wasmBytes)
FunctionCallAction(methodName: 'method', args: {...}, deposit: NearToken.zero())
TransferAction(deposit: NearToken.fromNear(10))
StakeAction(stake: NearToken.fromNear(100), publicKey: PublicKey('ed25519:...'))
AddKeyAction(publicKey: key, accessKey: FullAccessKey())
DeleteKeyAction(publicKey: key)
DeleteAccountAction(beneficiaryId: AccountId('beneficiary.near'))
```

### Integración MyNearWallet (conecta una vez, luego firma localmente)

`signIn()` genera una **clave de llamada de función (function-call key)**, redirecciona a MyNearWallet para provisionarla, y `completeSignIn()` almacena la clave privada — para que después puedas llamar a los contratos **localmente, sin más redirecciones**.

```dart
final adapter = MyNearWalletAdapter(
  config: MyNearWalletConfig(
    contractId: AccountId('app.near'),
    successUrl: 'myapp://callback/success',   // URL https en web
    failureUrl: 'myapp://callback/failure',
    network: MyNearWalletNetwork.mainnet,
  ),
  // Persiste las claves a través de la redirección/reinicio (ver SharedPrefsKeyStore en la app de ejemplo). Por defecto usa InMemoryKeyStore.
  keyStore: myPersistentKeyStore,
  launchUrl: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

// 1. Conectar: genera una clave y redirecciona a la wallet.
await adapter.signIn(contractId: AccountId('app.near'));

// 2. Cuando la wallet redirecciona de vuelta (deep link en móvil, URL de app en web):
final account = await adapter.completeSignIn(callbackUri);
print('Conectado: ${account?.accountId}');

// 3. De ahora en adelante, firma llamadas de contrato localmente — sin redirección:
final near = Account(
  accountId: account!.accountId,
  keyPair: (await adapter.keyFor(account.accountId))!,
  client: NearRpcClient.mainnet(),
);
await near.callFunction(
  contractId: AccountId('app.near'),
  methodName: 'set_greeting',
  args: {'greeting': 'hola'},
);
```

## Primitivas Seguras en Tipos

### AccountId

```dart
final account = AccountId('alice.near');  // Valida el formato
```

### NearToken

```dart
final amount = NearToken.fromNear(10);     // 10 NEAR
final small = NearToken.oneYocto();        // 1 yoctoNEAR
final zero = NearToken.zero();
print(amount.toNear());  // 10.0
```

### NearGas

```dart
final defaultCallGas = NearGas.defaultFunctionCall; // 30 TGas
final customGas = NearGas.teraGas(100);              // BigInt exacto
```

### Llamadas View Tipadas

```dart
final metadata = await client.viewFunction<Map<String, dynamic>>(
  contractId: AccountId('wrap.near'),
  methodName: 'ft_metadata',
  decode: (json) => (json as Map).cast<String, dynamic>(),
);
print(metadata.getOrThrow()['symbol']);
```

### PublicKey

```dart
final key = PublicKey('ed25519:6E8sCci9badyRkXb3JoRpBj5p8C6Tw41ELDZoiihKEtp');
print(key.keyType);  // KeyType.ed25519
```

### BlockReference

```dart
BlockReference.finality(Finality.final_)  // Último finalizado
BlockReference.finality(Finality.optimistic)  // Último (puede haber reorg)
BlockReference.blockId(123456789)  // Altura específica
BlockReference.blockHash(CryptoHash('...'))  // Hash específico
```

## Manejo de Errores

```dart
final result = await client.viewAccount(...);

switch (result) {
  case RpcSuccess(:final value):
    print('Balance: ${value.amount.toNear()}');
  case RpcFailure(:final error):
    switch (error.nearErrorCode) {
      case NearErrorCode.rpcTimeout:
        scheduleRetry();
      case NearErrorCode.rateLimited:
        useBackoff();
      default:
        showError(error.message);
    }
}
```

## Diagnósticos y Seguridad de Wallet

Registra un `NearLogger` al momento de la construcción y copia solo los campos operacionales explícitamente seguros hacia la telemetría:

```dart
void nearLogger(NearLogEvent event) {
  final safe = <String, Object?>{
    if (event.metadata['durationMs'] case final value?) 'durationMs': value,
    if (event.metadata['statusCode'] case final value?) 'statusCode': value,
    if (event.metadata['failureCode'] case final value?) 'failureCode': value,
  };
  print('${event.type.name} ${event.operation} $safe');
}

final client = NearRpcClient.mainnet(logger: nearLogger);
```

No añadas payloads, URLs de callback, mensajes, nonces, firmas, valores de autorización o material de claves en un callback del logger. Para flujos de wallet en Flutter, `near_wallet_connect` proporciona una política on-chain opcional:

```dart
import 'package:near_wallet_connect/near_wallet_connect.dart';

final wallet = NearWalletController(
  network: MyNearWalletNetwork.mainnet,
  contractId: AccountId('app.near'),
  logger: nearLogger,
  securityPolicy: const NearWalletSecurityPolicy(
    verifyAccessKeyOnConnect: true,
    transactionFinality: TxExecutionStatus.final_,
  ),
);
```

Los valores por defecto mantienen el comportamiento existente y no realizan ninguna de estas comprobaciones. Lee el [modelo de seguridad](https://github.com/0xjesus/near_dart/blob/main/docs/security.md) y la [guía de solución de problemas](https://github.com/0xjesus/near_dart/blob/main/docs/troubleshooting.md) para obtener garantías exactas, advertencias sobre relays y manejo de errores tipados.

## Aplicación de Ejemplo

Mira el directorio [example/](example/) para ver una aplicación de Flutter completa que demuestra cada característica del SDK: firma y envío local, conexión de wallet (redirección + deep link) y todas las consultas RPC — con cambio de red entre testnet y mainnet.

## Verificado en dispositivos y cadenas reales

Evidencia registrada de la aplicación de ejemplo ejecutándose contra la **testnet real de NEAR** (sin mocks en ninguna capa):

| Demo | Evidencia | Prueba on-chain |
|---|---|---|
| Android: generar clave -> faucet -> **firmar y enviar on-chain** | [video](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-sign-and-send-onchain.mp4) / [gif](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-sign-and-send-onchain.gif) | [`JByxPfTt...34cZG`](https://testnet.nearblocks.io/txns/JByxPfTtJwhEatZhU8FimkbkazygFajvg5ygnTH34cZG) |
| Android: wallet connect -> navegador -> deep link `nearsdk://` -> conectado | [video](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-wallet-connect-roundtrip.mp4) / [gif](https://github.com/0xjesus/near_dart/blob/main/docs/demo/android-wallet-connect-roundtrip.gif) | flujo de provisión de clave function-call |

Adicionalmente verificado: web (Chrome, dart2js **y** dart2wasm — firmas idénticas byte por byte vs near-api-js), transferencias on-chain reales desde el navegador, y un E2E programado en CI que firma y envía una transacción real de testnet. Las compilaciones de iOS se verifican en cada push mediante un job de CI en macOS.

## Pruebas

```bash
dart test --exclude-tags integration   # pruebas offline (sin red)
dart test test/integration/testnet/    # pruebas RPC live en testnet
dart test test/e2e/                    # incluye un firma+envío REAL en testnet
```

La serialización y las firmas se validan **byte por byte** contra los vectores canónicos de near-api-js@7.2.0 (`test/fixtures/near_api_js_vectors.json`).

## Licencia

Licencia MIT - ver [LICENSE](LICENSE) para más detalles.

## Enlaces

- [pub.dev](https://pub.dev/packages/near_dart)
- [GitHub](https://github.com/0xjesus/near_dart)
- [NEAR Protocol](https://near.org)
