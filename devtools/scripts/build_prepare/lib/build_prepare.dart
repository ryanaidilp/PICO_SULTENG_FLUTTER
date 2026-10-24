/// Build-time dependency swapping tool for the Archipelago workspace.
///
/// Swaps debug/release dependencies in pubspec.yaml files based on
/// a `build_prepare.yaml` configuration at the workspace root.
library;

export 'src/build_prepare_command.dart';
export 'src/build_prepare_config.dart';
export 'src/build_prepare_runner.dart';
