import 'dart:convert';
import 'dart:io';

/// Manages installed UI Kit components via `ui_kit_components.json`.
class UiKitRegistry({
  /// The path to the JSON registry file.
  required final String filePath,
}) {
  /// Creates a new [UiKitRegistry].
  this;

  /// Current version of the registry format.
  static const String currentVersion = '1.0.0';

  /// Returns the set of installed component names.
  Future<Set<String>> getInstalled() async {
    final data = await _readRegistry();
    final installed =
        (data['installed'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        <String>{};
    return installed;
  }

  /// Adds a component to the installed list.
  Future<void> addInstalled(String component) async {
    final data = await _readRegistry();
    final installed = _getInstalledList(data);

    if (installed.contains(component)) return;

    installed
      ..add(component)
      ..sort();
    data['installed'] = installed;

    await _writeRegistry(data);
  }

  /// Removes a component from the installed list.
  Future<void> removeInstalled(String component) async {
    final data = await _readRegistry();
    final installed = _getInstalledList(data);

    if (!installed.remove(component)) return;

    data['installed'] = installed;
    await _writeRegistry(data);
  }

  /// Returns `true` if the given component is installed.
  Future<bool> isInstalled(String component) async {
    final installed = await getInstalled();
    return installed.contains(component);
  }

  /// Returns custom components from the registry.
  Future<List<Map<String, dynamic>>> getCustomComponents() async {
    final data = await _readRegistry();
    final customList = data['custom'] as List<dynamic>? ?? [];
    return customList.cast<Map<String, dynamic>>();
  }

  /// Adds a custom component to the registry.
  Future<void> addCustomComponent(Map<String, dynamic> component) async {
    final data = await _readRegistry();
    final customList = _getCustomList(data);

    customList.removeWhere((c) => c['name'] == component['name']);
    customList
      ..add(component)
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    data['custom'] = customList;

    await _writeRegistry(data);
  }

  /// Removes a custom component from the registry.
  Future<void> removeCustomComponent(String name) async {
    final data = await _readRegistry();
    final customList = _getCustomList(data);

    customList.removeWhere((c) => c['name'] == name);
    data['custom'] = customList;

    await _writeRegistry(data);
  }

  Future<Map<String, dynamic>> _readRegistry() async {
    final file = File(filePath);
    if (!file.existsSync()) return _createEmptyRegistry();

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return _createEmptyRegistry();
      return jsonDecode(content) as Map<String, dynamic>;
    } on FormatException {
      return _createEmptyRegistry();
    }
  }

  Future<void> _writeRegistry(Map<String, dynamic> data) async {
    final file = File(filePath);
    final directory = file.parent;

    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    const encoder = JsonEncoder.withIndent('  ');
    final jsonContent = encoder.convert(data);
    await file.writeAsString('$jsonContent\n');
  }

  Map<String, dynamic> _createEmptyRegistry() => {
    'version': currentVersion,
    'installed': <String>[],
    'custom': <Map<String, dynamic>>[],
  };

  List<String> _getInstalledList(Map<String, dynamic> data) =>
      (data['installed'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      <String>[];

  List<Map<String, dynamic>> _getCustomList(Map<String, dynamic> data) =>
      (data['custom'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      <Map<String, dynamic>>[];
}
