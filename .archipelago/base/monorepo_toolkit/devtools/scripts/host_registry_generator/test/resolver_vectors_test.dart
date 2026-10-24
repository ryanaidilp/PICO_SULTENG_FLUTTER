import 'dart:convert';
import 'dart:io';

import 'package:host_registry_generator/host_registry_generator.dart';
import 'package:test/test.dart';

/// Runs the resolver against `fixtures/resolver_vectors.json`. The same file
/// is checked in beside `bricks/shared_hooks`' copy of the resolver, whose
/// test runs the identical vectors — a byte-identical fixture plus both
/// passing keeps the two resolver copies from drifting apart.
void main() {
  final vectors = jsonDecode(
    File('test/fixtures/resolver_vectors.json').readAsStringSync(),
  ) as List<dynamic>;

  for (final raw in vectors) {
    final vector = raw as Map<String, dynamic>;
    test('resolver vector: ${vector['name']}', () {
      final manifests = [
        for (final pkg in vector['packages'] as List<dynamic>)
          PackageManifest(
            packageName: (pkg as Map<String, dynamic>)['name'] as String,
            diModules: [
              for (final m in pkg['modules'] as List<dynamic>)
                DiModuleDeclaration(
                  className: (m as Map<String, dynamic>)['class'] as String,
                  packageName: pkg['name'] as String,
                  dependsOn: [
                    for (final d in (m['depends_on'] as List<dynamic>? ?? []))
                      d as String,
                  ],
                ),
            ],
          ),
      ];

      final error = vector['error'] as String?;
      if (error == null) {
        expect(DiModuleResolver.resolve(manifests).order.map((m) => m.id), [
          for (final id in vector['order'] as List<dynamic>) id as String,
        ]);
        return;
      }
      expect(
        () => DiModuleResolver.resolve(manifests),
        throwsA(switch (error) {
          'cycle' => isA<DiModuleCycleException>(),
          'unknown' => isA<DiModuleUnknownDependencyException>(),
          'duplicate' => isA<DiModuleDuplicateException>(),
          'cross_duplicate' => isA<DiModuleCrossPackageDuplicateException>(),
          _ => throw ArgumentError('unknown error vector: $error'),
        }),
      );
    });
  }
}
