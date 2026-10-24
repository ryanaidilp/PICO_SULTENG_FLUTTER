import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Backup of a single file's pre-swap content.
class const FileBackup({
  /// Path relative to the workspace root.
  required final String path,

  /// Original content before the swap was applied.
  required final String content,

  /// Content right after the swap. Lets a later `debug` run tell whether the
  /// file was edited since, before restoring [content] over it.
  final String? swapped,
}) {
  /// Creates a [FileBackup].
  this;

  /// Creates a [FileBackup] from JSON.
  factory fromJson(Map<String, dynamic> json) => FileBackup(
    path: json['path'] as String,
    content: json['content'] as String,
    swapped: json['swapped'] as String?,
  );

  /// Serializes the backup as JSON.
  Map<String, dynamic> toJson() => {
    'path': path,
    'content': content,
    if (swapped != null) 'swapped': swapped,
  };
}

/// Persisted record of an active build_prepare swap.
///
/// Written to `.build_prepare.state.json` at the workspace root after a
/// swap so `build_prepare --restore` can reverse it. The file is
/// gitignored — local-only state, never committed.
class const BuildPrepareState({
  /// Snapshots of every file mutated by the swap.
  required final List<FileBackup> files,
}) {
  /// Creates a [BuildPrepareState].
  this;

  /// File name written at the workspace root.
  static const stateFileName = '.build_prepare.state.json';

  /// Loads state from [rootPath]. Returns null when no state file exists.
  static BuildPrepareState? load(String rootPath) {
    final file = File(p.join(rootPath, stateFileName));
    if (!file.existsSync()) return null;

    try {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final filesJson = decoded['files'] as List<dynamic>?;
      if (filesJson == null) return const BuildPrepareState(files: []);

      return BuildPrepareState(
        files: filesJson
            .cast<Map<String, dynamic>>()
            .map(FileBackup.fromJson)
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  /// Writes [state] to [rootPath]. Overwrites any existing state file.
  static void save(String rootPath, BuildPrepareState state) {
    final file = File(p.join(rootPath, stateFileName));
    file.writeAsStringSync(jsonEncode(state.toJson()));
  }

  /// Deletes the state file at [rootPath]. No-op if absent.
  static void delete(String rootPath) {
    final file = File(p.join(rootPath, stateFileName));
    if (file.existsSync()) file.deleteSync();
  }

  /// Whether a state file exists at [rootPath].
  static bool exists(String rootPath) =>
      File(p.join(rootPath, stateFileName)).existsSync();

  /// Serializes as JSON.
  Map<String, dynamic> toJson() => {
    'files': files.map((f) => f.toJson()).toList(),
  };
}
