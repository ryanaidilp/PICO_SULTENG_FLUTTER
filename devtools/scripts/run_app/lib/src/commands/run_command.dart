import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:prepare/prepare.dart';
import 'package:run_app/src/models/app_config.dart';
import 'package:run_app/src/models/device_info.dart';
import 'package:run_app/src/utils/device_scanner.dart';
import 'package:run_app/src/utils/flavor_reader.dart';
import 'package:shared_scripts/shared_scripts.dart';

/// Command to run a Flutter app with interactive flavor and device selection.
///
/// Usage (interactive):
/// ```bash
/// monorepo_toolkit run
/// ```
///
/// Usage (non-interactive / CI):
/// ```bash
/// monorepo_toolkit run --app pico --flavor development --device emulator-5554
/// ```
class RunCommand({CliLogger? logger}) extends Command<int> {
  /// Creates a new [RunCommand].
  this {
    argParser
      ..addOption(
        'app',
        abbr: 'a',
        help: 'The app to run (directory name inside apps/).',
      )
      ..addOption(
        'flavor',
        abbr: 'f',
        help: 'The flavor to use (e.g. development, staging, production).',
      )
      ..addOption(
        'device',
        abbr: 'd',
        help: 'The device ID to run on (from `flutter devices`).',
      )
      ..addFlag(
        'prepare',
        help:
            'Prepare the workspace (env switch + envied regen + build-prepare) '
            'for the selected flavor before launching. Use --no-prepare to '
            'skip.',
        defaultsTo: true,
      );
  }

  final CliLogger _logger = logger ?? CliLogger();

  @override
  String get name => 'run';

  @override
  String get description =>
      'Run a Flutter app with interactive flavor and device selection.';

  @override
  String get invocation =>
      'monorepo_toolkit run [--app <name>] [--flavor <flavor>] [--device <id>]';

  @override
  Future<int> run() async {
    // --- 1. Resolve apps from flavors.yaml ---
    final List<AppConfig> apps;
    try {
      apps = FlavorReader.readApps();
    } on FlavorReaderException catch (e) {
      _logger.error(e.message);
      return 1;
    }

    if (apps.isEmpty) {
      _logger.error(
        'No apps found in flavors.yaml. '
        'Add apps under the `apps:` key and try again.',
      );
      return 1;
    }

    // --- 2. Select app ---
    final AppConfig selectedApp;
    final appArg = argResults?['app'] as String?;
    if (appArg != null) {
      final match = apps.where((a) => a.name == appArg).toList();
      if (match.isEmpty) {
        _logger.error(
          'App "$appArg" not found in flavors.yaml. '
          'Available: ${apps.map((a) => a.name).join(', ')}',
        );
        return 1;
      }
      selectedApp = match.first;
    } else if (apps.length == 1) {
      selectedApp = apps.first;
      _logger.info('\n📱 App: ${selectedApp.name}');
    } else {
      selectedApp = _promptApp(apps);
    }

    // --- 3. Select flavor ---
    final String selectedFlavor;
    final flavorArg = argResults?['flavor'] as String?;
    if (flavorArg != null) {
      if (!selectedApp.flavors.contains(flavorArg)) {
        _logger.error(
          'Flavor "$flavorArg" not found for app "${selectedApp.name}". '
          'Available: ${selectedApp.flavors.join(', ')}',
        );
        return 1;
      }
      selectedFlavor = flavorArg;
    } else {
      selectedFlavor = _promptFlavor(selectedApp.flavors);
    }

    // --- 4. Resolve connected devices ---
    _logger.progress('Scanning for connected devices...');
    final devices = await DeviceScanner.getDevices();

    if (devices.isEmpty) {
      _logger.error('No devices connected.\n');
      _logger.info('Start a device first:');
      _logger.info('  iOS Simulator:  open -a Simulator');
      _logger.info('  Android:        emulator -avd <name>');
      _logger.info('  Chrome:         flutter run -d chrome');
      _logger.info('\nThen run this command again.');
      return 1;
    }

    // --- 5. Select device ---
    final DeviceInfo selectedDevice;
    final deviceArg = argResults?['device'] as String?;
    if (deviceArg != null) {
      final match = devices.where((d) => d.id == deviceArg).toList();
      if (match.isEmpty) {
        _logger.error(
          'Device "$deviceArg" not found. '
          'Connected devices: ${devices.map((d) => d.id).join(', ')}',
        );
        return 1;
      }
      selectedDevice = match.first;
    } else if (devices.length == 1) {
      selectedDevice = devices.first;
    } else {
      selectedDevice = _promptDevice(devices);
    }

    // --- 6. Resolve the app working directory ---
    final rootPath = MonorepoFinder.requireRoot();
    final appDir = Directory(path.join(rootPath, 'apps', selectedApp.name));

    if (!appDir.existsSync()) {
      _logger.error(
        'App directory not found: ${appDir.path}. '
        'Expected Flutter app at apps/${selectedApp.name}.',
      );
      return 1;
    }

    // --- 7. Prepare the workspace for the selected flavor ---
    // Interactive run is always debug. Skippable via --no-prepare.
    if (argResults?['prepare'] as bool? ?? true) {
      _logger.info('');
      _logger.progress('Preparing $selectedFlavor…');
      try {
        await prepareWorkspace(
          rootPath: rootPath,
          flavor: selectedFlavor,
          mode: 'debug',
          logger: _logger,
        );
      } on PrepareException catch (e) {
        _logger.error(e.message);
        return 1;
      }
    }

    // --- 8. Spawn flutter run ---
    // Production uses main.dart, other flavors use main_{flavor}.dart
    final entryPoint = selectedFlavor == 'production'
        ? 'lib/main.dart'
        : 'lib/main_$selectedFlavor.dart';

    // Verify entry point exists
    final entryFile = File(path.join(appDir.path, entryPoint));
    if (!entryFile.existsSync()) {
      _logger.error(
        'Entry point not found: ${entryFile.path}\n'
        'Expected main file for "$selectedFlavor" flavor.',
      );
      return 1;
    }

    final flutterArgs = [
      'run',
      '--flavor',
      selectedFlavor,
      '--target',
      entryPoint,
      '-d',
      selectedDevice.id,
    ];

    _logger.info('');
    _logger.success(
      'Running ${selectedApp.name} ($selectedFlavor) on ${selectedDevice.displayLabel}',
    );
    _logger.info('  flutter ${flutterArgs.join(' ')}');
    _logger.info('');

    final process = await Process.start(
      'flutter',
      flutterArgs,
      workingDirectory: appDir.path,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );

    return await process.exitCode;
  }

