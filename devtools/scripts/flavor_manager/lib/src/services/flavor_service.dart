import 'dart:io';

import 'package:flavor_manager/src/models/flavor_config.dart';
import 'package:flavor_manager/src/models/global_flavor_settings.dart';
import 'package:flavor_manager/src/services/ide_config_generator.dart';
import 'package:flavor_manager/src/services/xcode_config_mirror.dart';
import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';

/// Exception thrown when a flavor already exists.
class const FlavorExistsException(
  /// The flavor name that already exists.
  final String flavorName,
) implements Exception {
  /// Creates a new [FlavorExistsException].
  this;

  @override
  String toString() => 'Flavor "$flavorName" already exists.';
}

/// Exception thrown when a flavor is not found.
class const FlavorNotFoundException(
  /// The flavor name that was not found.
  final String flavorName,
) implements Exception {
  /// Creates a new [FlavorNotFoundException].
  this;

  @override
  String toString() => 'Flavor "$flavorName" not found.';
}

/// Exception thrown when an app is not found.
class const AppNotFoundException(
  /// The app name that was not found.
  final String appName,
) implements Exception {
  /// Creates a new [AppNotFoundException].
  this;

  @override
  String toString() => 'App "$appName" not found in apps directory.';
}

/// Service for managing app flavors.
class FlavorService({
  /// The root path of the monorepo.
  required final String rootPath,
  CliLogger? logger,
}) {
  /// Creates a new [FlavorService].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  /// Gets the path to the apps directory.
  String get appsPath => path.join(rootPath, 'apps');

  /// Finds all apps in the monorepo that have flavorizr.yaml.
  List<String> findAppsWithFlavors() {
    final appsDir = Directory(appsPath);
    if (!appsDir.existsSync()) {
      return [];
    }

    return appsDir
        .listSync()
        .whereType<Directory>()
        .where((d) => _hasFlavorizrConfig(d.path))
        .map((d) => path.basename(d.path))
        .toList()
      ..sort();
  }

  /// Finds all apps in the monorepo (with or without flavorizr.yaml).
  List<String> findAllApps() {
    final appsDir = Directory(appsPath);
    if (!appsDir.existsSync()) {
      return [];
    }

    return appsDir
        .listSync()
        .whereType<Directory>()
        .where((d) => _hasPubspec(d.path))
        .map((d) => path.basename(d.path))
        .toList()
      ..sort();
  }

  bool _hasFlavorizrConfig(String appPath) =>
      File(path.join(appPath, 'flavorizr.yaml')).existsSync();

  bool _hasPubspec(String dirPath) =>
      File(path.join(dirPath, 'pubspec.yaml')).existsSync();

  /// Gets the full path to an app.
  String getAppPath(String appName) => path.join(appsPath, appName);

  /// Gets the flavorizr.yaml path for an app.
  String getFlavorizrPath(String appName) =>
      path.join(getAppPath(appName), 'flavorizr.yaml');

  /// Gets the flavor configuration for an app.
  FlavorizrConfig? getFlavorsForApp(String appName) {
    final appPath = getAppPath(appName);
    if (!Directory(appPath).existsSync()) {
      return null;
    }

    final configPath = getFlavorizrPath(appName);
    if (!File(configPath).existsSync()) {
      return null;
    }

    return FlavorizrConfig.fromFile(configPath);
  }

  /// Validates a flavor name.
  bool isValidFlavorName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }

  /// Adds a new flavor to an app.
  void addFlavor({required String appName, required FlavorConfig flavor}) {
    final appPath = getAppPath(appName);
    if (!Directory(appPath).existsSync()) {
      throw AppNotFoundException(appName);
    }

    final configPath = getFlavorizrPath(appName);
    final config = FlavorizrConfig.fromFile(configPath);

    if (config.flavors.containsKey(flavor.name)) {
      throw FlavorExistsException(flavor.name);
    }

    _logger.progress('Adding flavor "${flavor.name}" to flavorizr.yaml');
    config.addFlavor(configPath, flavor);
    _logger.success('Updated flavorizr.yaml');
  }

  /// Removes a flavor from an app.
  void removeFlavor({required String appName, required String flavorName}) {
    final appPath = getAppPath(appName);
    if (!Directory(appPath).existsSync()) {
      throw AppNotFoundException(appName);
    }

    final configPath = getFlavorizrPath(appName);
    final config = FlavorizrConfig.fromFile(configPath);

    if (!config.flavors.containsKey(flavorName)) {
      throw FlavorNotFoundException(flavorName);
    }

    _logger.progress('Removing flavor "$flavorName" from flavorizr.yaml');
    config.removeFlavor(configPath, flavorName);
    _logger.success('Updated flavorizr.yaml');
  }

  /// Runs flutter_flavorizr to generate flavor files.
  Future<int> generateFlavors(
    String appName, {
    bool excludeIcons = false,
  }) async {
    final appPath = getAppPath(appName);
    if (!Directory(appPath).existsSync()) {
      throw AppNotFoundException(appName);
    }

    // We always strip `flutter:*` instructions from flavorizr.yaml because
    // archipelago has its own pipeline for flavor-aware main entry files
    // and flavor-aware Dart code (see generateFlavorMainFiles + the
    // flavor_manager generate command). Letting flutter_flavorizr also
    // run those processors would overwrite our output with its templates.
    //
    // When excludeIcons is true, also strip icon-related entries.
    // flutter_flavorizr has no CLI flag for processor selection — it
    // reads instructions from the yaml — so we modify the file in place
    // and restore it after the run via try/finally.
    final yamlPath = path.join(appPath, 'flavorizr.yaml');
    String? originalYaml;
    final yamlFile = File(yamlPath);
    if (yamlFile.existsSync()) {
      originalYaml = yamlFile.readAsStringSync();
      var filtered = _stripFlutterInstructions(originalYaml);
      if (excludeIcons) {
        filtered = _stripIconInstructions(filtered);
      }
      if (filtered != originalYaml) {
        yamlFile.writeAsStringSync(filtered);
      } else {
        originalYaml = null; // Nothing to restore.
      }
    }

    try {
      // --force skips flutter_flavorizr's "Do you want to proceed?"
      // confirmation prompt. Without it, flutter_flavorizr 2.5+ calls
      // mason_logger's Logger.confirm(), which throws
      // "Bad state: No terminal attached to stdout" whenever stdout has
      // no TTY (CI, the `archipelago create` post_gen hook, etc.) — piping
      // stdin does not help since mason_logger checks stdout.hasTerminal,
      // not stdin. flutter_flavorizr's own entrypoint short-circuits the
      // confirm call entirely when force is true
      // (`force || logger.confirm(...)`), so this is the supported
      // non-interactive path rather than a workaround.
      //
      // Its first instruction, assets:download, fetches assets.zip from
      // GitHub on every run without checking the response, so a network
      // blip fails the whole run while a rerun succeeds. Hence the retry.
      final result = await runWithRetry(
        () => ShellRunner.run(
          'dart run flutter_flavorizr --force',
          workingDirectory: appPath,
        ),
        onRetry: (failed) => _logger.warning(
          'flutter_flavorizr failed (exit ${failed.exitCode}), retrying:\n'
          '${outputTail(failed)}',
        ),
      );
      if (result.exitCode != 0) {
        _logger.error(outputTail(result));
      } else {
        final pbxproj = File(
          path.join(appPath, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
        );
        if (pbxproj.existsSync()) {
          final before = pbxproj.readAsStringSync();
          final after = mirrorProjectConfigsToTargets(before);
          if (after != before) pbxproj.writeAsStringSync(after);
        }
      }
      return result.exitCode;
    } finally {
      if (originalYaml != null) {
        File(yamlPath).writeAsStringSync(originalYaml);
      }
    }
  }

  /// Runs [run] up to [attempts] times until it exits 0, waiting [delay]
  /// between tries. Returns the last result.
  static Future<ProcessResult> runWithRetry(
    Future<ProcessResult> Function() run, {
    int attempts = 3,
    Duration delay = const Duration(seconds: 3),
    void Function(ProcessResult failed)? onRetry,
  }) async {
    var result = await run();
    for (var i = 1; i < attempts && result.exitCode != 0; i++) {
      onRetry?.call(result);
      await Future<void>.delayed(delay);
      result = await run();
    }
    return result;
  }

  /// Last [lines] non-empty lines of [result]'s stdout and stderr.
  static String outputTail(ProcessResult result, {int lines = 30}) {
    final out = '${result.stdout}\n${result.stderr}'
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    return out.skip(out.length > lines ? out.length - lines : 0).join('\n');
  }

  /// Removes icon-related entries (`*:icons`) from a flavorizr.yaml
  /// `instructions:` list. Returns the modified yaml string.
  static String _stripIconInstructions(String yaml) {
    const iconLineSuffixes = ['android:icons', 'ios:icons', 'macos:icons'];
    return _filterInstructions(yaml, iconLineSuffixes.contains);
  }

  /// Removes `flutter:*` entries from a flavorizr.yaml `instructions:`
  /// list. Archipelago has its own flavor-aware Dart pipeline so
  /// flavorizr's flutter processors are unwanted.
  static String _stripFlutterInstructions(String yaml) =>
      _filterInstructions(yaml, (entry) => entry.startsWith('flutter:'));

  static String _filterInstructions(
    String yaml,
    bool Function(String entry) shouldRemove,
  ) {
    final lines = yaml.split('\n');
    final filtered = lines.where((line) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('-')) return true;
      final value = trimmed.substring(1).trim();
      return !shouldRemove(value);
    }).toList();
    return filtered.join('\n');
  }

  /// Creates a default flavor configuration.
  FlavorConfig createDefaultFlavor({
    required String name,
    FlavorizrConfig? existingConfig,
    String? appNameSuffix,
    String? bundleIdSuffix,
  }) {
    final suffix = bundleIdSuffix ?? '.$name';
    final displaySuffix = appNameSuffix ?? ' [${name.toUpperCase()}]';

    final baseFlavor =
        existingConfig?.flavors['production'] ??
        existingConfig?.flavors.values.firstOrNull;

    var baseAppName = 'App';
    if (baseFlavor?.app?.name != null) {
      baseAppName = baseFlavor!.app!.name!
          .replaceAll(RegExp(r'\s*\[.*\]'), '')
          .trim();
    }

    var baseAndroidId = 'com.example.app';
    var baseIosBundle = 'com.example.app';

    if (baseFlavor?.android?.applicationId != null) {
      baseAndroidId = baseFlavor!.android!.applicationId!.replaceAll(
        RegExp(r'\.(dev|stg|staging|prod|production)$'),
        '',
      );
    }

    if (baseFlavor?.ios?.bundleId != null) {
      baseIosBundle = baseFlavor!.ios!.bundleId!.replaceAll(
        RegExp(r'\.(dev|stg|staging|prod|production)$'),
        '',
      );
    }

    return FlavorConfig(
      name: name,
      app: AppConfig(name: '$baseAppName$displaySuffix'),
      android: AndroidFlavorConfig(
        applicationId: '$baseAndroidId$suffix',
        icon: 'launcher/logo-$name.png',
        adaptiveIcon: {
          'background': 'launcher/logo-background-$name.png',
          'foreground': 'launcher/logo-foreground.png',
        },
      ),
      ios: IosFlavorConfig(
        // Apple bundle IDs allow no underscore (Archipelago-2pyl).
        bundleId: '$baseIosBundle${suffix.replaceAll('_', '')}',
        icon: 'launcher/ios-logo-$name.png',
      ),
    );
  }

  /// Checks if an app has native splash configured.
  bool hasNativeSplash(String appName) =>
      File(path.join(getAppPath(appName), 'flutter_native_splash.yaml'))
          .existsSync();

  /// Generates native splash screens for all flavors.
  Future<int> generateNativeSplash(String appName) async {
    final appPath = getAppPath(appName);
    final result = await ShellRunner.run(
      'dart run flutter_native_splash:create',
      workingDirectory: appPath,
    );
    return result.exitCode;
  }

  /// Updates iOS storyboards for all flavors in an app.
  Future<void> updateAllFlavorStoryboards(String appName) async {
    // Storyboard update is handled by flutter_flavorizr
    _logger.info('Storyboard update delegated to flutter_flavorizr');
  }

  /// Generates IDE configurations for all apps with flavors.
  void generateAllIdeConfigs() {
    final generator = IdeConfigGenerator(rootPath: rootPath);
    final appFlavors = <String, List<String>>{};

    for (final appName in findAppsWithFlavors()) {
      final config = getFlavorsForApp(appName);
      if (config != null) {
        appFlavors[appName] = config.flavorNames;
      }
    }

    if (appFlavors.isNotEmpty) {
      generator.generateVsCodeConfig(appFlavors);
      generator.generateJetBrainsConfig(appFlavors);
    }
  }

  /// Gets flavors that need regeneration for an app.
  List<String> getFlavorsNeedingRegeneration(String appName) {
    final config = getFlavorsForApp(appName);
    if (config == null) return [];

    final cachePath = FlavorGenerationCache.getCachePath(rootPath);
    final cache = FlavorGenerationCache.fromFile(cachePath);
    final appCache = cache.apps[appName];

    if (appCache == null) return config.flavorNames;

    final appPath = getAppPath(appName);
    return config.flavorNames.where((flavorName) {
      final currentHash = FlavorHasher.computeHash(
        appPath: appPath,
        flavorName: flavorName,
      );
      return appCache.needsRegeneration(flavorName, currentHash);
    }).toList();
  }

  /// Marks a flavor as generated in the cache.
  void markFlavorGenerated(String appName, String flavorName) {
    final cachePath = FlavorGenerationCache.getCachePath(rootPath);
    final cache = FlavorGenerationCache.fromFile(cachePath);
    final appCache = cache.getOrCreateApp(appName);

    final appPath = getAppPath(appName);
    final hash = FlavorHasher.computeHash(
      appPath: appPath,
      flavorName: flavorName,
    );

    appCache.updateFlavor(
      flavorName,
      FlavorGenerationStatus(inputHash: hash, lastGenerated: DateTime.now()),
    );

    cache.save(cachePath);
  }

  /// Generates flavor-based main entry point files.
  ///
  /// Each missing `main_<flavor>.dart` is a copy of an existing entry file
  /// (`main.dart` first) with its `bootstrap(flavor: ...)` argument
  /// rewritten, so it keeps the app's real bootstrap and widget. A new
  /// flavor needs its `FlavorStatus` value: run `env sync`.
  Future<void> generateFlavorMainFiles(String appName) async {
    final appPath = getAppPath(appName);
    final config = getFlavorsForApp(appName);
    if (config == null) return;

    final libDir = Directory(path.join(appPath, 'lib'));
    final template = _mainTemplate(libDir);
    if (template == null) {
      _logger.warning(
        'No lib/main*.dart with a bootstrap(flavor: ...) call in $appName; '
        'skipping main files.',
      );
      return;
    }

    for (final flavorName in config.flavorNames) {
      final mainFile = _getMainFileForFlavor(flavorName);
      final file = File(path.join(libDir.path, mainFile));

      if (!file.existsSync()) {
        await file.writeAsString(
          template.replaceFirstMapped(
            _flavorArgument,
            (m) => m[1]!.startsWith("'")
                ? "flavor: '$flavorName'"
                : 'flavor: FlavorStatus.$flavorName',
          ),
        );
        _logger.info('  Created $mainFile');
      }
    }
  }

  /// `flavor: FlavorStatus.x` (template_base, app_scaffold) or
  /// `flavor: 'x'` (flutter_modular_monorepo).
  static final _flavorArgument = RegExp(r"flavor:\s*(FlavorStatus\.\w+|'\w+')");

  String? _mainTemplate(Directory libDir) {
    if (!libDir.existsSync()) return null;
    // Sorted, main.dart comes before main_<flavor>.dart.
    final candidates =
        libDir
            .listSync()
            .whereType<File>()
            .where((f) => RegExp(r'main(_\w+)?\.dart$').hasMatch(f.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in candidates) {
      final content = file.readAsStringSync();
      if (_flavorArgument.hasMatch(content)) return content;
    }
    return null;
  }

  /// Returns the main file name for a given flavor.
  String _getMainFileForFlavor(String flavor) {
    if (flavor == 'production') {
      return 'main.dart';
    }
    return 'main_$flavor.dart';
  }
}
