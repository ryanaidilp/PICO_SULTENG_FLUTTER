import 'package:host_registry_generator/host_registry_generator.dart';
import 'package:test/test.dart';

void main() {
  group('PackageManifest.parse', () {
    test('a package with no archipelago key has zero declared modules', () {
      const content = '''
name: leaf_package
version: 0.1.0
dependencies:
  meta: ^1.0.0
''';
      final manifest = PackageManifest.parse(
        packageName: 'leaf_package',
        pubspecContent: content,
      );

      expect(manifest.packageName, 'leaf_package');
      expect(manifest.diModules, isEmpty);
    });

    test('a package with archipelago but no di_modules key is also empty', () {
      const content = '''
name: leaf_package
archipelago:
  something_else: true
''';
      final manifest = PackageManifest.parse(
        packageName: 'leaf_package',
        pubspecContent: content,
      );
      expect(manifest.diModules, isEmpty);
    });

    test('parses a minimal entry, applying documented defaults', () {
      const content = '''
name: app_utilities
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
''';
      final manifest = PackageManifest.parse(
        packageName: 'app_utilities',
        pubspecContent: content,
      );

      expect(manifest.diModules, hasLength(1));
      final module = manifest.diModules.single;
      expect(module.className, 'AppUtilitiesPackageModule');
      // import defaults to package:<package_name>/<package_name>.dart
      expect(module.import, 'package:app_utilities/app_utilities.dart');
      expect(module.dependsOn, isEmpty);
      expect(module.scope, ModuleScope.before);
    });

    test('parses an explicit import override', () {
      const content = '''
name: app_utilities
archipelago:
  di_modules:
    - class: AppUtilitiesPackageModule
      import: package:app_utilities/src/di/app_utilities_module.dart
''';
      final manifest = PackageManifest.parse(
        packageName: 'app_utilities',
        pubspecContent: content,
      );
      expect(
        manifest.diModules.single.import,
        'package:app_utilities/src/di/app_utilities_module.dart',
      );
    });

    test('parses depends_on as a list of package names', () {
      const content = '''
name: auth_impl
archipelago:
  di_modules:
    - class: AuthImplGlobalModule
      depends_on: [introduction, app_utilities]
''';
      final manifest = PackageManifest.parse(
        packageName: 'auth_impl',
        pubspecContent: content,
      );
      expect(manifest.diModules.single.dependsOn, [
        'introduction',
        'app_utilities',
      ]);
    });

    test('parses scope: after', () {
      const content = '''
name: push_notification_impl
archipelago:
  di_modules:
    - class: PushNotificationGlobalModule
      scope: after
''';
      final manifest = PackageManifest.parse(
        packageName: 'push_notification_impl',
        pubspecContent: content,
      );
      expect(manifest.diModules.single.scope, ModuleScope.after);
    });

    test('parses multiple di_modules entries for one package in order', () {
      const content = '''
name: ai_chat_impl
archipelago:
  di_modules:
    - class: AiChatImplPackageModule
    - class: AiChatImplGlobalModule
      depends_on: [ai_chat_openai_impl, ai_chat_anthropic_impl]
''';
      final manifest = PackageManifest.parse(
        packageName: 'ai_chat_impl',
        pubspecContent: content,
      );
      expect(manifest.diModules, hasLength(2));
      expect(manifest.diModules[0].className, 'AiChatImplPackageModule');
      expect(manifest.diModules[1].className, 'AiChatImplGlobalModule');
    });

    test('throws ManifestParseException when class field is missing', () {
      const content = '''
name: broken
archipelago:
  di_modules:
    - depends_on: [foo]
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });

    test('throws ManifestParseException for an invalid scope value', () {
      const content = '''
name: broken
archipelago:
  di_modules:
    - class: BrokenModule
      scope: sometimes
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });
  });

  group('PackageManifest.parse test_prerequisites', () {
    test('a package with no archipelago key has zero declared '
        'prerequisites', () {
      const content = '''
name: leaf_package
version: 0.1.0
dependencies:
  meta: ^1.0.0
''';
      final manifest = PackageManifest.parse(
        packageName: 'leaf_package',
        pubspecContent: content,
      );

      expect(manifest.testPrerequisites, isEmpty);
    });

    test('a package with archipelago but no test_prerequisites key is also '
        'empty', () {
      const content = '''
name: leaf_package
archipelago:
  di_modules:
    - class: LeafPackageModule
''';
      final manifest = PackageManifest.parse(
        packageName: 'leaf_package',
        pubspecContent: content,
      );
      expect(manifest.testPrerequisites, isEmpty);
    });

    test('parses a minimal entry, applying documented defaults', () {
      const content = r'''
name: app_debugger
archipelago:
  test_prerequisites:
    - class: AppDebuggerTestPrerequisite
      reason: >-
        AppDebuggerRegisterModule's @preResolve cubits call path_provider
        getTemporaryDirectory() during $initGetIt.
''';
      final manifest = PackageManifest.parse(
        packageName: 'app_debugger',
        pubspecContent: content,
      );

      expect(manifest.testPrerequisites, hasLength(1));
      final prerequisite = manifest.testPrerequisites.single;
      expect(prerequisite.className, 'AppDebuggerTestPrerequisite');
      // import defaults to package:<package_name>/testing.dart
      expect(prerequisite.import, 'package:app_debugger/testing.dart');
      expect(
        prerequisite.reason,
        "AppDebuggerRegisterModule's @preResolve cubits call path_provider "
        r'getTemporaryDirectory() during $initGetIt.',
      );
      expect(prerequisite.dependsOn, isEmpty);
    });

    test('parses an explicit import override', () {
      const content = '''
name: app_debugger
archipelago:
  test_prerequisites:
    - class: AppDebuggerTestPrerequisite
      import: package:app_debugger/src/testing/app_debugger_test_prerequisite.dart
      reason: needs a path_provider fake.
''';
      final manifest = PackageManifest.parse(
        packageName: 'app_debugger',
        pubspecContent: content,
      );
      expect(
        manifest.testPrerequisites.single.import,
        'package:app_debugger/src/testing/app_debugger_test_prerequisite.dart',
      );
    });

    test('parses depends_on as a list of package names', () {
      const content = '''
name: monitoring_impl
archipelago:
  test_prerequisites:
    - class: MonitoringImplTestPrerequisite
      reason: needs firebase_core mocks.
      depends_on: [app_debugger, package_info_provider]
''';
      final manifest = PackageManifest.parse(
        packageName: 'monitoring_impl',
        pubspecContent: content,
      );
      expect(manifest.testPrerequisites.single.dependsOn, [
        'app_debugger',
        'package_info_provider',
      ]);
    });

    test('parses multiple test_prerequisites entries for one package in '
        'order', () {
      const content = '''
name: ai_chat_impl
archipelago:
  test_prerequisites:
    - class: AiChatOpenAiTestPrerequisite
      reason: needs a network fake.
    - class: AiChatAnthropicTestPrerequisite
      reason: needs a network fake.
''';
      final manifest = PackageManifest.parse(
        packageName: 'ai_chat_impl',
        pubspecContent: content,
      );
      expect(manifest.testPrerequisites, hasLength(2));
      expect(
        manifest.testPrerequisites[0].className,
        'AiChatOpenAiTestPrerequisite',
      );
      expect(
        manifest.testPrerequisites[1].className,
        'AiChatAnthropicTestPrerequisite',
      );
    });

    test('parses di_modules and test_prerequisites together', () {
      const content = '''
name: app_debugger
archipelago:
  di_modules:
    - class: AppDebuggerPackageModule
  test_prerequisites:
    - class: AppDebuggerTestPrerequisite
      reason: needs a path_provider fake.
''';
      final manifest = PackageManifest.parse(
        packageName: 'app_debugger',
        pubspecContent: content,
      );
      expect(manifest.diModules, hasLength(1));
      expect(manifest.testPrerequisites, hasLength(1));
    });

    test('throws ManifestParseException when class field is missing', () {
      const content = '''
name: broken
archipelago:
  test_prerequisites:
    - reason: some reason.
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });

    test('throws ManifestParseException when class field is empty', () {
      const content = '''
name: broken
archipelago:
  test_prerequisites:
    - class: ""
      reason: some reason.
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });

    test('throws ManifestParseException when reason field is missing', () {
      const content = '''
name: broken
archipelago:
  test_prerequisites:
    - class: BrokenTestPrerequisite
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(
          isA<ManifestParseException>().having(
            (e) => e.message,
            'message',
            contains('reason'),
          ),
        ),
      );
    });

    test('throws ManifestParseException when reason field is empty', () {
      const content = '''
name: broken
archipelago:
  test_prerequisites:
    - class: BrokenTestPrerequisite
      reason: ""
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });

    test('throws ManifestParseException for a non-string import value', () {
      const content = '''
name: broken
archipelago:
  test_prerequisites:
    - class: BrokenTestPrerequisite
      reason: some reason.
      import: [not, a, string]
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });

    test('throws ManifestParseException for a non-list depends_on value', () {
      const content = '''
name: broken
archipelago:
  test_prerequisites:
    - class: BrokenTestPrerequisite
      reason: some reason.
      depends_on: not_a_list
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken',
          pubspecContent: content,
        ),
        throwsA(isA<ManifestParseException>()),
      );
    });

    test('the exception names the offending package', () {
      const content = '''
name: broken_package
archipelago:
  test_prerequisites:
    - reason: some reason.
''';
      expect(
        () => PackageManifest.parse(
          packageName: 'broken_package',
          pubspecContent: content,
        ),
        throwsA(
          isA<ManifestParseException>().having(
            (e) => e.packageName,
            'packageName',
            'broken_package',
          ),
        ),
      );
    });
  });
}
