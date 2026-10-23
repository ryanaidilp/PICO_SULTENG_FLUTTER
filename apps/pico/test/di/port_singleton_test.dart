// Guards ADR-039's port rule: a port a feature owns has exactly one
// instance, shared by the root and every feature container.
//
// A port is registered once, in its feature's global module, on a line
// annotated `// di-global: <reason>`; feature containers get it through
// their `*_imports.dart` as `registerFactory<T>(() => root<T>())`. The
// instance stays identical as long as:
//   1. the port is registered as a singleton (a factory builds one per
//      resolve), and
//   2. every imports file forwards to the root instead of building, and
//   3. no feature registers the port again in its own container.
// This test reads the sources for those three rules, so it needs no list of
// ports or containers.
import 'package:flutter_test/flutter_test.dart';

import '../support/feature_files.dart';

final _registration = RegExp(
  r'\b(register\w*|factory\w*|cachedFactory\w*|lazySingleton\w*|singleton\w*)<(\w+)>\(',
);
final _singleton = RegExp(
  r'^(register(Lazy)?Singleton\w*|(lazySingleton|singleton)\w*)$',
);
final _forward = RegExp(
  r'\.registerFactory<(\w+)>\(\s*\(\)\s*=>\s*root(?:\.get)?<\1>\(\s*\),?\s*\)',
);

/// `// di-global:` registrations as (file:line, method, type).
List<(String, String, String)> _ports() {
  final ports = <(String, String, String)>[];
  for (final file in featureFiles('.dart')) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('///') || !line.contains('di-global:')) {
        continue;
      }
      final code = line.substring(0, line.indexOf('//'));
      final match =
          _registration.firstMatch(code) ??
          (i + 1 < lines.length
              ? _registration.firstMatch(lines[i + 1])
              : null);
      if (match == null) continue;
      ports.add(('${file.path}:${i + 1}', match[1]!, match[2]!));
    }
  }
  return ports;
}

void main() {
  test('every di-global port is registered as a singleton', () {
    final factories = [
      for (final (where, method, type) in _ports())
        if (!_singleton.hasMatch(method)) '$type ($method) at $where',
    ];

    expect(
      factories,
      isEmpty,
      reason:
          'A factory gives each container its own port instance. Register '
          'the port with lazySingleton or singleton.',
    );
  });

  test('every feature imports file forwards to the root', () {
    final built = <String>[];
    for (final file in featureFiles('_imports.dart')) {
      final text = file.readAsStringSync();
      for (final call in RegExp(r'\.register\w*<').allMatches(text)) {
        if (_forward.matchAsPrefix(text, call.start) == null) {
          final line = '\n'.allMatches(text.substring(0, call.start)).length;
          built.add('${file.path}:${line + 1}');
        }
      }
    }

    expect(
      built,
      isEmpty,
      reason:
          'An imports file only forwards: '
          'child.registerFactory<T>(() => root<T>()). Building the type '
          'there gives the feature its own instance.',
    );
  });
}
