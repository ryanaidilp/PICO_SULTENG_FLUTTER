import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:asset_generator/src/models/asset_generator_config.dart';
import 'package:asset_generator/src/models/discovered_asset.dart';
import 'package:asset_generator/src/services/asset_scanner_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// Command to generate type-safe asset enums.
class GenerateCommand() extends Command<int> {
  /// Creates a new [GenerateCommand].
  this {
    argParser
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Preview generated files without writing.',
        negatable: false,
      )
      ..addOption(
        'package',
        abbr: 'p',
        help:
            'Path to the asset package. Auto-discovered by scanning the '
            'workspace for an asset_generator.yaml when omitted.',
      )
      ..addOption(
        'prefix',
        help: 'Prefix for generated class names.',
        defaultsTo: 'App',
      );
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate type-safe asset enum files.';

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;
    final packageArg = argResults!['package'] as String?;
    final prefix = argResults!['prefix'] as String;
    final logger = CliLogger();

    try {
      final rootPath = MonorepoFinder.requireRoot();
      final packagePath = packageArg ?? _discoverAssetPackage(rootPath);

      if (packagePath == null) {
        logger.error(
          'No asset package found. Add asset_generator.yaml to your asset '
          'package, or pass --package <path> explicitly.',
        );
        return 1;
      }

      final fullPackagePath = p.join(rootPath, packagePath);

      // Load config from asset_generator.yaml or use defaults.
      final config =
          AssetGeneratorConfig.load(fullPackagePath) ??
          AssetGeneratorConfig(
            packagePath: fullPackagePath,
            assetsPath: p.join(fullPackagePath, 'assets'),
            outputPath: p.join(fullPackagePath, 'lib', 'src', 'generated'),
            prefix: prefix,
            packageName: p.basename(fullPackagePath),
          );

      final scanner = AssetScannerService(
        config: config,
        onWarning: logger.warning,
      );
      final groups = scanner.scan();

      if (groups.isEmpty) {
        logger.info('No assets found in ${config.assetsPath}');
        return 0;
      }

      logger.info(
        'Found ${groups.length} asset group(s) with '
        '${groups.fold(0, (sum, g) => sum + g.assets.length)} assets',
      );

      // Files exported by the top-level `generated.dart` barrel. Icons are
      // nested under `icons/` and aggregated by their own `icons/icons.dart`
      // barrel first; every other category stays flat at the output root.
      final topLevelExports = <String>[];
      final iconBarrelFiles = <String>[];

      for (final group in groups) {
        final content = scanner.generateEnumFile(group);

        final File outputFile;
        if (group.category == AssetCategory.icon && group.subcategory != null) {
          final fileName = '${_slug(group.subcategory!)}_icons.dart';
          outputFile = File(p.join(config.outputPath, 'icons', fileName));
          iconBarrelFiles.add(fileName);
        } else {
          final fileName = '${_slug(group.name)}.dart';
          outputFile = File(p.join(config.outputPath, fileName));
          topLevelExports.add(fileName);
        }

        await _writeOrPreview(
          outputFile: outputFile,
          content: content,
          dryRun: dryRun,
          rootPath: rootPath,
          logger: logger,
        );
      }

      if (iconBarrelFiles.isNotEmpty) {
        final barrelContent = scanner.generateIconsBarrel(iconBarrelFiles);
        final barrelFile = File(
          p.join(config.outputPath, 'icons', 'icons.dart'),
        );
        await _writeOrPreview(
          outputFile: barrelFile,
          content: barrelContent,
          dryRun: dryRun,
          rootPath: rootPath,
          logger: logger,
        );
        topLevelExports.add(p.join('icons', 'icons.dart'));
      }

      if (topLevelExports.isNotEmpty) {
        final generatedContent = scanner.generateTopLevelBarrel(
          // Barrel exports are always forward-slash paths regardless of
          // platform, since they are Dart import/export URIs, not file
          // system paths.
          topLevelExports.map((path) => path.replaceAll(r'\', '/')).toList(),
        );
        final generatedFile = File(p.join(config.outputPath, 'generated.dart'));
        await _writeOrPreview(
          outputFile: generatedFile,
          content: generatedContent,
          dryRun: dryRun,
          rootPath: rootPath,
          logger: logger,
        );
      }

      if (!dryRun) {
        await _formatOutput(config.outputPath, logger);
      }

      return 0;
    } on Exception catch (e) {
      logger.error('Failed to generate assets: $e');
      return 1;
    }
  }

  String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '_');

  Future<void> _writeOrPreview({
    required File outputFile,
    required String content,
    required bool dryRun,
    required String rootPath,
    required CliLogger logger,
  }) async {
    if (dryRun) {
      logger.info('[dry-run] Would generate: ${outputFile.path}');
      logger.verbose_(content);
      return;
    }

    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(content);
    logger.success('Generated: ${p.relative(outputFile.path, from: rootPath)}');
  }

  /// Best-effort `dart format` pass over the generated output so files
  /// match the formatting of the hand-written reference implementation.
  /// Failures are logged as warnings — a missing/unformatted `dart`
  /// executable should never fail generation itself.
  Future<void> _formatOutput(String outputPath, CliLogger logger) async {
    try {
      final result = await Process.run('dart', ['format', outputPath]);
      if (result.exitCode != 0) {
        logger.warning('dart format reported issues: ${result.stderr}');
      }
    } on ProcessException catch (e) {
      logger.warning('Could not run dart format: $e');
    }
  }

  /// Locates the asset package in the workspace.
  ///
  /// Resolution order:
  /// 1. Package containing `asset_generator.yaml` (explicit marker).
  /// 2. Package whose name ends in `_asset` (naming convention).
  ///
  /// Returns the path relative to [rootPath], or null if neither match.
  String? _discoverAssetPackage(String rootPath) {
    final packages = PackageScanner.scan(rootPath);

    for (final pkg in packages) {
      final configFile = File(p.join(pkg.path, 'asset_generator.yaml'));
      if (configFile.existsSync()) {
        return p.relative(pkg.path, from: rootPath);
      }
    }

    for (final pkg in packages) {
      if (pkg.name.endsWith('_asset')) {
        return p.relative(pkg.path, from: rootPath);
      }
    }

    return null;
  }
}
