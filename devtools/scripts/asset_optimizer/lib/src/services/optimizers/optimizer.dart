import 'dart:io';

import 'package:asset_optimizer/src/models/asset_optimizer_config.dart';

/// Base interface for asset optimizers.
abstract class Optimizer() {
  /// The name of the optimizer (e.g., 'svgo', 'oxipng').
  String get name;

  /// The file extensions this optimizer handles.
  List<String> get supportedExtensions;

  /// Check if the required tool is installed.
  Future<bool> isInstalled();

  /// Get the installation instructions.
  String get installInstructions;

  /// Optimize a single file.
  Future<OptimizationResult> optimize(File file);

  /// Check if a file is supported by this optimizer.
  bool supportsFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return supportedExtensions.contains(ext);
  }

  /// Run a command and capture output.
  Future<ProcessResult> runCommand(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async => await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
}
