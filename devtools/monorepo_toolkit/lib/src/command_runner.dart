import 'dart:io';

import 'package:affected/affected.dart' hide RunCommand;
import 'package:app_scaffold/app_scaffold.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:asset_generator/asset_generator.dart';
import 'package:asset_optimizer/asset_optimizer.dart';
import 'package:build_prepare/build_prepare.dart';
import 'package:changelog_generator/changelog_generator.dart';
import 'package:coverage_manager/coverage_manager.dart' hide RunCommand;
import 'package:dependency_graph/dependency_graph.dart';
import 'package:dependency_manager/dependency_manager.dart';
import 'package:detect_new_library/detect_new_library.dart';
import 'package:env_sync/env_sync.dart';
import 'package:flavor_manager/flavor_manager.dart';
// `GenerateCommand` collides with the same-named class already exported by
// `flavor_manager` (unused ambiguity until referenced) — import qualified
// to disambiguate.
import 'package:host_registry_generator/host_registry_generator.dart'
    as host_registry_generator;
import 'package:permission_guard/permission_guard.dart';
import 'package:prepare/prepare.dart';
import 'package:run_app/run_app.dart';
import 'package:shared_scripts/shared_scripts.dart';
import 'package:size_analyzer/size_analyzer.dart';
import 'package:size_guard/size_guard.dart';
import 'package:ui_kit_generator/ui_kit_generator.dart';
import 'package:workspace_setup/workspace_setup.dart';

const _executableName = 'monorepo_toolkit';
const _description =
    'A CLI tool for managing Flutter/Dart monorepo workspaces.';
const _version = '0.1.0';

/// A [CommandRunner] for the monorepo toolkit CLI.
///
/// Registers all available commands from script packages and provides
/// global flags for verbose output and version display.
class MonorepoToolkitCommandRunner({CliLogger? logger})
    extends CommandRunner<int> {
  /// Creates a new [MonorepoToolkitCommandRunner].
  this : super(_executableName, _description) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        negatable: false,
        help: 'Noisy logging, including all shell commands executed.',
      );

    // --- Free Commands ---
    addCommand(AppCommand(logger: _logger));
    addCommand(BuildPrepareCommand());
    addCommand(DepsCommand(logger: _logger));
    addCommand(EnvCommand(logger: _logger));
    addCommand(FlavorCommand(logger: _logger));
    addCommand(host_registry_generator.GenerateCommand(logger: _logger));
    addCommand(GraphCommand());
    addCommand(PrepareCommand(logger: _logger));
    addCommand(RunCommand(logger: _logger));
    addCommand(WorkspaceCommand(logger: _logger));

    // --- Installed Free Commands ---
    // Injected by ui_kit_generator brick
    addCommand(ThemeVariantCommand());
    addCommand(UiKitCommand());
    addCommand(ChangelogCommand());
    addCommand(AssetGenCommand());
    // Injected by installed free-tier devtool bricks (e.g. ui_kit_generator)

    // --- Pro Commands ---
    // Injected by affected brick
    addCommand(AffectedCommand());
    addCommand(AssetsCommand());
    addCommand(PermissionGuardCommand());
    addCommand(SizeAnalyzerCommand());
    addCommand(DetectNewLibraryCommand());
    addCommand(SizeGuardCommand());
    addCommand(CoverageCommand());

    // --- Enterprise Commands ---
    // Injected by monorepo_toolkit_enterprise brick
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      return await runCommand(topLevelResults) ?? 0;
    } on FormatException catch (e, stackTrace) {
      _logger.error(e.message);
      _logger.error('$stackTrace');
      _logger.info('');
      _logger.info(usage);
      return 64;
    } on UsageException catch (e) {
      _logger.error(e.message);
      _logger.info('');
      _logger.info(e.usage);
      return 64;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      stdout.writeln(_version);
      return 0;
    }

    return await super.runCommand(topLevelResults);
  }
}
