// OpenAPI -> Dart generator for the NEAR JSON-RPC client.
//
// Reads tool/openapi.json (a snapshot of nearcore's
// chain/jsonrpc/openapi/openapi.json) and emits:
//   lib/src/models.g.dart  — typed models for every schema
//   lib/src/client.g.dart  — one typed method per RPC path
//
// Run: dart run tool/generate.dart
//
// The CI auto-sync workflow re-fetches the spec, runs this, and opens a PR
// if the generated output changed.
import 'dart:convert';
import 'dart:io';

void main() {
  final specFile = File('tool/openapi.json');
  if (!specFile.existsSync()) {
    stderr.writeln('tool/openapi.json not found — run from package root.');
    exit(1);
  }
  final spec = jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
  final gen = Generator(spec);
  gen.run();
  File('lib/src/models.g.dart').writeAsStringSync(gen.models.toString());
  File('lib/src/client.g.dart').writeAsStringSync(gen.client.toString());
  stdout.writeln(
    'Generated ${gen.typeCount} types and ${gen.methodCount} RPC methods '
    '(nearcore OpenAPI ${gen.version}).',
  );
}

/// Converts an OpenAPI schema name into a valid Dart class identifier.
String dartName(String raw) {
  var n = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  if (n.isEmpty) return 'Dynamic';
  if (RegExp(r'^[0-9]').hasMatch(n)) n = 'N$n';
  return n;
}

/// Converts a JSON property name into a safe Dart field identifier.
String dartField(String raw) {
  var n = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  if (RegExp(r'^[0-9]').hasMatch(n)) n = 'n$n';
  const reserved = {
    'in',
    'is',
    'as',
    'if',
    'for',
    'new',
    'class',
    'enum',
    'void',
    'final',
    'const',
    'this',
    'super',
    'return',
    'switch',
    'default',
    'true',
    'false',
    'null',
    'var',
    'else',
    'while',
    'do',
    'try',
    'catch',
  };
  if (reserved.contains(n)) n = '\$$n';
  return n;
}

class Generator {
  Generator(this.spec)
    : schemas = (spec['components']?['schemas'] as Map<String, dynamic>?) ?? {},
      paths = (spec['paths'] as Map<String, dynamic>?) ?? {},
      version = '${spec['info']?['version'] ?? 'unknown'}';

  final Map<String, dynamic> spec;
  final Map<String, dynamic> schemas;
  final Map<String, dynamic> paths;
  final String version;

  final StringBuffer models = StringBuffer();
  final StringBuffer client = StringBuffer();
  int typeCount = 0;
  int methodCount = 0;

  void run() {
    _emitModelsHeader();
    final names = schemas.keys.toList()..sort();
    for (final name in names) {
      _emitSchema(name, schemas[name] as Map<String, dynamic>);
    }
    _emitClient();
  }

  // ---- type resolution -----------------------------------------------------

  /// Unwraps the `allOf: [ { $ref } ]` pattern (a single ref decorated with a
  /// description) to the referenced node, so such fields get a real type.
  Map<String, dynamic> _unwrap(Map<String, dynamic> node) {
    final all = node['allOf'];
    if (all is List && all.length == 1 && all.first is Map<String, dynamic>) {
      final only = all.first as Map<String, dynamic>;
      if (only.containsKey(r'$ref')) return only;
    }
    return node;
  }

  /// The Dart type for a schema node (inline or $ref). Does not append `?`.
  String typeOf(Map<String, dynamic> rawNode) {
    final node = _unwrap(rawNode);
    if (node.containsKey(r'$ref')) {
      return dartName((node[r'$ref'] as String).split('/').last);
    }
    if (node.containsKey('allOf') ||
        node.containsKey('oneOf') ||
        node.containsKey('anyOf')) {
      // Inline composition without a name — keep the raw decoded JSON as
      // `dynamic` (null-safe even nested in List/Map element positions).
      return 'dynamic';
    }
    final type = node['type'];
    switch (type) {
      case 'string':
        return 'String';
      case 'integer':
        return 'int';
      case 'number':
        return 'double';
      case 'boolean':
        return 'bool';
      case 'array':
        final items = node['items'];
        if (items is Map<String, dynamic>) {
          return 'List<${typeOf(items)}>';
        }
        return 'List<Object?>';
      case 'object':
        final ap = node['additionalProperties'];
        if (ap is Map<String, dynamic>) {
          return 'Map<String, ${typeOf(ap)}>';
        }
        return 'Map<String, dynamic>';
      default:
        return 'dynamic';
    }
  }

