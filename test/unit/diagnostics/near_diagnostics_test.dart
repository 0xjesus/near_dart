import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

void main() {
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
