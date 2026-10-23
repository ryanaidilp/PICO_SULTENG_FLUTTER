import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Persisted record of the flavor/mode the workspace was last prepared for.
///
/// Written to `.prepare.state.json` at the workspace root after a successful
/// prepare so repeat launches for the same `(flavor, mode)` can short-circuit
/// the expensive envied regeneration. The file is gitignored — local-only
/// state, never committed.
class const PrepareState({
  /// The flavor the workspace was prepared for (e.g. `development`).
  required final String flavor,

  /// The swap mode the workspace was prepared for (`auto`, `debug` or
  /// `release`).
  required final String mode,
}) {
  /// Creates a [PrepareState].
  this;

  /// File name written at the workspace root.
  static const stateFileName = '.prepare.state.json';

  /// Creates a [PrepareState] from JSON.
  factory fromJson(Map<String, dynamic> json) => PrepareState(
    flavor: json['flavor'] as String,
    mode: json['mode'] as String,
  );

  /// Loads state from [rootPath]. Returns null when no state file exists or
  /// the file is malformed.
  static PrepareState? load(String rootPath) {
    final file = File(p.join(rootPath, stateFileName));
    if (!file.existsSync()) return null;

    try {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return PrepareState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Writes [state] to [rootPath]. Overwrites any existing state file.
  static void save(String rootPath, PrepareState state) {
    final file = File(p.join(rootPath, stateFileName));
    file.writeAsStringSync(jsonEncode(state.toJson()));
  }

  /// Serializes as JSON.
  Map<String, dynamic> toJson() => {'flavor': flavor, 'mode': mode};

  /// Whether this state matches the requested [flavor]/[mode].
  bool matches(String flavor, String mode) =>
      this.flavor == flavor && this.mode == mode;
}
