import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Map<Object?, Object?> workflow(String path) {
  final value = loadYaml(File(path).readAsStringSync());
  return (value as YamlMap).cast<Object?, Object?>();
}

void main() {
  test('Windows uses the VS 2022 compatibility runner', () {
    final jobs = workflow('.github/workflows/test.yml')['jobs'] as YamlMap;
    final windows = jobs['example-windows'] as YamlMap;
    expect(windows['runs-on'], 'windows-2022');
  });

  test('OpenAPI sync has least privileges required to open a PR', () {
    final jobs =
        workflow('.github/workflows/sync-openapi.yml')['jobs'] as YamlMap;
    final sync = jobs['sync'] as YamlMap;
    expect((sync['permissions'] as YamlMap).cast<String, Object?>(), {
      'contents': 'write',
      'pull-requests': 'write',
    });
  });

  test('aggregate gate requires every claimed platform', () {
    final jobs = workflow('.github/workflows/test.yml')['jobs'] as YamlMap;
    final gate = jobs['all-tests-pass'] as YamlMap;
    final needs = (gate['needs'] as YamlList).cast<String>();
    expect(
      needs,
      containsAll(<String>[
        'example-android',
        'example-ios',
        'example-web',
        'example-linux',
        'example-macos',
        'example-windows',
      ]),
    );
  });
}
