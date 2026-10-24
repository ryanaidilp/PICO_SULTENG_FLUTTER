import 'dart:io';

import 'package:path/path.dart' as p;

const _featureSdkLib = 'shared/feature_sdk/lib';

/// Why a new app cannot be scaffolded in [rootPath], or `null` when it can.
///
/// The app templates read `FeatureSDKRegistry.enabledManifests` (ADR-038). A
/// `shared/feature_sdk` from before that has only `sdks`, and the generated
/// app would not compile. Same probe as `featureManifestApiError` in the
/// brick hooks' shared_hooks, which this tool cannot import
/// (Archipelago-5h52).
String? featureManifestApiError(String rootPath) {
  final dir = Directory(p.join(rootPath, _featureSdkLib));
  if (!dir.existsSync()) return null;
  final hasManifests = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .any((f) => f.readAsStringSync().contains('get manifests'));
  if (hasManifests) return null;
  return 'The app template needs FeatureSDKRegistry.manifests in '
      '$_featureSdkLib (ADR-038), and this project has the older '
      'FeatureSDKRegistry.sdks.\n'
      'Update shared/feature_sdk first: '
      'https://archipelago.banuacoder.com/docs/guide/migrating-feature-di '
      '(step 1). Then run this command again. Nothing was changed.';
}
