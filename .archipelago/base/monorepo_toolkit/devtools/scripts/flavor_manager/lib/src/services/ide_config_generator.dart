import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Writes IDE run configurations for flavor-based Flutter apps: VS Code
/// `.vscode/launch.json` + `.vscode/tasks.json`, JetBrains `.run/*.run.xml`.
///
/// Same output as shared_hooks' `IdeConfigUpdater` (used when a brick adds an
/// app); the workspace's committed files are the reference. Existing entries
/// and files are kept, so user edits survive a regeneration.
class IdeConfigGenerator({
  /// The monorepo root path.
  required final String rootPath,
}) {
  /// Creates a new [IdeConfigGenerator].
  this;

  /// Adds the missing launch entries and `prepare-<flavor>` tasks.
  ///
  /// Returns the path to `launch.json`. A file that is not a plain JSON
  /// object (comments, an array) is left unchanged, and so is `launch.json`
  /// when `tasks.json` is, as its entries run those tasks.
  String generateVsCodeConfig(Map<String, List<String>> appFlavors) {
    final dir = path.join(rootPath, '.vscode');
    final launchPath = path.join(dir, 'launch.json');
    final tasksPath = path.join(dir, 'tasks.json');
    final launch = _readJson(launchPath, '0.2.0', 'configurations');
    final tasksJson = _readJson(tasksPath, '2.0.0', 'tasks');

    if (tasksJson != null) {
      final tasks = tasksJson['tasks'] as List<Map<String, dynamic>>;
      final labels = tasks.map((t) => t['label']).toSet();
      for (final flavor in {for (final f in appFlavors.values) ...f}) {
        if (labels.add('prepare-$flavor')) tasks.add(_prepareTask(flavor));
      }
      _writeJson(tasksPath, tasksJson);
    }

    if (launch != null && tasksJson != null) {
      final configs = launch['configurations'] as List<Map<String, dynamic>>;
      final names = configs.map((c) => c['name']).toSet();
      for (final MapEntry(key: app, value: flavors) in appFlavors.entries) {
        for (final flavor in flavors) {
          for (final mode in _modesFor(flavor)) {
            final config = _launchConfig(app, flavor, mode);
            if (names.add(config['name'])) configs.add(config);
          }
        }
      }
      _writeJson(launchPath, launch);
    } else if (launch != null) {
      stderr.writeln('Left $launchPath unchanged too: its entries run tasks.');
    }

    return launchPath;
  }

  /// Writes the missing `.run/` files. Returns the paths written.
  List<String> generateJetBrainsConfig(Map<String, List<String>> appFlavors) {
    final runDir = Directory(path.join(rootPath, '.run'))
      ..createSync(recursive: true);
    final written = <String>[];
    void write(String name, String content) {
      final file = File(path.join(runDir.path, name));
      if (file.existsSync()) return;
      file.writeAsStringSync(content);
      written.add(file.path);
    }

    for (final MapEntry(key: app, value: flavors) in appFlavors.entries) {
      for (final flavor in flavors) {
        write('prepare-$flavor.run.xml', _prepareXml(flavor));
        for (final mode in _modesFor(flavor)) {
          write(
            '${app}_$flavor${mode == null ? '' : '_$mode'}.run.xml',
            _runXml(app, flavor, mode),
          );
        }
      }
    }
    return written;
  }

  /// Debug, plus profile for development/staging and release for
  /// staging/production.
  static List<String?> _modesFor(String flavor) => [
    null,
    if (flavor == 'development' || flavor == 'staging') 'profile',
    if (flavor == 'staging' || flavor == 'production') 'release',
  ];

  static String _mainFileFor(String flavor) =>
      flavor == 'production' ? 'main.dart' : 'main_$flavor.dart';

  static String _name(String app, String flavor, String? mode) {
    final base = '${_title(app.replaceAll('_', ' '))} - ${_title(flavor)}';
    return mode == null ? base : '$base (${_title(mode)})';
  }

  static Map<String, Object> _launchConfig(
    String app,
    String flavor,
    String? mode,
  ) => {
    'name': _name(app, flavor, mode),
    'request': 'launch',
    'type': 'dart',
    'program': '\${workspaceFolder}/apps/$app/lib/${_mainFileFor(flavor)}',
    'cwd': '\${workspaceFolder}/apps/$app',
    'args': ['--flavor', flavor],
    'flutterMode': ?mode,
    'preLaunchTask': 'prepare-$flavor',
  };

  static Map<String, Object> _prepareTask(String flavor) => {
    'label': 'prepare-$flavor',
    'type': 'shell',
    'command': 'dart run monorepo_toolkit prepare --flavor $flavor',
    'options': {'cwd': r'${workspaceFolder}'},
    'presentation': {'reveal': 'always', 'panel': 'shared'},
  };

  static String _runXml(String app, String flavor, String? mode) =>
      '''
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="${_name(app, flavor, mode)}" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="buildFlavor" value="$flavor" />
    <option name="filePath" value="\$PROJECT_DIR\$/apps/$app/lib/${_mainFileFor(flavor)}" />${mode == null ? '' : '\n    <option name="additionalArgs" value="--$mode" />'}
    <method v="2">
      <option name="RunConfigurationTask" enabled="true" run_configuration_name="prepare-$flavor" run_configuration_type="ShConfigurationType" />
    </method>
  </configuration>
</component>
''';

  static String _prepareXml(String flavor) =>
      '''
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="prepare-$flavor" type="ShConfigurationType">
    <option name="SCRIPT_TEXT" value="dart run monorepo_toolkit prepare --flavor $flavor" />
    <option name="INDEPENDENT_SCRIPT_PATH" value="true" />
    <option name="SCRIPT_PATH" value="" />
    <option name="SCRIPT_OPTIONS" value="" />
    <option name="INDEPENDENT_SCRIPT_WORKING_DIRECTORY" value="true" />
    <option name="SCRIPT_WORKING_DIRECTORY" value="\$PROJECT_DIR\$" />
    <option name="INDEPENDENT_INTERPRETER_PATH" value="true" />
    <option name="INTERPRETER_PATH" value="/bin/sh" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="EXECUTE_IN_TERMINAL" value="true" />
    <option name="EXECUTE_SCRIPT_FILE" value="false" />
    <envs />
    <method v="2" />
  </configuration>
</component>
''';

  static Map<String, dynamic>? _readJson(
    String filePath,
    String version,
    String listKey,
  ) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return {'version': version, listKey: <Map<String, dynamic>>[]};
    }
    try {
      final json = jsonDecode(file.readAsStringSync());
      final list = json is Map<String, dynamic>
          ? json[listKey] ?? <Object?>[]
          : null;
      if (list is List && list.every((e) => e is Map<String, dynamic>)) {
        return (json as Map<String, dynamic>)
          ..[listKey] = list.cast<Map<String, dynamic>>().toList();
      }
    } on FormatException {
      // Reported below.
    }
    stderr.writeln(
      'Left $filePath unchanged: it is not plain JSON with a "$listKey" list.',
    );
    return null;
  }

  static void _writeJson(String filePath, Map<String, dynamic> json) {
    File(filePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      );
  }

  static String _title(String text) => text
      .split(' ')
      .map(
        (w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}