  /// How to decode `expr` (a `dynamic` JSON value) into [dartType].
  String decodeExpr(String expr, Map<String, dynamic> rawNode) {
    final node = _unwrap(rawNode);
    if (node.containsKey(r'$ref')) {
      final t = dartName((node[r'$ref'] as String).split('/').last);
      final kind = _kindOf(node[r'$ref'] as String);
      if (kind == 'object' || kind == 'enum' || kind == 'union') {
        return '$t.fromJson($expr)';
      }
      return '$expr as $t'; // alias to a primitive/list/map
    }
    final type = node['type'];
    switch (type) {
      case 'string':
        return '$expr as String';
      case 'integer':
        return '($expr as num).toInt()';
      case 'number':
        return '($expr as num).toDouble()';
      case 'boolean':
        return '$expr as bool';
      case 'array':
        final items = node['items'];
        if (items is Map<String, dynamic>) {
          // Type the map so the result matches the field's List<ElemType>
          // (the element decode may be a `dynamic` passthrough).
          return '($expr as List).map<${typeOf(items)}>'
              '((e) => ${decodeExpr('e', items)}).toList()';
        }
        return '($expr as List)';
      case 'object':
        final ap = node['additionalProperties'];
        if (ap is Map<String, dynamic>) {
          return '($expr as Map).map((k, v) => MapEntry(k as String, '
              '${decodeExpr('v', ap)}))';
        }
        return '($expr as Map).cast<String, dynamic>()';
      default:
        return expr; // dynamic / composed
    }
  }

  /// How to encode a Dart field `expr` of [node] back to JSON.
  String encodeExpr(String expr, Map<String, dynamic> rawNode, bool nullable) {
    final node = _unwrap(rawNode);
    final q = nullable ? '?' : '';
    if (node.containsKey(r'$ref')) {
      final kind = _kindOf(node[r'$ref'] as String);
      if (kind == 'object' || kind == 'enum' || kind == 'union') {
        return '$expr$q.toJson()';
      }
      return expr;
    }
    final type = node['type'];
    if (type == 'array') {
      final items = node['items'];
      if (items is Map<String, dynamic> &&
          (items.containsKey(r'$ref') &&
              _kindOf(items[r'$ref'] as String) != 'alias')) {
        return '$expr$q.map((e) => ${encodeExpr('e', items, false)}).toList()';
      }
      return expr;
    }
    if (type == 'object') {
      final ap = node['additionalProperties'];
      if (ap is Map<String, dynamic> && ap.containsKey(r'$ref')) {
        return '$expr$q.map((k, v) => MapEntry(k, ${encodeExpr('v', ap, false)}))';
      }
    }
    return expr;
  }

  /// The emitted kind for a named schema — must mirror [_emitSchema] exactly
  /// so decode/encode/param logic matches what was generated.
  String _kindOf(String ref) => schemaKind(ref.split('/').last);

  String schemaKind(String name) {
    final s = schemas[name] as Map<String, dynamic>?;
    if (s == null) return 'alias';
    if (s.containsKey('enum') && s['type'] == 'string') return 'enum';
    if (s.containsKey('oneOf') || s.containsKey('anyOf')) return 'union';
    if (s.containsKey('allOf')) return 'object';
    if (s['type'] == 'object' && s.containsKey('properties')) return 'object';
    if (s['type'] == 'object' && !s.containsKey('additionalProperties')) {
      return 'object';
    }
    return 'alias';
  }

  // ---- schema emission -----------------------------------------------------

