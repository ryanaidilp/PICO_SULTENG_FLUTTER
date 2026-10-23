import 'dart:io';

import 'package:app_scaffold/src/feature_manifest_check.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  void writeSdk(String source) =>
      File('${root.path}/shared/feature_sdk/lib/src/feature_sdk_registry.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(source);

  setUp(() => root = Directory.systemTemp.createTempSync('scaffold_check_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('passes when the project has no feature_sdk', () {
    expect(featureManifestApiError(root.path), isNull);
  });

  test('passes when the registry has manifests', () {
    writeSdk('class R { List<Object> get manifests => []; }');
    expect(featureManifestApiError(root.path), isNull);
  });

  test('stops on a registry with only sdks', () {
    writeSdk('class R { List<Object> get sdks => []; }');
    expect(
      featureManifestApiError(root.path),
      contains('migrating-feature-di'),
    );
  });
}
