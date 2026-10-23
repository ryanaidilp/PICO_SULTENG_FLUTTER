import 'dart:io';

import 'package:app_scaffold/src/feature_manifest_check.dart';
import 'package:app_scaffold/src/services/app_scaffold_service.dart';
import 'package:app_scaffold/src/services/mason_bridge.dart';
import 'package:args/command_runner.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Parent command for app scaffolding operations.
///
/// Usage:
/// ```bash
/// monorepo_toolkit app create --name my_app --org com.example --domain example.com
/// ```
class AppCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [AppCommand].
  this {
    addSubcommand(CreateCommand(logger: logger));
  }

  @override
  String get name => 'app';

  @override
  String get description =>
      'Scaffold and manage Flutter apps in the workspace.';
}

/// Scaffolds a new Flutter app with full configuration.
///
/// Prefers the `app_scaffold` Mason brick when available, falling back
/// to the built-in Dart template generator.
///
/// Generates:
/// - Dart source files (main, bootstrap, DI, router, app widget)
/// - Fastlane configuration (Gemfile, Fastfile, Appfile, Matchfile, Pluginfile)
/// - Launcher icon and splash screen configs
/// - Flavorizr configuration
/// - IDE run configurations
/// - Runs `dart pub get` and `workspace setup` (brick path only)
///
/// It does not edit `flavors.yaml`; add the new app there by hand.
class CreateCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [CreateCommand].
  this {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'The name of the app (snake_case).',
        mandatory: true,
      )
      ..addOption(
        'org',
        abbr: 'o',
        help: 'The organization identifier (e.g., com.example).',
        defaultsTo: 'com.example',
      )
      ..addOption(
        'domain',
        abbr: 'd',
        help: 'The domain for bundle identifiers (e.g., example.com).',
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'create';

  @override
  String get description =>
      'Scaffold a new Flutter app with full configuration.';

  @override
  Future<int> run() async {
    final appName = argResults!['name'] as String;
    final org = argResults!['org'] as String;
    final domain = argResults!['domain'] as String? ?? _domainFromOrg(org);

    // Validate app name
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(appName)) {
      _logger.error(
        'Invalid app name "$appName". '
        'Must be lowercase with underscores (snake_case).',
      );
      return 1;
    }

    final rootPath = MonorepoFinder.requireRoot();
    final staleSdk = featureManifestApiError(rootPath);
    if (staleSdk != null) {
      _logger.error(staleSdk);
      return 1;
    }
    final appDir = Directory('$rootPath/apps/$appName');

    if (appDir.existsSync()) {
      _logger.error('App directory already exists: apps/$appName');
      return 1;
    }

    _logger.info('Scaffolding new app: $appName');
    _logger.info('  Organization: $org');
    _logger.info('  Domain: $domain');
    _logger.info('');

    try {
      final result = await _scaffoldWithMason(
        appName: appName,
        org: org,
        domain: domain,
        rootPath: rootPath,
      );

      if (result == 0) {
        // The `app_scaffold` brick's own post_gen.dart hook runs `flutter
        // create` and merges the result in (Archipelago-vu2c) — but that
        // hook is advisory-only (e.g. a missing `flutter` on PATH doesn't
        // fail generation), so probe the filesystem rather than trusting
        // the hook's own exit code to know whether it actually happened.
        _logSuccess(
          appName,
          org,
          platformScaffolded: _isPlatformScaffolded(rootPath, appName),
        );
        return 0;
      }

      // Mason failed — fall back to built-in templates
      _logger.info('');
      _logger.info('Falling back to built-in template generator...');
      return await _scaffoldWithTemplates(
        appName: appName,
        org: org,
        domain: domain,
        rootPath: rootPath,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to scaffold app: $e');
      _logger.error('$stackTrace');
      return 1;
    }
  }

  /// Attempts to scaffold the app using the Mason `app_scaffold` brick.
  ///
  /// Returns 0 on success, non-zero if Mason is not installed or
  /// the brick is not available.
  Future<int> _scaffoldWithMason({
    required String appName,
    required String org,
    required String domain,
    required String rootPath,
  }) async {
    final mason = MasonBridge(logger: _logger);

    // Check Mason installation
    if (!await mason.isMasonInstalled()) {
      _logger.info(
        'Mason CLI not found. Install it with: '
        'dart pub global activate mason_cli',
      );
      return 1;
    }

    // Check brick availability
    if (!await mason.isBrickAvailable(
      'app_scaffold',
      workingDirectory: rootPath,
    )) {
      _logger.info(
        'Mason brick "app_scaffold" not found.\n'
        'To install it:\n'
        '  mason add app_scaffold          (from mason.yaml)\n'
        '  mason add app_scaffold --git-url <repo>  (from git)\n'
        '  mason add -g app_scaffold       (globally)',
      );
      return 1;
    }

    _logger.info('Using Mason brick: app_scaffold');

    // The brick builds its IDs as <domain>.<organization>.<app>, so split the
    // reverse-DNS --org (com.example) instead of passing it whole
    // (Archipelago-2pyl).
    final dot = org.lastIndexOf('.');

    final exitCode = await mason.makeBrick(
      brickName: 'app_scaffold',
      variables: {
        'appName': appName,
        'organization': org.substring(dot + 1),
        'domain': dot > 0 ? org.substring(0, dot) : 'com',
        // The brick also declares a `prefix` var (with a `prompt:`). Mason
        // is invoked via `Process.run` (see `ShellRunner.run`), whose child
        // stdio is always piped rather than an inherited terminal, so
        // `mason make` always sees no terminal attached — leaving this var
        // out of the map isn't just "use the brick's default", it makes
        // `mason make` try to interactively prompt for it and fail
        // immediately, regardless of environment. Hardcode the brick's own
        // default ('App') so the brick path doesn't depend on a value this
        // command doesn't currently expose as a flag.
        'prefix': 'App',
      },
      // The brick's own `__brick__` tree already nests the generated app
      // under an `apps/<snake-case-name>` directory, so the output root
      // must be the workspace root itself — passing 'apps/' here would
      // double-nest into `apps/apps/<name>/`.
      outputDir: '.',
      workingDirectory: rootPath,
    );

    if (exitCode != 0) return exitCode;

    // Run post-setup
    return await mason.runPostSetup(
      appDir: '$rootPath/apps/$appName',
      rootPath: rootPath,
    );
  }

  /// Scaffolds using the built-in Dart template generator.
  Future<int> _scaffoldWithTemplates({
    required String appName,
    required String org,
    required String domain,
    required String rootPath,
  }) async {
    final service = AppScaffoldService(
      rootPath: rootPath,
      appName: appName,
      org: org,
      domain: domain,
      logger: _logger,
    );

    await service.scaffold();
    // The built-in template generator only ever writes Dart source files
    // (see AppScaffoldService.scaffold) — it never runs `flutter create`,
    // so platform directories are always still missing here.
    _logSuccess(appName, org, platformScaffolded: false);
    return 0;
  }

  /// Whether `apps/$appName` already has real `flutter create`-generated
  /// platform scaffolding, rather than just the handful of files the brick
  /// itself templates (`android/app/build.gradle.kts`, `ios/Runner/
  /// AppDelegate.swift`, ...). Checks for files `flutter create` always
  /// produces and the brick never templates, so their presence is
  /// unambiguous evidence a real `flutter create` merge succeeded.
  ///
  /// `ios/Runner.xcodeproj` (not `ios/Podfile`) is the iOS signal: modern
  /// Flutter (Swift Package Manager-based plugin resolution) no longer
  /// always generates a `Podfile`, but `flutter create` has always
  /// generated the `.xcodeproj`, regardless of dependency manager.
  bool _isPlatformScaffolded(String rootPath, String appName) {
    final appDir = '$rootPath/apps/$appName';
    return Directory('$appDir/ios/Runner.xcodeproj').existsSync() &&
        File('$appDir/android/app/src/main/AndroidManifest.xml').existsSync();
  }

  void _logSuccess(
    String appName,
    String org, {
    required bool platformScaffolded,
  }) {
    _logger.success('');
    _logger.success('App "$appName" scaffolded successfully!');
    _logger.info('');

    final steps = <String>[
      'Run "dart pub get" to resolve dependencies',
      'Run "melos run build" to generate code',
    ];

    if (!platformScaffolded) {
      steps.add(
        'Run "flutter create apps/$appName --org $org" '
        'to generate platform directories',
      );
    }

    steps.add(
      'Run "melos run flavor:generate -- --app $appName" to apply flavorizr',
    );

    _logger.info('Next steps:');
    for (var i = 0; i < steps.length; i++) {
      _logger.info('  ${i + 1}. ${steps[i]}');
    }
  }

  String _domainFromOrg(String org) {
    final parts = org.split('.').reversed.toList();
    return parts.join('.');
  }
}
