import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:near_dart/near_dart.dart';
import 'package:test/test.dart';

typedef _IntentsEndpointCall =
    Future<void> Function(
      Uri endpoint,
      List<NearLogEvent> events,
      http.Client client,
    );

void main() {
  test(
    'all Intents clients reject invalid explicit ports before transport',
    () async {
      final clients = <_IntentsEndpointCall>[
        (endpoint, events, httpClient) => OneClickClient(
          baseUri: endpoint,
          logger: events.add,
          httpClient: httpClient,
        ).tokens(),
        (endpoint, events, httpClient) => OneClickExplorerClient(
          baseUri: endpoint,
          logger: events.add,
          httpClient: httpClient,
        ).transactions(),
        (endpoint, events, httpClient) => SolverRelayClient(
          endpoint: endpoint,
          logger: events.add,
          httpClient: httpClient,
        ).getStatus('intent-hash'),
      ];

      for (final endpoint in [
        'https://example.com:-1/api',
        'https://example.com:99999/api',
      ]) {
        for (final invoke in clients) {
          final events = <NearLogEvent>[];
          var transportCalls = 0;

          await expectLater(
            invoke(
              Uri.parse(endpoint),
              events,
              MockClient((_) async {
                transportCalls++;
                return http.Response('{}', 200);
              }),
            ),
            throwsA(
              isA<NearSdkException>()
                  .having(
                    (error) => error.code,
                    'code',
                    NearErrorCode.invalidInput,
                  )
                  .having((error) => error.retryable, 'retryable', isFalse),
            ),
            reason: endpoint,
          );
          expect(events.map((event) => event.type), [
            NearLogEventType.intentsRequestStarted,
            NearLogEventType.intentsRequestFailed,
          ]);
          expect(
            events.where(
              (event) =>
                  event.type == NearLogEventType.intentsRequestSucceeded ||
                  event.type == NearLogEventType.intentsRequestFailed,
            ),
            hasLength(1),
          );
          expect(transportCalls, 0, reason: endpoint);
        }
      }
    },
  );
}
