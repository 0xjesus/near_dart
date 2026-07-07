import 'one_click_client.dart';
import 'one_click_models.dart';

/// Parsed 1Click asset identifier, such as `nep141:wrap.near`.
class OneClickAssetId {
  const OneClickAssetId({required this.standard, required this.reference});

  factory OneClickAssetId.parse(String value) {
    final separator = value.indexOf(':');
    if (separator <= 0 || separator == value.length - 1) {
      throw FormatException('Invalid NEAR Intents asset id: $value');
    }
    return OneClickAssetId(
      standard: value.substring(0, separator),
      reference: value.substring(separator + 1),
    );
  }

  final String standard;
  final String reference;

  bool get isNep141 => standard == 'nep141';

  @override
  String toString() => '$standard:$reference';
}

/// Exact decimal conversion for 1Click token amounts.
class OneClickAmount {
  const OneClickAmount._();

  /// Converts a human decimal amount into the smallest-unit integer string.
  static String parseDecimal(String value, int decimals) {
    if (decimals < 0) {
      throw ArgumentError.value(decimals, 'decimals', 'Must be non-negative');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Amount cannot be empty');
    }
    if (trimmed.startsWith('-')) {
      throw const FormatException('Amount cannot be negative');
    }

    final parts = trimmed.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid decimal amount: $value');
    }
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final fraction = parts.length == 2 ? parts[1] : '';
    if (!_digits.hasMatch(whole) ||
        (fraction.isNotEmpty && !_digits.hasMatch(fraction))) {
      throw FormatException('Invalid decimal amount: $value');
    }
    if (fraction.length > decimals) {
      throw FormatException(
        'Amount has ${fraction.length} decimals, token supports $decimals',
      );
    }

    final combined = '$whole${fraction.padRight(decimals, '0')}'.replaceFirst(
      RegExp(r'^0+'),
      '',
    );
    return combined.isEmpty ? '0' : combined;
  }

  /// Formats a smallest-unit integer amount into a human decimal string.
  static String formatSmallestUnit(
    String value,
    int decimals, {
    int? maxFractionDigits,
    bool trimTrailingZeros = true,
  }) {
    if (decimals < 0) {
      throw ArgumentError.value(decimals, 'decimals', 'Must be non-negative');
    }
    if (!_digits.hasMatch(value)) {
      throw FormatException('Invalid smallest-unit amount: $value');
    }
    final amount = BigInt.parse(value);
    if (decimals == 0) return amount.toString();

    final base = BigInt.from(10).pow(decimals);
    final whole = amount ~/ base;
    var fraction = (amount % base).toString().padLeft(decimals, '0');
    if (maxFractionDigits != null && maxFractionDigits < fraction.length) {
      fraction = fraction.substring(0, maxFractionDigits);
    }
    if (trimTrailingZeros) {
      fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    }
    return fraction.isEmpty ? whole.toString() : '$whole.$fraction';
  }

  static final _digits = RegExp(r'^[0-9]+$');
}

/// Cached catalog of assets supported by the 1Click API.
class OneClickAssetCatalog {
  OneClickAssetCatalog({
    required OneClickClient client,
    this.ttl = const Duration(minutes: 5),
  }) : _client = client;

  final OneClickClient _client;

  /// How long [load] can reuse a token list before refreshing.
  final Duration ttl;

  List<OneClickToken>? _tokens;
  DateTime? _loadedAt;

  /// Loads supported tokens, using a TTL cache unless [refresh] is true.
  Future<List<OneClickToken>> load({bool refresh = false}) async {
    final now = DateTime.now().toUtc();
    final tokens = _tokens;
    final loadedAt = _loadedAt;
    if (!refresh &&
        tokens != null &&
        loadedAt != null &&
        now.difference(loadedAt) < ttl) {
      return tokens;
    }
    final fresh = List<OneClickToken>.unmodifiable(await _client.tokens());
    _tokens = fresh;
    _loadedAt = now;
    return fresh;
  }

  /// Finds a token by exact `assetId`, or returns null.
  Future<OneClickToken?> findByAssetId(
    String assetId, {
    bool refresh = false,
  }) async {
    for (final token in await load(refresh: refresh)) {
      if (token.assetId == assetId) return token;
    }
    return null;
  }

  /// Requires a token by exact `assetId`.
  Future<OneClickToken> requireByAssetId(
    String assetId, {
    bool refresh = false,
  }) async {
    final token = await findByAssetId(assetId, refresh: refresh);
    if (token == null) {
      throw StateError('1Click token not found: $assetId');
    }
    return token;
  }

  /// Searches by symbol, chain, contract, or asset id.
  Future<List<OneClickToken>> search({
    String? query,
    String? blockchain,
    String? symbol,
    bool refresh = false,
  }) async {
    final q = query?.toLowerCase();
    final chain = blockchain?.toLowerCase();
    final ticker = symbol?.toLowerCase();
    return [
      for (final token in await load(refresh: refresh))
        if ((q == null ||
                token.assetId.toLowerCase().contains(q) ||
                token.symbol.toLowerCase().contains(q) ||
                (token.contractAddress?.toLowerCase().contains(q) ?? false)) &&
            (chain == null || token.blockchain.toLowerCase() == chain) &&
            (ticker == null || token.symbol.toLowerCase() == ticker))
          token,
    ];
  }

  /// Clears cached supported tokens.
  void clear() {
    _tokens = null;
    _loadedAt = null;
  }
}
