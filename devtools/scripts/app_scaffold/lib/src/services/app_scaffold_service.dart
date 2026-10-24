import 'dart:io';

import 'package:app_scaffold/src/templates/app_template.dart';
import 'package:app_scaffold/src/templates/bootstrap_template.dart';
import 'package:app_scaffold/src/templates/injector_template.dart';
import 'package:app_scaffold/src/templates/main_template.dart';
import 'package:app_scaffold/src/templates/pubspec_template.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';

/// The workspace's real UI kit package (e.g. `minimal_ci_ui_kit`) and the
/// theme factory class it exposes (e.g. `AppTheme`), resolved from the
/// filesystem rather than hardcoded — see [AppScaffoldService._resolveUiKit].
typedef _UiKitTarget = ({String packageName, String themeClassName});

/// Service that scaffolds a new Flutter app using built-in Dart templates.
///
/// This is the fallback generator used when the Mason brick is not available.
/// It writes all template files directly to disk.
class AppScaffoldService({
  /// The monorepo root path.
  required final String rootPath,

  /// The app name in snake_case.
  required final String appName,

  /// The organization identifier (e.g., com.example).
  required final String org,

  /// The domain for bundle identifiers.
  required final String domain,
  CliLogger? logger,
}) {
  /// Creates a new [AppScaffoldService].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  String get _appDir => '$rootPath/apps/$appName';

  String get _appClassName => appName
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join();

  String get _appTitle => appName
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  /// Scaffolds the full app directory structure.
  Future<void> scaffold() async {
    _logger.info('Using built-in template generator...');

    // Resolve the workspace's real UI kit package/theme class before
    // writing anything — see [_resolveUiKit].
    final uiKit = _resolveUiKit();

    // Create directory structure
    await _createDirectories();

    // Write template files
    await _writePubspec(uiKit);
    await _writeMainFiles();
    await _writeAppFile(uiKit);
    await _writeBenchmarkFile();
    await _writeBootstrapFile();
    await _writeInjectorFile();
    await _writeRouterFile();
    await _writeHostFiles();
  }

  /// Resolves the workspace's real UI kit package name and theme factory
  /// class by scanning `packages/` for the sole `*_ui_kit` directory.
  ///
  /// `flutter_modular_monorepo`/`flutter_ui_kit` always name the UI kit
  /// package after the *first* app in the workspace (`<mainAppName>_ui_kit`)
  /// and its theme class after that app's `prefix` (`<Prefix>Theme`) —
  /// neither is a fixed literal this fallback generator can hardcode, so
  /// both must be resolved against the real workspace on disk
  /// (Archipelago-wy57).
  ///
  /// Throws a [StateError] (propagates to the CLI command's catch, which
  /// logs the error and exits non-zero) if zero or more than one
  /// `*_ui_kit` package or theme class is found — guessing wrong here would
  /// silently embed a nonexistent package/import in the generated app.
  _UiKitTarget _resolveUiKit() {
    final packagesDir = Directory('$rootPath/packages');
    if (!packagesDir.existsSync()) {
      throw StateError(
        'Cannot resolve the workspace UI kit package: '
        '"${packagesDir.path}" does not exist. Expected exactly one '
        '"*_ui_kit" directory there (created by flutter_modular_monorepo/ '
        'flutter_ui_kit) for app_scaffold to wire apps/$appName up to.',
      );
    }

    final uiKitDirs =
        packagesDir
            .listSync()
            .whereType<Directory>()
            .where((d) => p.basename(d.path).endsWith('_ui_kit'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    if (uiKitDirs.length != 1) {
      final found = uiKitDirs.isEmpty
          ? 'none'
          : uiKitDirs.map((d) => p.basename(d.path)).join(', ');
      throw StateError(
        'Expected exactly one "*_ui_kit" package under "${packagesDir.path}" '
        'to wire apps/$appName up to, found ${uiKitDirs.length} ($found). '
        'app_scaffold cannot guess which UI kit package the new app should '
        'depend on — resolve the ambiguity in packages/ and re-run.',
      );
    }

    final uiKitDir = uiKitDirs.single;
    final packageName = p.basename(uiKitDir.path);

    final themeClassPattern = RegExp(r'abstract final class (\w*Theme)\b');
    final themeClassMatches = <String>{};
    final libDir = Directory(p.join(uiKitDir.path, 'lib'));
    if (libDir.existsSync()) {
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final match = themeClassPattern.firstMatch(entity.readAsStringSync());
          if (match != null) {
            themeClassMatches.add(match.group(1)!);
          }
        }
      }
    }

    if (themeClassMatches.length != 1) {
      final found = themeClassMatches.isEmpty
          ? 'none'
          : themeClassMatches.join(', ');
      throw StateError(
        'Expected exactly one theme factory class (matching '
        '"abstract final class <Prefix>Theme") under "${libDir.path}", '
        'found ${themeClassMatches.length} ($found). Cannot determine the '
        'correct theme class for apps/$appName.',
      );
    }

    return (packageName: packageName, themeClassName: themeClassMatches.single);
  }

  Future<void> _createDirectories() async {
    final dirs = [
      '$_appDir/lib',
      '$_appDir/lib/di',
      '$_appDir/lib/router',
      '$_appDir/lib/host/initializers',
      '$_appDir/test',
    ];

    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }

    _logger.info('Created directory structure.');
  }

  Future<void> _writePubspec(_UiKitTarget uiKit) async {
    await _writeFile(
      '$_appDir/pubspec.yaml',
      pubspecTemplate(appName: appName, uiKitPackageName: uiKit.packageName),
    );
  }

  Future<void> _writeMainFiles() async {
    const flavors = [
      ('development', 'development'),
      ('staging', 'staging'),
      ('production', 'production'),
    ];

    // main.dart (defaults to development)
    await _writeFile(
      '$_appDir/lib/main.dart',
      mainTemplate(
        appName: appName,
        flavor: 'development',
        flavorEnum: 'development',
        appClassName: _appClassName,
      ),
    );

    // Flavor-specific entry points
    for (final (flavor, flavorEnum) in flavors) {
      await _writeFile(
        '$_appDir/lib/main_$flavor.dart',
        mainTemplate(
          appName: appName,
          flavor: flavor,
          flavorEnum: flavorEnum,
          appClassName: _appClassName,
        ),
      );
    }
  }

  Future<void> _writeAppFile(_UiKitTarget uiKit) async {
    await _writeFile(
      '$_appDir/lib/app.dart',
      appTemplate(
        appName: appName,
        appClassName: _appClassName,
        appTitle: _appTitle,
        uiKitPackageName: uiKit.packageName,
        themeClassName: uiKit.themeClassName,
      ),
    );
  }

  Future<void> _writeBenchmarkFile() async {
    await _writeFile('$_appDir/lib/benchmark.dart', benchmarkTemplate());
  }

  Future<void> _writeBootstrapFile() async {
    await _writeFile(
      '$_appDir/lib/bootstrap.dart',
      bootstrapTemplate(appName: appName),
    );
  }

  Future<void> _writeInjectorFile() async {
    await _writeFile(
      '$_appDir/lib/di/injector.dart',
      injectorTemplate(appName: appName),
    );
  }

  Future<void> _writeRouterFile() async {
    await _writeFile(
      '$_appDir/lib/router/app_router.dart',
      routerTemplate(appName: appName),
    );
  }

  Future<void> _writeHostFiles() async {
    await _writeFile(
      '$_appDir/lib/host/host_app_widget.dart',
      hostAppWidgetTemplate(appName: appName),
    );

    await _writeFile(
      '$_appDir/lib/host/initializers/initializer.dart',
      initializerTemplate(appName: appName),
    );

    await _writeFile(
      '$_appDir/lib/host/initializers/pre_launch_initializer.dart',
      preLaunchInitializerTemplate(appName: appName),
    );

    await _writeFile(
      '$_appDir/lib/host/initializers/post_launch_initializer.dart',
      postLaunchInitializerTemplate(appName: appName),
    );
  }

  Future<void> _writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    _logger.info('  Created ${file.path.replaceFirst(rootPath, '.')}');
  }
}
