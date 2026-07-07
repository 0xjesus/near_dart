import 'dart:convert';

import '../wallet/nep413.dart';

/// Wallet signature standards supported by NEAR Intents.
enum IntentSigningStandard {
  nep413('nep413'),
  erc191('erc191'),
  rawEd25519('raw_ed25519'),
  webauthn('webauthn'),
  tonConnect('ton_connect'),
  sep53('sep53'),
  tip191('tip191');

  const IntentSigningStandard(this.wireValue);

  /// Wire value used by the 1Click/Verifier APIs.
  final String wireValue;

  /// Parses a wire value.
  factory IntentSigningStandard.fromJson(String value) {
    for (final standard in values) {
      if (standard.wireValue == value) return standard;
    }
    throw ArgumentError.value(
      value,
      'value',
      'Unsupported intent signing standard',
    );
  }
}

/// Unsigned intent payload returned by the 1Click API.
class GeneratedIntent {
  const GeneratedIntent({
    required this.standard,
    required this.payload,
    required this.raw,
    this.correlationId,
  });

  factory GeneratedIntent.fromJson(Map<String, dynamic> json) {
    final envelope = json['intent'] is Map ? json['intent'] as Map : json;
    final standard = envelope['standard'];
    final payload = envelope['payload'];
    if (standard is! String) {
      throw const FormatException('Generated intent is missing standard');
    }
    if (payload is! Map) {
      throw const FormatException('Generated intent is missing payload object');
    }
    return GeneratedIntent(
      standard: IntentSigningStandard.fromJson(standard),
      payload: payload.cast<String, dynamic>(),
      correlationId: json['correlationId'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  /// Unique request trace ID returned by 1Click, when present.
  final String? correlationId;

  /// Signing standard requested for this intent.
  final IntentSigningStandard standard;

  /// Exact payload the wallet must sign.
  final Map<String, dynamic> payload;

  /// Original API response for fields that are not modeled yet.
  final Map<String, dynamic> raw;

  /// Converts a generated NEP-413 intent to the SDK's signable payload.
  ///
  /// The API-provided `message`, `nonce`, `recipient` and optional
  /// `callbackUrl` are preserved exactly. The nonce is base64-decoded because
  /// [Nep413Payload] stores the 32 nonce bytes.
  Nep413Payload asNep413Payload() {
    if (standard != IntentSigningStandard.nep413) {
      throw StateError(
        'Generated intent uses ${standard.wireValue}, not NEP-413',
      );
    }
    final message = payload['message'];
    final nonce = payload['nonce'];
    final recipient = payload['recipient'];
    if (message is! String || nonce is! String || recipient is! String) {
      throw const FormatException(
        'NEP-413 intent payload requires message, nonce and recipient strings',
      );
    }
    return Nep413Payload(
      message: message,
      nonce: base64Decode(nonce),
      recipient: recipient,
      callbackUrl: payload['callbackUrl'] as String?,
    );
  }
}

/// Signed multi-payload submitted back to NEAR Intents.
class SignedMultiPayload {
  const SignedMultiPayload({
    required this.standard,
    required this.payload,
    required this.publicKey,
    required this.signature,
  });

  /// Builds signed data from a generated NEP-413 intent and wallet signature.
  factory SignedMultiPayload.fromNep413({
    required GeneratedIntent generated,
    required Nep413SignedMessage signed,
  }) {
    if (generated.standard != IntentSigningStandard.nep413) {
      throw StateError(
        'Generated intent uses ${generated.standard.wireValue}, not NEP-413',
      );
    }
    return SignedMultiPayload(
      standard: IntentSigningStandard.nep413,
      payload: generated.payload,
      publicKey: signed.publicKey.value,
      signature: signed.signature,
    );
  }

  /// Signature standard used by the wallet.
  final IntentSigningStandard standard;

  /// Payload that was signed. Do not normalize or mutate API-generated data.
  final Map<String, dynamic> payload;

  /// Public key in the wire format expected by the upstream API.
  final String publicKey;

  /// Signature in the wire format expected by the upstream API.
  final String signature;

  Map<String, dynamic> toJson() => {
    'standard': standard.wireValue,
    'payload': payload,
    'public_key': publicKey,
    'signature': signature,
  };
}

/// Response returned after submitting a signed intent.
class SubmitIntentResponse {
  const SubmitIntentResponse({
    required this.raw,
    this.intentHash,
    this.correlationId,
    this.status,
    this.reason,
  });

  factory SubmitIntentResponse.fromJson(Map<String, dynamic> json) {
    return SubmitIntentResponse(
      intentHash:
          json['intentHash'] as String? ?? json['intent_hash'] as String?,
      correlationId: json['correlationId'] as String?,
      status: json['status'] as String?,
      reason: json['reason'] as String?,
      raw: Map.unmodifiable(json),
    );
  }

  /// Intent hash returned by the API, when available.
  final String? intentHash;

  /// Unique request trace ID returned by 1Click, when present.
  final String? correlationId;

  /// Upstream status value, for Message Bus compatibility.
  final String? status;

  /// Error reason when the upstream API returns one in a 200 response.
  final String? reason;

  /// Original API response for fields that are not modeled yet.
  final Map<String, dynamic> raw;
}
