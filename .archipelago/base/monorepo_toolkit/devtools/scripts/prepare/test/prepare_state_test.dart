import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:prepare/src/prepare_runner.dart';
import 'package:prepare/src/prepare_state.dart';
import 'package:test/test.dart';

void main() {
  group('PrepareState', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('prepare_state_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('load returns null when no state file exists', () {
      expect(PrepareState.load(tempDir.path), isNull);
    });

    test('save then load round-trips flavor and mode', () {
      PrepareState.save(
        tempDir.path,
        const PrepareState(flavor: 'development', mode: 'debug'),
      );

      final loaded = PrepareState.load(tempDir.path);
      expect(loaded, isNotNull);
      expect(loaded!.flavor, equals('development'));
      expect(loaded.mode, equals('debug'));
    });

    test('save writes the expected JSON shape', () {
      PrepareState.save(
        tempDir.path,
        const PrepareState(flavor: 'production', mode: 'release'),
      );

      final file = File(p.join(tempDir.path, PrepareState.stateFileName));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json, equals({'flavor': 'production', 'mode': 'release'}));
    });

    test('load returns null on malformed JSON', () {
      File(p.join(tempDir.path, PrepareState.stateFileName))
          .writeAsStringSync('{ not json');
      expect(PrepareState.load(tempDir.path), isNull);
    });

    test('matches is true only for same flavor and mode', () {
      const state = PrepareState(flavor: 'development', mode: 'debug');
      expect(state.matches('development', 'debug'), isTrue);
      expect(state.matches('development', 'release'), isFalse);
      expect(state.matches('staging', 'debug'), isFalse);
    });
  });

  group('prepareWorkspace idempotency', () {
    late Directory rootDir;
    late Directory appConfigDir;

    setUp(() {
      rootDir = Directory.systemTemp.createTempSync('prepare_idem_test_');
      appConfigDir = Directory(p.join(rootDir.path, 'shared', 'app_config'))
        ..createSync(recursive: true);
      File(p.join(appConfigDir.path, '.env.development'))
          .writeAsStringSync('API_BASE_URL=https://dev.example.com\n');
    });

    tearDown(() {
      if (rootDir.existsSync()) rootDir.deleteSync(recursive: true);
    });

    test(
      'state hit short-circuits without running envied regen or build-prepare',
      () async {
        // Seed matching state and the .env artifact so the cache is "warm".
        File(p.join(appConfigDir.path, '.env'))
            .writeAsStringSync('API_BASE_URL=https://dev.example.com\n');
        PrepareState.save(
          rootDir.path,
          const PrepareState(flavor: 'development', mode: 'debug'),
        );

        final outcome = await prepareWorkspace(
          rootPath: rootDir.path,
          flavor: 'development',
          mode: 'debug',
        );

        // If it had not short-circuited it would have spawned build_runner /
        // build-prepare (no build_prepare.yaml here) — instead it skips.
        expect(outcome, equals(PrepareOutcome.skipped));
      },
    );

    test('throws PrepareException when .env.<flavor> is missing', () async {
      expect(
        () => prepareWorkspace(
          rootPath: rootDir.path,
          flavor: 'nonexistent',
          mode: 'debug',
        ),
        throwsA(isA<PrepareException>()),
      );
    });
  });
}