  // ---------------------------------------------------------------------------
  // Private prompt helpers
  // ---------------------------------------------------------------------------

  AppConfig _promptApp(List<AppConfig> apps) {
    stdout.writeln('\u{1F4F1} Available apps:');
    for (var i = 0; i < apps.length; i++) {
      stdout.writeln('  ${i + 1}. ${apps[i].name}');
    }
    stdout.write('\nSelect app [1]: ');

    final input = stdin.readLineSync()?.trim() ?? '';
    final index = int.tryParse(input.isEmpty ? '1' : input);

    if (index == null || index < 1 || index > apps.length) {
      _logger.warning('Invalid selection, defaulting to 1.');
      return apps.first;
    }
    return apps[index - 1];
  }

  String _promptFlavor(List<String> flavors) {
    stdout.writeln('\n\u{1F3A8} Available flavors:');
    for (var i = 0; i < flavors.length; i++) {
      stdout.writeln('  ${i + 1}. ${flavors[i]}');
    }
    stdout.write('\nSelect flavor [1]: ');

    final input = stdin.readLineSync()?.trim() ?? '';
    final index = int.tryParse(input.isEmpty ? '1' : input);

    if (index == null || index < 1 || index > flavors.length) {
      _logger.warning('Invalid selection, defaulting to 1.');
      return flavors.first;
    }
    return flavors[index - 1];
  }

  DeviceInfo _promptDevice(List<DeviceInfo> devices) {
    stdout.writeln('\n\u{1F4F2} Connected devices:');
    for (var i = 0; i < devices.length; i++) {
      stdout.writeln('  ${i + 1}. ${devices[i].displayLabel}');
    }
    stdout.write('\nSelect device [1]: ');

    final input = stdin.readLineSync()?.trim() ?? '';
    final index = int.tryParse(input.isEmpty ? '1' : input);

    if (index == null || index < 1 || index > devices.length) {
      _logger.warning('Invalid selection, defaulting to 1.');
      return devices.first;
    }
    return devices[index - 1];
  }
}
