import 'package:detect_new_library/detect_new_library.dart';
import 'package:test/test.dart';

void main() {
  group('DetectNewLibraryService.extractDepsFromContent', () {
    test('extracts direct and dev dependencies', () {
      const content = '''
dependencies:
  flutter:
    sdk: flutter
  get_it: ^8.0.0
  dio: ^5.0.0

dev_dependencies:
  test: ^1.25.0
  build_runner: ^2.4.0
''';
      final deps = DetectNewLibraryService.extractDepsFromContent(content);
      expect(deps, containsAll(['get_it', 'dio', 'test', 'build_runner']));
      expect(deps, isNot(contains('flutter'))); // sdk dep excluded
    });

    test('returns empty set for pubspec with no dependencies', () {
      const content = 'name: my_package\n';
      final deps = DetectNewLibraryService.extractDepsFromContent(content);
      expect(deps, isEmpty);
    });

    test('excludes path dependencies (they are packages, not external libs)', () {
      const content = '''
dependencies:
  my_local_pkg:
    path: ../my_local_pkg
  dio: ^5.0.0
''';
      // Path deps ARE included (they could be new local packages worth noting).
      // Only SDK constraints are excluded.
      final deps = DetectNewLibraryService.extractDepsFromContent(content);
      expect(deps, contains('dio'));
      expect(deps, contains('my_local_pkg'));
    });
  });

  group('DetectNewLibraryService.findNewDeps', () {
    test('detects added dependency', () {
      const base = '''
dependencies:
  get_it: ^8.0.0
''';
      const current = '''
dependencies:
  get_it: ^8.0.0
  dio: ^5.0.0
''';
      final newDeps = DetectNewLibraryService.findNewDeps(
        baseContent: base,
        currentContent: current,
      );
      expect(newDeps, equals({'dio'}));
    });

    test('does not flag existing dependencies as new', () {
      const base = '''
dependencies:
  get_it: ^8.0.0
  dio: ^5.0.0
''';
      const current = '''
dependencies:
  get_it: ^8.0.0
  dio: ^5.0.0
''';
      final newDeps = DetectNewLibraryService.findNewDeps(
        baseContent: base,
        currentContent: current,
      );
      expect(newDeps, isEmpty);
    });

    test('does not flag removed dependency', () {
      const base = '''
dependencies:
  get_it: ^8.0.0
  dio: ^5.0.0
''';
      const current = '''
dependencies:
  get_it: ^8.0.0
''';
      final newDeps = DetectNewLibraryService.findNewDeps(
        baseContent: base,
        currentContent: current,
      );
      expect(newDeps, isEmpty);
    });

    test('detects new dev dependency', () {
      const base = 'name: pkg\n';
      const current = '''
dev_dependencies:
  mocktail: ^1.0.0
''';
      final newDeps = DetectNewLibraryService.findNewDeps(
        baseContent: base,
        currentContent: current,
      );
      expect(newDeps, equals({'mocktail'}));
    });
  });

  group('NewLibraryConfig.fromYaml', () {
    test('uses defaults when yaml is empty', () {
      final config = NewLibraryConfig.fromYaml({});
      expect(config.failOnNew, isFalse);
      expect(config.ignoredPackages, containsAll(['flutter', 'dart']));
    });

    test('reads fail_on_new from yaml', () {
      final config = NewLibraryConfig.fromYaml({'fail_on_new': true});
      expect(config.failOnNew, isTrue);
    });

    test('reads base_branch from yaml', () {
      final config = NewLibraryConfig.fromYaml({'base_branch': 'main'});
      expect(config.baseBranch, 'main');
    });

    test('reads ignored_packages from yaml', () {
      final config = NewLibraryConfig.fromYaml({
        'ignored_packages': ['flutter', 'dart', 'my_internal_pkg'],
      });
      expect(
        config.ignoredPackages,
        containsAll(['flutter', 'dart', 'my_internal_pkg']),
      );
    });
  });
}
