import 'dart:io';

import 'package:asset_optimizer/src/models/asset_optimizer_config.dart';
import 'package:asset_optimizer/src/services/optimizers/optimizer.dart';

/// Optimizer for JPEG files using jpegoptim.
class JpegOptimizer({required final JpegConfig config}) extends Optimizer {
  @override
  String get name => 'jpegoptim';

  @override
  List<String> get supportedExtensions => ['jpg', 'jpeg'];

  @override
  String get installInstructions =>
      'brew install jpegoptim (macOS) or apt-get install jpegoptim';

  @override
  Future<bool> isInstalled() async {
    try {
      final result = await runCommand('jpegoptim', ['--version']);
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
        '--max=${config.quality}', // Maximum quality
        '--strip-all', // Strip all metadata
        '--all-progressive', // Convert to progressive
        file.path,
      ];

      final result = await runCommand('jpegoptim', args);

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
