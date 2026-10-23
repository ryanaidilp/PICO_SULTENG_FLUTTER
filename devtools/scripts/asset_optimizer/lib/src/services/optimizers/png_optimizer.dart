import 'dart:io';

import 'package:asset_optimizer/src/models/asset_optimizer_config.dart';
import 'package:asset_optimizer/src/services/optimizers/optimizer.dart';

/// Optimizer for PNG files using oxipng.
class PngOptimizer({required final PngConfig config}) extends Optimizer {
  @override
  String get name => 'oxipng';

  @override
  List<String> get supportedExtensions => ['png'];

  @override
  String get installInstructions =>
      'brew install oxipng (macOS) or cargo install oxipng';

  @override
  Future<bool> isInstalled() async {
    try {
      final result = await runCommand('oxipng', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OptimizationResult> optimize(File file) async {
    final originalSize = await file.length();

    try {
      final args = <String>[
        '-o',
        config.level.toString(), // Optimization level (1-6)
        '--strip',
        'safe', // Strip safe metadata
        file.path,
      ];

      final result = await runCommand('oxipng', args);

      if (result.exitCode != 0) {
        return OptimizationResult(
          filePath: file.path,
          originalSize: originalSize,
          optimizedSize: originalSize,
          success: false,
          error: result.stderr.toString(),
        );
      }

      final optimizedSize = await file.length();

      return OptimizationResult(
        filePath: file.path,
        originalSize: originalSize,
        optimizedSize: optimizedSize,
        success: true,
      );
    } catch (e) {
      return OptimizationResult(
        filePath: file.path,
        originalSize: originalSize,
        optimizedSize: originalSize,
        success: false,
        error: e.toString(),
      );
    }
  }
}