  void _emitSchema(String name, Map<String, dynamic> s) {
    final cls = dartName(name);
    if (s.containsKey('enum') && s['type'] == 'string') {
      _emitEnum(cls, s);
    } else if (s.containsKey('oneOf') || s.containsKey('anyOf')) {
      _emitUnion(cls, name);
    } else if (s.containsKey('allOf')) {
      _emitObject(cls, _mergeAllOf(s), name);
    } else if (s['type'] == 'object' && s.containsKey('properties')) {
      _emitObject(cls, s, name);
    } else if (s['type'] == 'object' &&
        !s.containsKey('additionalProperties')) {
      _emitObject(cls, {'properties': <String, dynamic>{}}, name);
    } else {
      // alias to primitive / list / map / ref
      final t = typeOf(s);
      models.writeln('/// Alias for `$name`.');
      models.writeln('typedef $cls = $t;');
      models.writeln();
      typeCount++;
    }
  }

  Map<String, dynamic> _mergeAllOf(Map<String, dynamic> s) {
    final props = <String, dynamic>{};
    final required = <String>[];
    for (final part in (s['allOf'] as List)) {
      final m = part is Map<String, dynamic> && part.containsKey(r'$ref')
          ? schemas[(part[r'$ref'] as String).split('/').last]
                as Map<String, dynamic>
          : part as Map<String, dynamic>;
      final mp = m['properties'];
      if (mp is Map<String, dynamic>) props.addAll(mp);
      final mr = m['required'];
      if (mr is List) required.addAll(mr.cast<String>());
    }
    return {'properties': props, 'required': required};
  }

  void _emitEnum(String cls, Map<String, dynamic> s) {
    final values = (s['enum'] as List).cast<String>();
    final entries = <String, String>{}; // dart identifier -> json value
    for (final v in values) {
      var id = dartField(v.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_'));
      if (id.isEmpty || RegExp(r'^[0-9]').hasMatch(id)) id = 'v$id';
      // de-dupe
      var uid = id;
      var i = 1;
      while (entries.containsKey(uid)) {
        uid = '$id$i';
        i++;
      }
      entries[uid] = v;
    }
    models.writeln('/// Generated from `${s['title'] ?? cls}`.');
    models.writeln('enum $cls {');
    for (final e in entries.entries) {
      models.writeln("  ${e.key}(r'${e.value}'),");
    }
    models.writeln('  ;');
    models.writeln();
    models.writeln('  const $cls(this.wireValue);');
    models.writeln('  final String wireValue;');
    models.writeln();
    models.writeln('  static $cls fromJson(dynamic json) =>');
    models.writeln('      values.firstWhere((e) => e.wireValue == json);');
    models.writeln('  String toJson() => wireValue;');
    models.writeln('}');
    models.writeln();
    typeCount++;
  }

  /// oneOf/anyOf — represented as a holder of the raw decoded JSON. This keeps
  /// every variant accessible and the generated code total; callers read
  /// `.json` (NEAR's Rust-tagged unions, e.g. {"Variant": {...}}).
  void _emitUnion(String cls, String name) {
    models.writeln('/// Union type generated from `$name`.');
    models.writeln('///');
    models.writeln('/// Holds the raw decoded JSON; inspect [json] for the');
    models.writeln('/// active variant (NEAR serializes these tagged).');
    models.writeln('class $cls {');
    models.writeln('  const $cls(this.json);');
    models.writeln('  factory $cls.fromJson(dynamic json) => $cls(json);');
    models.writeln('  final dynamic json;');
    models.writeln('  dynamic toJson() => json;');
    models.writeln('}');
    models.writeln();
    typeCount++;
  }

  void _emitObject(String cls, Map<String, dynamic> s, String name) {
    final props = (s['properties'] as Map<String, dynamic>?) ?? {};
    final fields = <_Field>[];
    for (final entry in props.entries) {
      final node = entry.value as Map<String, dynamic>;
      // Every field is nullable: nearcore's spec marks many fields `required`
      // that are null/absent in real responses, and the spec evolves. A
      // generated client must decode defensively rather than crash.
      const nullable = true;
      fields.add(
        _Field(
          jsonKey: entry.key,
          dart: dartField(entry.key),
          type: typeOf(node),
          node: node,
          nullable: nullable,
        ),
      );
    }

    models.writeln('/// Generated from `$name`.');
    models.writeln('class $cls {');
    // constructor (Dart forbids an empty `{}` parameter list)
    if (fields.isEmpty) {
      models.writeln('  const $cls();');
    } else {
      models.writeln('  const $cls({');
      for (final f in fields) {
        models.writeln('    ${f.nullable ? '' : 'required '}this.${f.dart},');
      }
      models.writeln('  });');
    }
    models.writeln();
    // fromJson
    models.writeln(
      '  factory $cls.fromJson(Map<String, dynamic> json) => $cls(',
    );
    for (final f in fields) {
      final raw = "json[r'${f.jsonKey}']";
      if (f.nullable) {
        models.writeln(
          '    ${f.dart}: $raw == null ? null : ${decodeExpr(raw, f.node)},',
        );
      } else {
        models.writeln('    ${f.dart}: ${decodeExpr(raw, f.node)},');
      }
    }
    models.writeln('  );');
    models.writeln();
    // fields
    for (final f in fields) {
      models.writeln('  final ${f.type}${f.nullable ? '?' : ''} ${f.dart};');
    }
    models.writeln();
    // toJson
    models.writeln('  Map<String, dynamic> toJson() => {');
    for (final f in fields) {
      final enc = encodeExpr(f.dart, f.node, f.nullable);
      if (f.nullable) {
        models.writeln("    if (${f.dart} != null) r'${f.jsonKey}': $enc,");
      } else {
        models.writeln("    r'${f.jsonKey}': $enc,");
      }
    }
    models.writeln('  };');
    models.writeln('}');
    models.writeln();
    typeCount++;
  }

  // ---- client emission -----------------------------------------------------

  void _emitClient() {
    _emitClientHeader();
    final methods = <String>[];
    final entries = paths.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final op =
          (entry.value as Map<String, dynamic>)['post']
              as Map<String, dynamic>?;
      if (op == null) continue;
      final opId =
          op['operationId'] as String? ?? entry.key.replaceAll('/', '');
      methods.add(_emitMethod(opId, op));
    }
    client.writeln(methods.join('\n'));
    client.writeln('}');
  }

