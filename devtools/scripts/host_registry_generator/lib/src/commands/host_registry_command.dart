import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:host_registry_generator/src/models/di_resolution_exception.dart';
import 'package:host_registry_generator/src/models/host_registry_app_not_found_exception.dart';
import 'package:host_registry_generator/src/models/host_registry_generation_result.dart';
import 'package:host_registry_generator/src/models/host_registry_target_not_found_exception.dart';
import 'package:host_registry_generator/src/models/manifest_parse_exception.dart';
import 'package:host_registry_generator/src/services/host_registry_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Regenerates the `feature_imports` / `feature_modules_before` /
/// `feature_modules_after` marker regions of an app's `injector.dart` from
/// every workspace package's `archipelago: di_modules` manifest.
///
/// Usage:
/// ```bash
/// monorepo_toolkit generate host-registry
/// monorepo_toolkit generate host-registry --app template_app
/// monorepo_toolkit generate host-registry --target apps/my_app/lib/di/injector.dart
/// ```
class HostRegistryCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [HostRegistryCommand].
  this {
    argParser
      ..addOption(
        'app',
        abbr: 'a',
        help:
            'The app to update (directory name inside apps/). Auto-detected '
            'when the workspace has exactly one app with an injector.dart.',
      )
      ..addOption(
        'root',
        help:
            'Override the workspace root (defaults to the detected '
            'monorepo root).',
      )
      ..addOption(
        'target',
        abbr: 't',
        help:
            'Explicit path to the injector.dart file to update. Overrides '
            '--app/--root auto-detection.',
      )
      ..addFlag(
        'prune',
        negatable: false,
        help:
            'Drop ExternalModule entries no manifest declares. By default '
            'they are kept and reported.',
      )
      ..addFlag(
        'check',
        help:
            'Report drift without writing. Exits 1 if injector.dart would '
            'change.',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'host-registry';

  @override
  String get description =>
      "Regenerate an app's injector.dart DI registration marker regions "
      'from each package archipelago: di_modules manifest.';

  @override
  Future<int> run() async {
    final rootPath =
        (argResults?['root'] as String?) ?? MonorepoFinder.findRoot();
    if (rootPath == null) {
      _logger.error(
        'Could not find monorepo root. Make sure you are inside a Dart '
        'workspace with a pubspec.yaml containing a workspace: key, or '
        'pass --root explicitly.',
      );
      return 1;
    }

    final String targetPath;
    final explicitTarget = argResults?['target'] as String?;
    if (explicitTarget != null) {
      targetPath = explicitTarget;
    } else {
      final resolved = resolveHostInjectorPath(
        rootPath: rootPath,
        appArg: argResults?['app'] as String?,
        logger: _logger,
      );
      if (resolved == null) return 1;
      targetPath = resolved;
    }

    final service = HostRegistryService(rootPath: rootPath);
    final checkOnly = argResults?['check'] as bool? ?? false;

    try {
      final result = service.generate(
        targetInjectorPath: targetPath,
        write: !checkOnly,
        prune: argResults?['prune'] as bool? ?? false,
      );
      if (result.preservedModules.isNotEmpty) {
        _logger.warning(
          'Kept ${result.preservedModules.length} module(s) no manifest in '
          "this app's dependencies declares: "
          '${result.preservedModules.join(', ')}. They now sit after the '
          'generated entries. Declare them under '
          'archipelago: di_modules, or pass --prune to drop them. If you ran '
          'build-prepare release, run build-prepare debug first.',
        );
      }
      _printSummary(result, checkOnly: checkOnly);
      if (checkOnly && result.changed) {
        _logger.error(
          '${result.targetPath} is out of date. Run '
          '`dart run monorepo_toolkit generate host-registry` to fix.',
        );
        return 1;
      }
      return 0;
    } on ManifestParseException catch (e) {
      _logger.error(e.toString());
      return 1;
    } on DiResolutionException catch (e) {
      // Covers DiModuleCycleException, DiModuleUnknownDependencyException,
      // and DiModuleDuplicateException — all carry an actionable message.
      _logger.error(e.message);
      return 1;
    } on HostRegistryTargetNotFoundException catch (e) {
      _logger.error(e.toString());
      return 1;
    } on HostRegistryAppNotFoundException catch (e) {
      _logger.error(e.toString());
      return 1;
    } on MarkerImbalanceException catch (e) {
      _logger.error(e.message);
      return 1;
    }
  }

  void _printSummary(
    HostRegistryGenerationResult result, {
    required bool checkOnly,
  }) {
    _logger.info('Scanned ${result.packagesScanned} package(s).');
    _logger.info(
      '${result.packagesWithModules} package(s) declared '
      '${result.totalModulesDeclared} di_module(s).',
    );

    final order = result.resolution.order;
    if (order.isEmpty) {
      _logger.info('Resolved order: (none)');
    } else {
      _logger.info('Resolved order:');
      for (final module in order) {
        _logger.info('  - ${module.id} (${module.scope.name})');
      }
    }

    _logger.success(
      result.changed
          ? '${checkOnly ? 'Would update' : 'Updated'} ${result.targetPath}.'
          : '${result.targetPath} already up to date (no change).',
    );
  }
}

/// Resolves `apps/<name>/lib/di/injector.dart` from `--app`, or
/// auto-detects it when exactly one app in the workspace has an
/// `injector.dart`. Prints an actionable error (and returns `null`) when
/// the app is ambiguous or not found.
String? resolveHostInjectorPath({
  required String rootPath,
  required CliLogger logger,
  String? appArg,
}) {
  final appsDir = Directory(p.join(rootPath, 'apps'));

  if (appArg != null) {
    final path = p.join(rootPath, 'apps', appArg, 'lib', 'di', 'injector.dart');
    if (!File(path).existsSync()) {
      logger.error('No injector.dart found for app "$appArg" at $path.');
      return null;
    }
    return path;
  }

  if (!appsDir.existsSync()) {
    logger.error('No apps/ directory found under $rootPath.');
    return null;
  }

  final found = <String, String>{};
  for (final entity in appsDir.listSync()) {
    if (entity is! Directory) continue;
    final candidate = p.join(entity.path, 'lib', 'di', 'injector.dart');
    if (File(candidate).existsSync()) {
      found[p.basename(entity.path)] = candidate;
    }
  }

  if (found.isEmpty) {
    logger.error('No app under apps/ has a lib/di/injector.dart.');
    return null;
  }
  if (found.length > 1) {
    final names = found.keys.toList()..sort();
    logger.error(
      'Multiple apps found (${names.join(', ')}). Pass --app to select '
      'one.',
    );
    return null;
  }

  return found.values.single;
}
