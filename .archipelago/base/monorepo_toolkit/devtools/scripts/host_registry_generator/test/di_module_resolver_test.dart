import 'package:host_registry_generator/host_registry_generator.dart';
import 'package:test/test.dart';

/// Shorthand for building a synthetic [PackageManifest] in tests.
PackageManifest _pkg(String name, List<DiModuleDeclaration> modules) =>
    PackageManifest(packageName: name, diModules: modules);

/// Shorthand for building a synthetic [DiModuleDeclaration].
DiModuleDeclaration _mod(
  String packageName,
  String className, {
  List<String> dependsOn = const [],
  ModuleScope scope = ModuleScope.before,
}) => DiModuleDeclaration(
  className: className,
  packageName: packageName,
  dependsOn: dependsOn,
  scope: scope,
);

void main() {
  group('DiModuleResolver.resolve — no constraints', () {
    test('falls back to alphabetical package name order', () {
      final result = DiModuleResolver.resolve([
        _pkg('zeta', [_mod('zeta', 'ZetaModule')]),
        _pkg('alpha', [_mod('alpha', 'AlphaModule')]),
        _pkg('mu', [_mod('mu', 'MuModule')]),
      ]);

      expect(result.order.map((m) => m.packageName).toList(), [
        'alpha',
        'mu',
        'zeta',
      ]);
    });

    test('within one package, preserves declaration order', () {
      final result = DiModuleResolver.resolve([
        _pkg('alpha', [
          _mod('alpha', 'AlphaModuleOne'),
          _mod('alpha', 'AlphaModuleTwo'),
          _mod('alpha', 'AlphaModuleThree'),
        ]),
      ]);

      expect(result.order.map((m) => m.className).toList(), [
        'AlphaModuleOne',
        'AlphaModuleTwo',
        'AlphaModuleThree',
      ]);
    });

    test('packages with no archipelago manifest contribute nothing', () {
      final result = DiModuleResolver.resolve([
        _pkg('alpha', [_mod('alpha', 'AlphaModule')]),
        _pkg('leaf_package', const []),
      ]);

      expect(result.order, hasLength(1));
      expect(result.order.single.packageName, 'alpha');
    });
  });

  group('DiModuleResolver.resolve — linear chain', () {
    test('respects a simple A -> B -> C depends_on chain', () {
      final result = DiModuleResolver.resolve([
        _pkg('c', [
          _mod('c', 'CModule', dependsOn: ['b']),
        ]),
        _pkg('a', [_mod('a', 'AModule')]),
        _pkg('b', [
          _mod('b', 'BModule', dependsOn: ['a']),
        ]),
      ]);

      expect(result.order.map((m) => m.packageName).toList(), ['a', 'b', 'c']);
    });
  });

  group('DiModuleResolver.resolve — diamond dependency', () {
    test(
      'D depends on B and C, both depend on A — resolves deterministically',
      () {
        final result = DiModuleResolver.resolve([
          _pkg('d', [
            _mod('d', 'DModule', dependsOn: ['b', 'c']),
          ]),
          _pkg('c', [
            _mod('c', 'CModule', dependsOn: ['a']),
          ]),
          _pkg('b', [
            _mod('b', 'BModule', dependsOn: ['a']),
          ]),
          _pkg('a', [_mod('a', 'AModule')]),
        ]);

        // A must precede B and C; both must precede D. B before C because
        // 'b' < 'c' alphabetically (the tiebreak) once both are ready.
        expect(result.order.map((m) => m.packageName).toList(), [
          'a',
          'b',
          'c',
          'd',
        ]);
      },
    );

    test('resolving twice with the same input yields the same order', () {
      List<PackageManifest> graph() => [
        _pkg('d', [
          _mod('d', 'DModule', dependsOn: ['b', 'c']),
        ]),
        _pkg('c', [
          _mod('c', 'CModule', dependsOn: ['a']),
        ]),
        _pkg('b', [
          _mod('b', 'BModule', dependsOn: ['a']),
        ]),
        _pkg('a', [_mod('a', 'AModule')]),
      ];

      final first = DiModuleResolver.resolve(graph());
      final second = DiModuleResolver.resolve(graph());

      expect(
        first.order.map((m) => m.id).toList(),
        second.order.map((m) => m.id).toList(),
      );
    });
  });

  group('DiModuleResolver.resolve — scope splitting', () {
    test('splits before/after while preserving unified relative order', () {
      final result = DiModuleResolver.resolve([
        _pkg('alpha', [_mod('alpha', 'AlphaModule')]),
        _pkg('beta', [_mod('beta', 'BetaModule', scope: ModuleScope.after)]),
        _pkg('gamma', [_mod('gamma', 'GammaModule')]),
      ]);

      expect(result.beforeModules.map((m) => m.packageName).toList(), [
        'alpha',
        'gamma',
      ]);
      expect(result.afterModules.map((m) => m.packageName).toList(), ['beta']);
    });
  });

  group('DiModuleResolver.resolve — cycle detection', () {
    test('throws a named 2-node cycle error', () {
      expect(
        () => DiModuleResolver.resolve([
          _pkg('a', [
            _mod('a', 'AModule', dependsOn: ['b']),
          ]),
          _pkg('b', [
            _mod('b', 'BModule', dependsOn: ['a']),
          ]),
        ]),
        throwsA(
          isA<DiModuleCycleException>()
              .having((e) => e.cycle, 'cycle', contains('a::AModule'))
              .having((e) => e.cycle, 'cycle', contains('b::BModule'))
              .having(
                (e) => e.message,
                'message',
                allOf(contains('a::AModule'), contains('b::BModule')),
              ),
        ),
      );
    });

    test('throws a named 3-node cycle error', () {
      expect(
        () => DiModuleResolver.resolve([
          _pkg('a', [
            _mod('a', 'AModule', dependsOn: ['c']),
          ]),
          _pkg('b', [
            _mod('b', 'BModule', dependsOn: ['a']),
          ]),
          _pkg('c', [
            _mod('c', 'CModule', dependsOn: ['b']),
          ]),
        ]),
        throwsA(
          isA<DiModuleCycleException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('a::AModule'),
              contains('b::BModule'),
              contains('c::CModule'),
            ),
          ),
        ),
      );
    });

    test(
      'a cycle among a subset does not falsely implicate unrelated packages',
      () {
        expect(
          () => DiModuleResolver.resolve([
            _pkg('a', [
              _mod('a', 'AModule', dependsOn: ['b']),
            ]),
            _pkg('b', [
              _mod('b', 'BModule', dependsOn: ['a']),
            ]),
            _pkg('unrelated', [_mod('unrelated', 'UnrelatedModule')]),
          ]),
          throwsA(
            isA<DiModuleCycleException>().having(
              (e) => e.message,
              'message',
              isNot(contains('unrelated')),
            ),
          ),
        );
      },
    );
  });

  group('DiModuleResolver.resolve — validation', () {
    test('throws when depends_on names a package with no di_modules', () {
      expect(
        () => DiModuleResolver.resolve([
          _pkg('a', [
            _mod('a', 'AModule', dependsOn: ['ghost']),
          ]),
        ]),
        throwsA(
          isA<DiModuleUnknownDependencyException>().having(
            (e) => e.unknownPackage,
            'unknownPackage',
            'ghost',
          ),
        ),
      );
    });

    test('throws when a package declares the same class twice', () {
      expect(
        () => DiModuleResolver.resolve([
          _pkg('a', [_mod('a', 'AModule'), _mod('a', 'AModule')]),
        ]),
        throwsA(isA<DiModuleDuplicateException>()),
      );
    });

    test('throws DiModuleCrossPackageDuplicateException when two different '
        'packages declare the same class (e.g. an impl/noop pair)', () {
      expect(
        () => DiModuleResolver.resolve([
          _pkg('feature_impl', [_mod('feature_impl', 'FeatureModule')]),
          _pkg('feature_noop', [_mod('feature_noop', 'FeatureModule')]),
        ]),
        throwsA(
          isA<DiModuleCrossPackageDuplicateException>()
              .having((e) => e.className, 'className', 'FeatureModule')
              .having(
                (e) => e.message,
                'message',
                allOf(contains('feature_impl'), contains('feature_noop')),
              ),
        ),
      );
    });
  });
}