  String _emitMethod(String opId, Map<String, dynamic> op) {
    final method = dartField(_camel(opId));
    // Resolve the params type and how to pass it.
    String paramSig = '';
    String paramsArg = 'null';
    final reqRef =
        op['requestBody']?['content']?['application/json']?['schema']?[r'$ref']
            as String?;
    if (reqRef != null) {
      final reqSchema =
          schemas[reqRef.split('/').last] as Map<String, dynamic>?;
      final paramsNode =
          reqSchema?['properties']?['params'] as Map<String, dynamic>?;
      final paramsRequired = ((reqSchema?['required'] as List?) ?? const [])
          .contains('params');
      if (paramsNode != null && paramsNode.containsKey(r'$ref')) {
        final refName = (paramsNode[r'$ref'] as String).split('/').last;
        final t = dartName(refName);
        final kind = schemaKind(refName);
        if (kind == 'object' || kind == 'union' || kind == 'enum') {
          if (paramsRequired) {
            paramSig = '$t params';
            paramsArg = 'params.toJson()';
          } else {
            paramSig = '[$t? params]';
            paramsArg = 'params?.toJson()';
          }
        } else {
          // alias: dynamic / primitive / list / map — no toJson().
          final underlying = typeOf(schemas[refName] as Map<String, dynamic>);
          if (underlying == 'dynamic') {
            paramSig = '[dynamic params]';
          } else {
            paramSig = paramsRequired
                ? '$underlying params'
                : '[$underlying? params]';
          }
          paramsArg = 'params';
        }
      }
    }
    // result type
    String resultType = 'dynamic';
    String resultDecode = 'result';
    final respRef =
        op['responses']?['200']?['content']?['application/json']?['schema']?[r'$ref']
            as String?;
    if (respRef != null) {
      final respSchema =
          schemas[respRef.split('/').last] as Map<String, dynamic>?;
      final oneOf = respSchema?['oneOf'] as List?;
      if (oneOf != null) {
        for (final variant in oneOf) {
          final rNode =
              (variant as Map<String, dynamic>)['properties']?['result']
                  as Map<String, dynamic>?;
          if (rNode != null && rNode.containsKey(r'$ref')) {
            resultType = dartName((rNode[r'$ref'] as String).split('/').last);
            resultDecode = decodeExpr('result', rNode);
            break;
          }
        }
      }
    }
    methodCount++;
    final b = StringBuffer();
    b.writeln('  /// Calls the `$opId` JSON-RPC method.');
    b.writeln('  Future<$resultType> $method($paramSig) async {');
    b.writeln("    final result = await _call(r'$opId', $paramsArg);");
    b.writeln('    return $resultDecode;');
    b.writeln('  }');
    return b.toString();
  }

