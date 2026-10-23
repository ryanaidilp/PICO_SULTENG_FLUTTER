/// Maps configuration file names to their default paths relative to
/// the workspace root.
///
/// When a command needs a config file, it looks up the default path here.
/// Users can override these paths via command-line `--config` options.
class ConfigRegistry._() {
  /// Default configuration files and their paths.
  ///
  /// Free-tier configs are included by default.
  /// Pro and Enterprise configs are added by their respective bricks.
  static const Map<String, String> defaults = {
    'build_prepare': 'build_prepare.yaml',
    'flavors': 'flavors.yaml',
    'dependency_graph': 'dependency_graph.yaml',
    // --- Pro Configs ---
    // Added by monorepo_toolkit_pro brick:
    // 'coverage': 'coverage.yaml',
    // 'size_guard': 'size_guard.yaml',
    // 'asset_optimizer': 'asset_optimizer.yaml',
    // 'asset_generator': 'asset_generator.yaml',
    // 'affected': 'affected.yaml',
    // --- Enterprise Configs ---
    // Added by monorepo_toolkit_enterprise brick:
    // 'ui_kit': 'ui_kit.yaml',
  };

  /// Returns the default config path for a given tool name.
  ///
  /// Returns `null` if no default is registered.
  static String? defaultPathFor(String toolName) => defaults[toolName];
}
