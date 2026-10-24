/// Generates the DI module import/registration lists in an app's
/// `injector.dart` from `archipelago:` manifests declared in each
/// package's `pubspec.yaml`.
library;

export 'src/commands/generate_command.dart';
export 'src/commands/host_registry_command.dart';
export 'src/commands/test_harness_command.dart';
export 'src/models/di_module_declaration.dart';
export 'src/models/di_module_resolution.dart';
export 'src/models/di_resolution_exception.dart';
export 'src/models/host_registry_app_not_found_exception.dart';
export 'src/models/host_registry_generation_result.dart';
export 'src/models/host_registry_target_not_found_exception.dart';
export 'src/models/manifest_parse_exception.dart';
export 'src/models/module_scope.dart';
export 'src/models/package_manifest.dart';
export 'src/models/resolved_module.dart';
export 'src/models/test_harness_generation_result.dart';
export 'src/models/test_prerequisite_declaration.dart';
export 'src/services/di_module_resolver.dart';
export 'src/services/host_registry_service.dart';
export 'src/services/test_prerequisite_resolver.dart';