  String _camel(String s) {
    final parts = s.split(RegExp(r'[_/]')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return s;
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  // ---- headers -------------------------------------------------------------

  void _emitModelsHeader() {
    models.writeln('// GENERATED CODE — DO NOT EDIT BY HAND.');
    models.writeln('// Source: nearcore OpenAPI $version');
    models.writeln('// Regenerate: dart run tool/generate.dart');
    models.writeln('//');
    models.writeln(
      '// ignore_for_file: non_constant_identifier_names, '
      'constant_identifier_names, prefer_const_constructors',
    );
    models.writeln();
  }

  void _emitClientHeader() {
    client.writeln('// GENERATED CODE — DO NOT EDIT BY HAND.');
    client.writeln('// Source: nearcore OpenAPI $version');
    client.writeln('// Regenerate: dart run tool/generate.dart');
    client.writeln('//');
    client.writeln('// ignore_for_file: non_constant_identifier_names');
    client.writeln();
    client.writeln("import 'dart:convert';");
    client.writeln("import 'package:http/http.dart' as http;");
    client.writeln("import 'models.g.dart';");
    client.writeln();
    client.writeln('/// Thrown when the node returns a JSON-RPC error.');
    client.writeln('class NearRpcException implements Exception {');
    client.writeln('  NearRpcException(this.error);');
    client.writeln('  final Object? error;');
    client.writeln('  @override');
    client.writeln("  String toString() => 'NearRpcException(\$error)';");
    client.writeln('}');
    client.writeln();
    client.writeln(
      '/// Typed NEAR JSON-RPC client generated from the nearcore '
      'OpenAPI spec.',
    );
    client.writeln('class NearJsonRpcClient {');
    client.writeln(
      '  NearJsonRpcClient({required this.endpoint, '
      'http.Client? httpClient})',
    );
    client.writeln('      : _http = httpClient ?? http.Client();');
    client.writeln();
    client.writeln(
      '  /// nearcore OpenAPI spec version this client was '
      'generated from.',
    );
    client.writeln("  static const specVersion = '$version';");
    client.writeln('  final String endpoint;');
    client.writeln('  final http.Client _http;');
    client.writeln('  var _id = 0;');
    client.writeln();
    client.writeln(
      '  Future<dynamic> _call(String method, dynamic params) '
      'async {',
    );
    client.writeln('    final body = jsonEncode({');
    client.writeln("      'jsonrpc': '2.0',");
    client.writeln("      'id': 'near-dart-\${_id++}',");
    client.writeln("      'method': method,");
    client.writeln("      if (params != null) 'params': params,");
    client.writeln('    });');
    client.writeln('    final res = await _http.post(Uri.parse(endpoint),');
    client.writeln(
      "        headers: {'Content-Type': 'application/json'}, "
      'body: body);',
    );
    client.writeln(
      '    final json = jsonDecode(res.body) '
      'as Map<String, dynamic>;',
    );
    client.writeln("    if (json['error'] != null) {");
    client.writeln("      throw NearRpcException(json['error']);");
    client.writeln('    }');
    client.writeln("    return json['result'];");
    client.writeln('  }');
    client.writeln();
    client.writeln('  /// Closes the underlying HTTP client.');
    client.writeln('  void close() => _http.close();');
    client.writeln();
  }
}

class _Field {
  _Field({
    required this.jsonKey,
    required this.dart,
    required this.type,
    required this.node,
    required this.nullable,
  });
  final String jsonKey;
  final String dart;
  final String type;
  final Map<String, dynamic> node;
  final bool nullable;
}
