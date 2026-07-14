import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Map<Object?, Object?> workflow(String path) {
  final value = loadYaml(File(path).readAsStringSync());
  return (value as YamlMap).cast<Object?, Object?>();
}

List<String> jobCommands(String workflowPath, String jobName) {
  final jobs = workflow(workflowPath)['jobs'] as YamlMap;
  final job = jobs[jobName] as YamlMap;
  final steps = job['steps'] as YamlList;
  return steps
      .whereType<YamlMap>()
      .map((step) => step['run'])
      .whereType<String>()
      .toList();
}

List<String> jobActions(String workflowPath, String jobName) {
  final jobs = workflow(workflowPath)['jobs'] as YamlMap;
  final job = jobs[jobName] as YamlMap;
  final steps = job['steps'] as YamlList;
  return steps
      .whereType<YamlMap>()
      .map((step) => step['uses'])
      .whereType<String>()
      .toList();
}

void expectWalletCheckoutOverride(List<String> commands) {
  final overrideIndex = commands.indexWhere(
    (command) =>
        command.contains("'dependency_overrides:'") &&
        command.contains("'  near_dart:'") &&
        command.contains("'    path: ../..'") &&
        command.contains('> pubspec_overrides.yaml'),
  );
  final pubGetIndex = commands.indexOf('flutter pub get');
  final analyzeIndex = commands.indexOf('flutter analyze lib test');
  final testIndex = commands.indexOf('flutter test');

  expect(overrideIndex, isNonNegative);
  expect(overrideIndex, lessThan(pubGetIndex));
  expect(pubGetIndex, lessThan(analyzeIndex));
  expect(analyzeIndex, lessThan(testIndex));
  expect(
    commands.where(
      (command) =>
          command.contains('pub publish') &&
          !command.contains('pub publish --dry-run'),
    ),
    isEmpty,
  );
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

  test('root release check runs non-integration tests', () {
    final jobs =
        workflow('.github/workflows/release-check.yml')['jobs'] as YamlMap;
    final nearDart = jobs['near-dart'] as YamlMap;
    final steps = nearDart['steps'] as YamlList;

    expect(
      steps.whereType<YamlMap>().any(
        (step) => step['run'] == 'dart test --exclude-tags integration',
      ),
      isTrue,
    );
  });

  test('wallet CI resolves near_dart from the checkout before validation', () {
    final commands = jobCommands(
      '.github/workflows/test.yml',
      'wallet-connect',
    );

    expectWalletCheckoutOverride(commands);
    expect(
      commands.where((command) => command.contains('pub publish')),
      isEmpty,
    );
  });

  test('Chrome CI covers signing and wallet redirect restoration', () {
    final rootCommands = jobCommands(
      '.github/workflows/test.yml',
      'platform-chrome',
    );
    expect(
      rootCommands,
      contains(
        'dart test --platform chrome test/platform/web_test.dart '
        'test/platform/web_signing_test.dart --reporter=expanded',
      ),
    );
    expect(
      rootCommands,
      contains(
        'dart test --platform chrome --compiler dart2wasm '
        'test/platform/web_test.dart test/platform/web_signing_test.dart '
        '--reporter=expanded',
      ),
    );

    final walletCommands = jobCommands(
      '.github/workflows/test.yml',
      'wallet-connect',
    );
    expect(
      walletCommands,
      contains('flutter test --platform chrome test/web_wallet_flow_test.dart'),
    );
    expect(
      walletCommands,
      contains(
        'flutter test --platform chrome --wasm '
        'test/web_wallet_flow_test.dart',
      ),
    );

    final webBuildCommands = jobCommands(
      '.github/workflows/test.yml',
      'example-web',
    );
    expect(
      webBuildCommands,
      contains('flutter build web --wasm --no-tree-shake-icons'),
    );

    const pinnedChromeAction =
        'browser-actions/setup-chrome@'
        '2e1d749697dd1612b833dba4a722266286fbefcd';
    expect(
      jobActions('.github/workflows/test.yml', 'platform-chrome'),
      contains(pinnedChromeAction),
    );
    expect(
      jobActions('.github/workflows/test.yml', 'wallet-connect'),
      contains(pinnedChromeAction),
    );
  });

  test(
    'wallet release validation uses checkout resolution without publishing',
    () {
      final commands = jobCommands(
        '.github/workflows/release-check.yml',
        'near-wallet-connect',
      );

      expectWalletCheckoutOverride(commands);
      final publishIndex = commands.indexOf('dart pub publish --dry-run');
      expect(publishIndex, greaterThan(commands.indexOf('flutter test')));
      expect(
        commands.where((command) => command == 'dart pub publish --dry-run'),
        hasLength(1),
      );
    },
  );
}
