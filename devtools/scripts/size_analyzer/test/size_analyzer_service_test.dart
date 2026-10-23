import 'dart:io';

import 'package:size_analyzer/size_analyzer.dart';
import 'package:test/test.dart';

void main() {
  group('SizeAnalyzerService.parseJson', () {
    test(
      'parses flutter analyze-size JSON and aggregates by top-level package',
      () {
        const json = '''
{
  "type": "dart",
  "root": {
    "n": "Root",
    "value": 5000000,
    "children": [
      {"n": "package:flutter/src/widgets/framework.dart", "value": 2000000, "children": []},
      {"n": "package:flutter/src/rendering/box.dart", "value": 500000, "children": []},
      {"n": "package:get_it/get_it.dart", "value": 300000, "children": []}
    ]
  }
}
''';
        final nodes = SizeAnalyzerService.parseJson(json);
        // package:flutter/* should be aggregated into package:flutter
        final flutter = nodes.firstWhere((n) => n.name == 'package:flutter');
        expect(flutter.bytes, 2500000);
        final getIt = nodes.firstWhere((n) => n.name == 'package:get_it');
        expect(getIt.bytes, 300000);
        // sorted descending by bytes
        expect(nodes.first.bytes, greaterThanOrEqualTo(nodes.last.bytes));
      },
    );

    test('returns empty list for JSON with no root', () {
      const json = '{"type": "dart"}';
      expect(SizeAnalyzerService.parseJson(json), isEmpty);
    });

    test('returns empty list for root with no children', () {
      const json = '{"root": {"n": "Root", "value": 0}}';
      expect(SizeAnalyzerService.parseJson(json), isEmpty);
    });
  });

  group('SizeAnalyzerService.diffBaseline', () {
    test('detects size increase', () {
      final current = [const SizeNode(name: 'package:flutter', bytes: 2100000)];
      final baseline = [
        const SizeNode(name: 'package:flutter', bytes: 2000000),
      ];
      final diff = SizeAnalyzerService.diffBaseline(
        current: current,
        baseline: baseline,
      );
      expect(diff.length, 1);
      expect(diff.first.name, 'package:flutter');
      expect(diff.first.delta, 100000);
      expect(diff.first.isIncrease, isTrue);
    });

    test('detects new package', () {
      final current = [const SizeNode(name: 'package:new_pkg', bytes: 300000)];
      final diff = SizeAnalyzerService.diffBaseline(
        current: current,
        baseline: [],
      );
      expect(diff.first.isNew, isTrue);
      expect(diff.first.delta, 300000);
    });

    test('detects removed package', () {
      final current = [const SizeNode(name: 'package:flutter', bytes: 2000000)];
      final baseline = [
        const SizeNode(name: 'package:flutter', bytes: 2000000),
        const SizeNode(name: 'package:old_pkg', bytes: 100000),
      ];
      final diff = SizeAnalyzerService.diffBaseline(
        current: current,
        baseline: baseline,
      );
      expect(diff.length, 1);
      expect(diff.first.name, 'package:old_pkg');
      expect(diff.first.delta, -100000);
      expect(diff.first.isIncrease, isFalse);
    });

    test('returns empty when no changes', () {
      final current = [const SizeNode(name: 'package:flutter', bytes: 2000000)];
      final baseline = [
        const SizeNode(name: 'package:flutter', bytes: 2000000),
      ];
      final diff = SizeAnalyzerService.diffBaseline(
        current: current,
        baseline: baseline,
      );
      expect(diff, isEmpty);
    });
  });

  group('SizeAnalyzerService baseline round-trip', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('size_analyzer_test_');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('saves and loads baseline correctly', () {
      final service = SizeAnalyzerService(rootPath: tempDir.path);
      final nodes = [
        const SizeNode(name: 'package:flutter', bytes: 2000000),
        const SizeNode(name: 'package:get_it', bytes: 300000),
      ];
      service.updateBaseline(nodes, 'size_baseline/android.json');
      final loaded = service.loadBaseline('size_baseline/android.json');
      expect(loaded.length, 2);
      expect(
        loaded.map((n) => n.name),
        containsAll(['package:flutter', 'package:get_it']),
      );
    });

    test('loadBaseline returns empty when file does not exist', () {
      final service = SizeAnalyzerService(rootPath: tempDir.path);
      expect(service.loadBaseline('size_baseline/android.json'), isEmpty);
    });
  });

  group('SizeNode formatting', () {
    test('formats bytes below 1MB as KB', () {
      const node = SizeNode(name: 'pkg', bytes: 512 * 1024);
      expect(node.formatted, '512.0 KB');
    });

    test('formats bytes above 1MB as MB', () {
      const node = SizeNode(name: 'pkg', bytes: 2 * 1024 * 1024);
      expect(node.formatted, '2.00 MB');
    });
  });

  group('SizeNodeDiff formatting', () {
    test('formats positive delta with + prefix', () {
      const diff = SizeNodeDiff(name: 'pkg', bytes: 600000, delta: 100000);
      expect(diff.deltaFormatted, startsWith('+'));
    });

    test('formats negative delta with - prefix', () {
      const diff = SizeNodeDiff(name: 'pkg', bytes: 400000, delta: -100000);
      expect(diff.deltaFormatted, startsWith('-'));
    });
  });
}
