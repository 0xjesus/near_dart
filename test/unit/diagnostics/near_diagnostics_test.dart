import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
  test('defines explicit wallet flow terminal events', () {
    expect(NearLogEventType.walletFlowSucceeded.name, 'walletFlowSucceeded');
    expect(NearLogEventType.walletFlowFailed.name, 'walletFlowFailed');
  });

  test('redacts sensitive metadata recursively', () {
    final event = NearLogEvent(
      level: NearLogLevel.info,
      type: NearLogEventType.rpcRequestStarted,
      operation: 'query',
      metadata: {
        'endpoint': 'https://rpc.example.com',
        'authorization': 'Bearer secret',
        'nested': {'signature': 'abc', 'attempt': 2},
      },
      timestamp: DateTime.utc(2026, 7, 13),
    );

    expect(event.metadata['endpoint'], 'https://rpc.example.com');
    expect(event.toString(), isNot(contains('Bearer secret')));
    expect(event.toString(), isNot(contains('abc')));
    expect(event.toString(), contains('<redacted>'));
  });

  test('normalizes sensitive metadata key names before redacting', () {
    final event = NearLogEvent(
      level: NearLogLevel.info,
      type: NearLogEventType.rpcRequestStarted,
      operation: 'query',
      metadata: {
        'private_key': 'private value',
        'signed-tx': 'signed value',
        'requestBody': 'body value',
        'apiToken': 'token value',
        'nonce': 7,
      },
    );

    for (final value in event.metadata.values) {
      expect(value, '<redacted>');
    }
  });

  test(
    'redacts canonical signed transactions and NEP-413 messages nested in lists',
    () {
      const signedTransactionSnakeCase = 'signed transaction snake sentinel';
      const signedTransactionCamelCase = 'signed transaction camel sentinel';
      const nep413MessageBody = 'NEP-413 message body sentinel';
      final event = NearLogEvent(
        level: NearLogLevel.info,
        type: NearLogEventType.rpcRequestStarted,
        operation: 'query',
        metadata: {
          'events': [
            {
              'signed_transaction': signedTransactionSnakeCase,
              'signedTransaction': signedTransactionCamelCase,
              'message': nep413MessageBody,
            },
          ],
        },
      );

      for (final value in <String>[
        signedTransactionSnakeCase,
        signedTransactionCamelCase,
        nep413MessageBody,
      ]) {
        expect(event.metadata.toString(), isNot(contains(value)));
        expect(event.toString(), isNot(contains(value)));
      }
      expect(event.metadata.toString(), contains('<redacted>'));
      expect(event.toString(), contains('<redacted>'));
    },
  );

  test('distinguishes signed transaction keys from safe similar keys', () {
    const decoratedSignedTransaction = 'decorated signed transaction sentinel';
    const decoratedSignedTx = 'decorated signed tx sentinel';
    const statusMessage = 'request completed';
    const errorMessage = 'request failed';
    final event = NearLogEvent(
      level: NearLogLevel.info,
      type: NearLogEventType.rpcRequestStarted,
      operation: 'query',
      metadata: {
        'requestSignedTransaction': decoratedSignedTransaction,
        'wallet-signed-tx-payload': decoratedSignedTx,
        'unsignedTransactionCount': 2,
        'unsignedTxCount': 3,
        'statusMessage': statusMessage,
        'messageCount': 4,
        'errorMessage': errorMessage,
      },
    );

    for (final value in <String>[
      decoratedSignedTransaction,
      decoratedSignedTx,
    ]) {
      expect(event.metadata.toString(), isNot(contains(value)));
      expect(event.toString(), isNot(contains(value)));
    }
    expect(event.metadata['unsignedTransactionCount'], 2);
    expect(event.metadata['unsignedTxCount'], 3);
    expect(event.metadata['statusMessage'], statusMessage);
    expect(event.metadata['messageCount'], 4);
    expect(event.metadata['errorMessage'], errorMessage);
  });

  test('redacts acronym-cased signed transactions nested in metadata', () {
    const walletSignedTxHash = 'wallet signed TX hash sentinel';
    const rpcSignedTransactionHash = 'RPC signed transaction hash sentinel';
    final event = NearLogEvent(
      level: NearLogLevel.info,
      type: NearLogEventType.rpcRequestStarted,
      operation: 'query',
      metadata: {
        'responses': [
          {
            'walletSignedTXHash': walletSignedTxHash,
            'nested': [
              {'RPCSignedTransactionHash': rpcSignedTransactionHash},
            ],
            'unsignedTransactionCount': 2,
            'unsignedTxCount': 3,
          },
        ],
      },
    );

    for (final value in <String>[
      walletSignedTxHash,
      rpcSignedTransactionHash,
    ]) {
      expect(event.metadata.toString(), isNot(contains(value)));
      expect(event.toString(), isNot(contains(value)));
    }

    final response =
        (event.metadata['responses'] as List<Object?>).single
            as Map<Object?, Object?>;
    expect(response['unsignedTransactionCount'], 2);
    expect(response['unsignedTxCount'], 3);
  });

  test('deeply copies and freezes nested metadata collections', () {
    final nested = <String, Object?>{
      'attempt': 2,
      'headers': <String, Object?>{'requestId': 'first'},
    };
    final attempts = <Object?>[
      1,
      <String, Object?>{'durationMs': 50},
    ];
    final source = <String, Object?>{'nested': nested, 'attempts': attempts};
    final event = NearLogEvent(
      level: NearLogLevel.info,
      type: NearLogEventType.rpcRequestStarted,
      operation: 'query',
      metadata: source,
    );

    nested['attempt'] = 3;
    (nested['headers'] as Map<String, Object?>)['requestId'] = 'changed';
    attempts.add(3);
    (attempts[1] as Map<String, Object?>)['durationMs'] = 100;

    final eventNested = event.metadata['nested'] as Map<Object?, Object?>;
    final eventHeaders = eventNested['headers'] as Map<Object?, Object?>;
    final eventAttempts = event.metadata['attempts'] as List<Object?>;
    final eventDuration = eventAttempts[1] as Map<Object?, Object?>;

    expect(eventNested['attempt'], 2);
    expect(eventHeaders['requestId'], 'first');
    expect(eventAttempts, hasLength(2));
    expect(eventDuration['durationMs'], 50);
    expect(() => eventNested['attempt'] = 4, throwsUnsupportedError);
    expect(() => eventAttempts.add(3), throwsUnsupportedError);
    expect(() => eventDuration['durationMs'] = 100, throwsUnsupportedError);
  });

  test('does not allow logger failures to escape', () {
    final event = NearLogEvent(
      level: NearLogLevel.error,
      type: NearLogEventType.rpcRequestFailed,
      operation: 'query',
    );

    expect(
      () => emitNearLog((_) => throw StateError('logger failure'), event),
      returnsNormally,
    );
  });
}
