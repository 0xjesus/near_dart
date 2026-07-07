# NEAR AI

NEAR AI support should start as documentation and examples rather than a hard
SDK dependency. NEAR AI Cloud exposes OpenAI-compatible HTTP APIs, so Flutter
apps and backends can use normal HTTP clients while keeping wallet approval
boundaries explicit.

Sources:

- https://docs.near.ai/cloud/quickstart/
- https://docs.near.ai/cloud/guides/openai-compatibility/
- https://docs.near.ai/cloud/private-inference/
- https://docs.near.ai/cloud/verification/

## Do Not Put Shared API Keys In Mobile Apps

NEAR AI Cloud API keys should be kept secret. Use one of these patterns:

- Flutter app -> your backend -> NEAR AI Cloud.
- Flutter prototype with a user-provided key stored locally by the user.
- Server-side agent proposes a transaction/intent; user approves in wallet.

Do not embed a shared project key in a published APK, IPA, or web bundle.

## OpenAI-Compatible Request

Gateway base URL:

```text
https://cloud-api.near.ai/v1
```

Direct model completions use:

```text
https://{slug}.completions.near.ai/v1
```

Check current models:

```bash
curl https://cloud-api.near.ai/v1/models \
  -H "Authorization: Bearer $NEARAI_API_KEY"
```

Minimal Dart backend/prototype call:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> askNearAi({
  required String apiKey,
  required String model,
  required String prompt,
}) async {
  final response = await http.post(
    Uri.parse('https://cloud-api.near.ai/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    }),
  );

  if (response.statusCode != 200) {
    throw StateError('NEAR AI error ${response.statusCode}: ${response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final choices = json['choices'] as List;
  return choices.first['message']['content'] as String;
}
```

## Agent + Intents Pattern

Use NEAR AI to propose, not to silently spend:

1. Backend asks NEAR AI to interpret user intent.
2. Backend calls `OneClickClient.quote(dry: true)` or a real quote endpoint.
3. App shows the proposed route, fees, and status.
4. User signs in wallet.
5. App submits the signed payload and confirms status.

The wallet remains the trust boundary. An AI agent may prepare payloads, but
the user should approve economic actions in a wallet UI.

## Private Inference Notes

NEAR AI Cloud documents TEE-based private inference and verification. Use the
gateway for a simple OpenAI-compatible path; use direct completions when you
need lower latency or a simpler trust model tied to a model endpoint.

For production, document which model path you use and whether the privacy
guarantee applies to that model. Third-party proxied models may not inherit the
same TEE guarantees as NEAR-hosted models.

