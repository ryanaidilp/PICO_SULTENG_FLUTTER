import 'package:host_registry_generator/host_registry_generator.dart';
import 'package:test/test.dart';

/// Shorthand for building a synthetic [PackageManifest] in tests.
PackageManifest _pkg(String name, List<TestPrerequisiteDeclaration> prereqs) =>
    PackageManifest(packageName: name, testPrerequisites: prereqs);

/// Shorthand for building a synthetic [TestPrerequisiteDeclaration].
TestPrerequisiteDeclaration _prereq(
  String packageName,
  String className, {
  List<String> dependsOn = const [],
}) => TestPrerequisiteDeclaration(
  className: className,
  packageName: packageName,
  reason: 'reason',
  dependsOn: dependsOn,
);

List<String> _classes(List<TestPrerequisiteDeclaration> order) =>
    order.map((p) => p.className).toList();

void main() {
  group('TestPrerequisiteResolver.resolve — no constraints', () {
    test('falls back to alphabetical package name order', () {
      final order = TestPrerequisiteResolver.resolve([
        _pkg('zeta', [_prereq('zeta', 'Zeta')]),
        _pkg('alpha', [_prereq('alpha', 'Alpha')]),
        _pkg('mu', [_prereq('mu', 'Mu')]),
      ]);

      expect(_classes(order), ['Alpha', 'Mu', 'Zeta']);
    });

    test('within one package, preserves declaration order', () {
      final order = TestPrerequisiteResolver.resolve([
        _pkg('alpha', [_prereq('alpha', 'Two'), _prereq('alpha', 'One')]),
      ]);

      expect(_classes(order), ['Two', 'One']);
    });

    test('packages with no test_prerequisites contribute nothing', () {
      final order = TestPrerequisiteResolver.resolve([
        _pkg('alpha', [_prereq('alpha', 'Alpha')]),
        _pkg('leaf_package', const []),
      ]);

      expect(_classes(order), ['Alpha']);
    });
  });

  group('TestPrerequisiteResolver.resolve — depends_on', () {
    test('respects a simple A -> B -> C chain against alphabetical order', () {
      final order = TestPrerequisiteResolver.resolve([
        _pkg('a', [
          _prereq('a', 'A', dependsOn: ['b']),
        ]),
        _pkg('b', [
          _prereq('b', 'B', dependsOn: ['c']),
        ]),
        _pkg('c', [_prereq('c', 'C')]),
      ]);

      expect(_classes(order), ['C', 'B', 'A']);
    });

    test('a depends_on naming an absent package is ignored', () {
      final order = TestPrerequisiteResolver.resolve([
        _pkg('a', [
          _prereq('a', 'A', dependsOn: ['not_installed']),
        ]),
      ]);

      expect(_classes(order), ['A']);
    });

    test('resolving twice with shuffled input yields the same order', () {
      final manifests = [
        _pkg('d', [
          _prereq('d', 'D', dependsOn: ['b', 'c']),
        ]),
        _pkg('b', [
          _prereq('b', 'B', dependsOn: ['a']),
        ]),
        _pkg('c', [
          _prereq('c', 'C', dependsOn: ['a']),
        ]),
        _pkg('a', [_prereq('a', 'A')]),
      ];

      final first = TestPrerequisiteResolver.resolve(manifests);
      final second = TestPrerequisiteResolver.resolve(
        manifests.reversed.toList(),
      );

      expect(_classes(first), ['A', 'B', 'C', 'D']);
      expect(_classes(second), _classes(first));
    });
  });

  group('TestPrerequisiteResolver.resolve — cycle detection', () {
    test('throws DiModuleCycleException naming the cycle', () {
      expect(
        () => TestPrerequisiteResolver.resolve([
          _pkg('a', [
            _prereq('a', 'A', dependsOn: ['b']),
          ]),
          _pkg('b', [
            _prereq('b', 'B', dependsOn: ['a']),
          ]),
        ]),
        throwsA(
          isA<DiModuleCycleException>().having(
            (e) => e.message,
            'message',
            allOf(contains('a::A'), contains('b::B')),
          ),
        ),
      );
    });
  });
}
