import 'package:dependencies/di.dart';

/// The app-root types the Pengaturan feature uses.
///
/// The only file in this feature that reads [root]. The feature's container
/// never falls back to the root, so a type that is not forwarded here (and
/// not registered by the feature itself) cannot be resolved. Each line
/// forwards one type; the root keeps ownership of the instance:
/// ```dart
/// child.registerFactory<HttpClient>(() => root<HttpClient>());
/// ```
void importPengaturanGlobals(GetIt child, GetIt root) {
  // TODO(user): Forward each root type this feature needs.
}
