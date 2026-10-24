import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:yaml/yaml.dart';

/// Service for managing environment configuration files.
///
/// Handles generation and modification of:
/// - Per-flavor `.env.<flavor>` source files
/// - Single `env.dart` class (reads from `.env`)
/// - `FlavorStatus` enum synchronization
///
/// The active flavor is selected via `env switch <flavor>`, which copies
/// `.env.<flavor>` → `.env` so build_runner picks up the correct values.
class EnvService({
  /// The root path of the monorepo.
  required final String rootPath,
  CliLogger? logger,
}) {
  /// Creates a new [EnvService].
  this;

  final CliLogger _logger = logger ?? CliLogger();

  /// Path to the app_config package.
  String get configPackagePath => path.join(rootPath, 'shared', 'app_config');

  /// Path to the env source directory.
  String get envSrcPath => path.join(configPackagePath, 'lib', 'src', 'env');

  /// Path to the flavor.dart file.
  String get flavorFilePath =>
      path.join(configPackagePath, 'lib', 'src', 'flavor.dart');

  /// Path to the single env.dart file.
  String get envFilePath => path.join(envSrcPath, 'env.dart');

  /// Path to the app_env.dart file.
  String get appEnvFilePath => path.join(envSrcPath, 'app_env.dart');

  /// Gets the list of flavors from the global flavor settings.
  List<String> getFlavorsFromSettings() {
    final flavorsYamlPath = path.join(rootPath, 'flavors.yaml');
    final file = File(flavorsYamlPath);

    if (!file.existsSync()) {
      return ['development', 'staging', 'production'];
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;
    final defaults = yaml?['defaults'] as YamlMap?;
    // `defaultFlavors` is the pre-fix spelling, kept for one release.
    final defaultFlavors =
        (defaults?['default_flavors'] ?? defaults?['defaultFlavors'])
            as YamlList?;

    if (defaultFlavors != null) {
      return defaultFlavors.cast<String>().toList();
    }

    // Extract from apps section
    final apps = yaml?['apps'] as YamlMap?;
    if (apps != null && apps.isNotEmpty) {
      final firstApp = apps.values.first as YamlMap?;
      final flavors = firstApp?['flavors'] as YamlList?;
      if (flavors != null) {
        return flavors.cast<String>().toList();
      }
    }

    return ['development', 'staging', 'production'];
  }

  /// Gets existing env variable names from the single env.dart class.
  List<String> getExistingEnvVariables() {
    final envFile = File(envFilePath);
    if (!envFile.existsSync()) return [];

    final content = envFile.readAsStringSync();
    // Match `static final String <name>` or `static const String <name>`
    final pattern = RegExp(r'static\s+(?:final|const)\s+String\s+(\w+)\s*=');
    final matches = pattern.allMatches(content);

    return matches.map((m) => m.group(1)!).toList();
  }

  /// Whether `env.dart` already declares one or more `@EnviedField()`s.
  ///
  /// Used to guard against `env init` silently clobbering a package that a
  /// project has already extended by hand (see `EnvInitCommand`).
  bool isInitialized() => getExistingEnvVariables().isNotEmpty;

  /// Path to the `.env.example` template file, if present.
  String get envExampleFilePath => path.join(configPackagePath, '.env.example');

  /// Reads variable names declared in this package's `.env.example`.
  ///
  /// Returns the CONSTANT_CASE names as they appear before `=`, in file
  /// order, skipping blank lines and comments. Returns an empty list if no
  /// `.env.example` file exists.
  List<String> getVariablesFromEnvExample() {
    final file = File(envExampleFilePath);
    if (!file.existsSync()) return [];

    final names = <String>[];
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final eqIndex = line.indexOf('=');
      if (eqIndex <= 0) continue;

      names.add(line.substring(0, eqIndex).trim());
    }

    return names;
  }

  /// Resolves which variables to use when scaffolding `.env.<flavor>`
  /// files or a from-scratch `env.dart`, in priority order:
  ///
  /// 1. This package's `.env.example`, if present.
  /// 2. The existing `env.dart` fields, if any (converted back to
  ///    CONSTANT_CASE).
  /// 3. The tool's built-in two-variable default (`API_BASE_URL`,
  ///    `AES_KEY`), only for a genuinely from-scratch package with neither
  ///    of the above.
  List<String> resolveScaffoldVariables() {
    final fromExample = getVariablesFromEnvExample();
    if (fromExample.isNotEmpty) return fromExample;

    final existing = getExistingEnvVariables();
    if (existing.isNotEmpty) {
      return existing.map(_toConstantCase).toList();
    }

    return const ['API_BASE_URL', 'AES_KEY'];
  }

  /// Ensures a `.env.<flavor>` scaffold exists for every configured
  /// flavor, without overwriting any file that already exists on disk.
  ///
  /// Variable names come from [envVariables] if provided, otherwise from
  /// [resolveScaffoldVariables]. Returns the flavors for which a new file
  /// was actually created (pre-existing files are left untouched and are
  /// not included).
  Future<List<String>> ensureEnvTemplateFiles({
    List<String>? envVariables,
  }) async {
    final flavors = getFlavorsFromSettings();
    final variables = envVariables ?? resolveScaffoldVariables();

    await Directory(envSrcPath).create(recursive: true);

    final created = <String>[];
    for (final flavor in flavors) {
      final filePath = path.join(configPackagePath, '.env.$flavor');
      if (File(filePath).existsSync()) continue;

      await _generateEnvTemplateFile(flavor, variables);
      created.add(flavor);
    }

    return created;
  }

  /// Initializes env configuration for all flavors.
  ///
  /// Creates per-flavor `.env.<flavor>` source files, generates the single
  /// `env.dart` class, syncs the FlavorStatus enum, then switches to
  /// `development` so `.env` is immediately populated.
  ///
  /// This unconditionally (re)writes `env.dart`/`flavor.dart`/
  /// `.env.<flavor>` — callers that must not clobber an already-initialized
  /// package (e.g. `EnvInitCommand`) should check [isInitialized] first and
  /// use [ensureEnvTemplateFiles] instead when it returns `true`.
  ///
  /// When [envVariables] is not provided, the variable list is resolved via
  /// [resolveScaffoldVariables].
  Future<void> initializeEnv({List<String>? envVariables}) async {
    final flavors = getFlavorsFromSettings();
    final variables = envVariables ?? resolveScaffoldVariables();

    _logger.info('Initializing env config for flavors: ${flavors.join(', ')}');

    // Create env directory if needed
    await Directory(envSrcPath).create(recursive: true);

    // Generate per-flavor .env.<flavor> source files
    for (final flavor in flavors) {
      await _generateEnvTemplateFile(flavor, variables);
    }

    // Generate single env.dart class
    await _generateSingleEnvClass(variables);

    // Sync FlavorStatus enum
    await _syncFlavorStatusEnum(flavors);

    // Switch to development by default so .env is populated
    await _switchFlavor('development');

    _logger.success('Env configuration initialized!');
  }

  /// Brings every flavor up to date without touching existing values.
  ///
  /// Creates a missing `.env.<flavor>` or `env.dart`, appends only the
  /// missing keys (from `.env.example` and the `env.dart` fields) to each
  /// `.env.<flavor>`, adds missing `env.dart` fields the way `env add` does,
  /// and rewrites the FlavorStatus enum only when its flavors changed, so
  /// its doc comments survive a no-op sync. `.env` is left alone.
  Future<void> syncEnv() async {
    final flavors = getFlavorsFromSettings();
    final existingFields = getExistingEnvVariables();
    final variables = {
      ...resolveScaffoldVariables().map(_toConstantCase),
      ...existingFields.map(_toConstantCase),
    }.toList();

    await ensureEnvTemplateFiles(envVariables: variables);
    for (final flavor in flavors) {
      for (final variable in variables) {
        await _addVariableToEnvTemplateFile(flavor, variable);
      }
    }

    if (!File(envFilePath).existsSync()) {
      await _generateSingleEnvClass(variables);
    } else {
      for (final variable in variables) {
        await _addVariableToSingleEnvClass(variable);
        await _addVariableToAppEnv(variable);
      }
    }

    if (!_flavorFileMatches(flavors)) await _syncFlavorStatusEnum(flavors);
  }

  /// Whether `flavor.dart` already lists exactly [flavors].
  bool _flavorFileMatches(List<String> flavors) {
    final file = File(flavorFilePath);
    if (!file.existsSync()) return false;
    final names = RegExp(r'FlavorStatus\.(\w+) =>')
        .allMatches(file.readAsStringSync())
        .map((m) => m[1]!)
        .toSet();
    return names.length == flavors.length && names.containsAll(flavors);
  }

  /// Adds a new environment variable to all flavor configurations.
  ///
  /// Adds the variable to all `.env.<flavor>` files and to `env.dart`.
  /// Does NOT touch `.env` directly — that is managed by `env switch`.
  Future<void> addEnvVariable(String variableName) async {
    final flavors = getFlavorsFromSettings();
    final existingVars = getExistingEnvVariables();
    final camelCase = _toCamelCase(variableName);

    if (existingVars.contains(camelCase)) {
      _logger.warning('Variable "$variableName" already exists.');
      return;
    }

    _logger.info('Adding env variable: $variableName');

    // Add to each .env.<flavor> file
    for (final flavor in flavors) {
      await _addVariableToEnvTemplateFile(flavor, variableName);
    }

    // Add to single env.dart
    await _addVariableToSingleEnvClass(variableName);
    await _addVariableToAppEnv(variableName);

    _logger.success('Added "$variableName" to all flavor configurations.');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _generateSingleEnvClass(List<String> variables) async {
    final fields = variables
        .map((v) {
          final camelCase = _toCamelCase(v);
          return '''
  /// The ${_toTitleCase(v)} value.
  @EnviedField()
  static final String $camelCase = _Env.$camelCase;''';
        })
        .join('\n\n');

    final content =
        '''
import 'package:envied/envied.dart';

part 'env.g.dart';

/// Single source of environment variables for the active flavor.
///
/// Values are populated by build_runner from the `.env` file at the package
/// root. To switch flavors, run:
/// ```bash
/// dart run monorepo_toolkit env switch <flavor>
/// dart run build_runner build
/// ```
///
/// The `.env` file is gitignored — it is written at build time by `env switch`.
/// Never edit it directly.
@Envied(path: '.env', obfuscate: true, useConstantCase: true)
abstract final class Env {
$fields
}
''';

    await File(envFilePath).writeAsString(content);
  }

  Future<void> _generateEnvTemplateFile(
    String flavor,
    List<String> variables,
  ) async {
    final fileName = '.env.$flavor';
    final filePath = path.join(configPackagePath, fileName);

    final entries = variables
        .map((v) {
          final constCase = _toConstantCase(v);
          return '$constCase=${_placeholderFor(constCase)}';
        })
        .join('\n');

    final content =
        '''
# Environment configuration for $flavor
# Replace these placeholder values with real ones for your project.

$entries
''';

    await File(filePath).writeAsString(content);
  }

  /// Non-empty placeholder value for a scaffolded `.env.<flavor>` entry.
  ///
  /// `envied` (`@EnviedField()`, no `defaultValue`) treats an empty value as
  /// "not found" and fails codegen outright (Archipelago-r3mx), so every
  /// scaffolded variable needs SOME value, not just a bare `KEY=`. Known
  /// keys get the exact placeholder `post_gen.dart`'s `_createEnvFiles`
  /// writes at generation time (see
  /// flutter_modular_monorepo/hooks/post_gen.dart) so `env init` on a fresh
  /// clone reproduces the same buildable state the generator produced.
  /// Custom variables (e.g. added via `env add`) get a generic
  /// `replace-with-your-<key>` placeholder instead.
  static const Map<String, String> _knownPlaceholders = {
    'API_BASE_URL': 'https://api.example.com',
    'APP_NAME': 'MyApp',
    'AES_KEY': 'replace-with-your-aes-key',
    'DATABASE_URL': 'sqlite:///path/to/database.db',
    'APPSFLYER_DEV_KEY': 'replace-with-your-appsflyer-dev-key',
    'APPSFLYER_APP_ID': 'replace-with-your-appsflyer-app-id',
    'MIXPANEL_TOKEN': 'replace-with-your-mixpanel-token',
    'MOENGAGE_APP_ID': 'replace-with-your-moengage-app-id',
    // Added by auth_sdk's supabase backend (its post_gen writes the same).
    'SUPABASE_URL': 'https://replace-with-your-project.supabase.co',
    'SUPABASE_ANON_KEY': 'replace-with-your-supabase-anon-key',
  };

  String _placeholderFor(String constCase) {
    final known = _knownPlaceholders[constCase];
    if (known != null) return known;
    return 'replace-with-your-${constCase.toLowerCase().replaceAll('_', '-')}';
  }

  Future<void> _syncFlavorStatusEnum(List<String> flavors) async {
    final enumValues = flavors
        .map((f) {
          final doc = '  /// ${_toTitleCase(f)} flavor';
          final suffix = f == flavors.last ? ';' : ',';
          return '$doc\n  $f$suffix';
        })
        .join('\n\n');

    final codeCases = flavors
        .map((f) {
          final name = _toConstantCase(f).toLowerCase();
          // Short names such as `qa` keep their full length.
          final code = name.length > 3 ? name.substring(0, 3) : name;
          return "    FlavorStatus.$f => '$code',";
        })
        .join('\n');

    final displayCases = flavors
        .map((f) {
          final display = _toTitleCase(f);
          return "    FlavorStatus.$f => '$display',";
        })
        .join('\n');

    final isGetters = flavors
        .map((f) {
          final pascalCase = _toPascalCase(f);
          return '''
  /// Whether the current flavor is $f.
  static bool get is$pascalCase => status == FlavorStatus.$f;''';
        })
        .join('\n\n');

    final content =
        '''
/// Defines the available flavor states for the application.
enum FlavorStatus {
$enumValues

  /// Returns the short code for this flavor.
  String get code => switch (this) {
$codeCases
  };

  /// Returns the display name for this flavor.
  String get displayName => switch (this) {
$displayCases
  };
}

/// Manages the current application flavor status.
abstract final class Flavor {
  /// The current flavor status of the application.
  static FlavorStatus? status;

  /// Returns the current flavor status, throwing if not initialized.
  static FlavorStatus get current {
    final currentStatus = status;
    if (currentStatus == null) {
      throw StateError(
        'Flavor.status has not been initialized. '
        'Call Flavor.status = FlavorStatus.xxx in main() before accessing.',
      );
    }
    return currentStatus;
  }

$isGetters
}
''';

    await File(flavorFilePath).writeAsString(content);
  }

  Future<void> _addVariableToEnvTemplateFile(
    String flavor,
    String variableName,
  ) async {
    final fileName = '.env.$flavor';
    final filePath = path.join(configPackagePath, fileName);
    final file = File(filePath);

    if (!file.existsSync()) {
      _logger.warning('$fileName not found, skipping');
      return;
    }

    final content = await file.readAsString();
    final constCase = _toConstantCase(variableName);

    if (RegExp(
      '^${RegExp.escape(constCase)}=',
      multiLine: true,
    ).hasMatch(content)) {
      return;
    }

    final separator = content.isEmpty || content.endsWith('\n') ? '' : '\n';
    final updatedContent =
        '$content$separator$constCase=${_placeholderFor(constCase)}\n';
    await file.writeAsString(updatedContent);
  }

  Future<void> _addVariableToSingleEnvClass(String variableName) async {
    final file = File(envFilePath);
    if (!file.existsSync()) {
      _logger.warning('env.dart not found');
      return;
    }

    final content = await file.readAsString();
    final camelCase = _toCamelCase(variableName);

    if (content.contains('String $camelCase =')) {
      return;
    }

    final newField =
        '''

  /// The ${_toTitleCase(variableName)} value.
  @EnviedField()
  static final String $camelCase = _Env.$camelCase;
''';

    final updatedContent = content.replaceFirst(
      RegExp(r'\}\n$'),
      '$newField}\n',
    );

    await file.writeAsString(updatedContent);
  }

  /// Adds the `AppEnv` getter for [variableName], as shared_hooks
  /// `addAppEnvKeys` writes it. Skipped when `app_env.dart` is absent.
  Future<void> _addVariableToAppEnv(String variableName) async {
    final file = File(appEnvFilePath);
    if (!file.existsSync()) return;

    final content = await file.readAsString();
    final camelCase = _toCamelCase(variableName);
    if (content.contains('String get $camelCase =>')) return;

    final newGetter =
        '''

  /// The ${_toTitleCase(variableName)} value for the active flavor.
  static String get $camelCase => Env.$camelCase;
''';

    await file.writeAsString(
      content.replaceFirst(RegExp(r'\}\n$'), '$newGetter}\n'),
    );
  }

  /// Copies `.env.<flavor>` to `.env` so build_runner picks up the values.
  Future<void> _switchFlavor(String flavor) async {
    final sourcePath = path.join(configPackagePath, '.env.$flavor');
    final targetPath = path.join(configPackagePath, '.env');

    final source = File(sourcePath);
    if (!source.existsSync()) {
      _logger.warning(
        '.env.$flavor not found — skipping auto-switch to $flavor.',
      );
      return;
    }

    final contents = source.readAsStringSync();
    File(targetPath).writeAsStringSync(contents);
    _logger.info('Auto-switched env to: $flavor');
  }

  /// Updates the barrel file to export env.dart.
  Future<void> updateBarrelFile() async {
    final barrelPath = path.join(configPackagePath, 'lib', 'app_config.dart');
    final file = File(barrelPath);

    const content = '''
/// Centralized configuration for environment variables and flavor management.
library;

export 'src/env/app_env.dart';
export 'src/env/env.dart';
export 'src/flavor.dart';
''';

    await file.writeAsString(content);
  }

  // Simple case conversion utilities to avoid recase dependency.
  String _toCamelCase(String input) {
    final words = input.split(RegExp(r'[_\s]+'));
    if (words.isEmpty) return input;
    return words.first.toLowerCase() +
        words
            .skip(1)
            .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join();
  }

  String _toPascalCase(String input) {
    final words = input.split(RegExp(r'[_\s]+'));
    return words
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join();
  }

  String _toTitleCase(String input) {
    final words = input.split(RegExp(r'[_\s]+'));
    return words
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String _toConstantCase(String input) {
    // If already CONSTANT_CASE, return as-is
    if (RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(input)) return input;
    // Convert camelCase/PascalCase to CONSTANT_CASE
    return input
        .replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toUpperCase();
  }
}
