import 'dart:io';

import 'package:path/path.dart' as path;

/// Service for managing barrel files in the dependencies package.
class const BarrelFileService({
  /// Path to the lib directory of the dependencies package.
  required final String dependenciesLibPath,
}) {
  /// Creates a new [BarrelFileService].
  this;

  /// Gets all existing barrel files (excluding dependencies.dart).
  List<String> getExistingBarrelFiles() {
    final libDir = Directory(dependenciesLibPath);
    if (!libDir.existsSync()) return [];

    return libDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => path.basenameWithoutExtension(file.path))
        .where((name) => name != 'dependencies')
        .toList()
      ..sort();
  }

  /// Checks if a barrel file exists.
  bool barrelFileExists(String category) {
    final file = File(path.join(dependenciesLibPath, '$category.dart'));
    return file.existsSync();
  }

  /// Creates a new barrel file with the given category name.
  Future<void> createBarrelFile({
    required String category,
    required String description,
  }) async {
    final file = File(path.join(dependenciesLibPath, '$category.dart'));
    final content =
        '''
/// $description exports.
library;
''';
    await file.writeAsString(content);
  }

  /// Adds an export statement to a barrel file.
  Future<void> addExportToBarrelFile({
    required String category,
    required String packageName,
  }) async {
    final file = File(path.join(dependenciesLibPath, '$category.dart'));
    if (!file.existsSync()) {
      throw StateError('Barrel file "$category.dart" does not exist.');
    }

    final content = await file.readAsString();
    final exportStatement = "export 'package:$packageName/$packageName.dart';";

    // Check if export already exists
    if (content.contains(exportStatement)) {
      return;
    }

    // Add export statement at the end
    final updatedContent = '$content\n$exportStatement\n';
    await file.writeAsString(updatedContent);
  }

  /// Updates dependencies.dart to export a barrel file.
  Future<void> addBarrelToDependencies(String category) async {
    final dependenciesFile = File(
      path.join(dependenciesLibPath, 'dependencies.dart'),
    );
    if (!dependenciesFile.existsSync()) {
      throw StateError('dependencies.dart does not exist.');
    }

    final content = await dependenciesFile.readAsString();
    final exportStatement = "export '$category.dart';";

    // Check if export already exists
    if (content.contains(exportStatement)) {
      return;
    }

    // Add export statement at the end
    final updatedContent = '$content\n$exportStatement\n';
    await dependenciesFile.writeAsString(updatedContent);
  }

  /// Removes export statements for a package from all barrel files.
  Future<void> removeExportFromAllBarrelFiles({
    required String packageName,
  }) async {
    final barrelFiles = getExistingBarrelFiles();
    final exportPattern = RegExp("export 'package:$packageName/.*';\\n?");

    for (final category in barrelFiles) {
      final file = File(path.join(dependenciesLibPath, '$category.dart'));
      if (!file.existsSync()) continue;

      final content = await file.readAsString();
      if (exportPattern.hasMatch(content)) {
        final updatedContent = content.replaceAll(exportPattern, '');
        await file.writeAsString(updatedContent);
      }
    }
  }
}
