import 'dart:io';

import 'package:asset_optimizer/src/models/asset_optimizer_config.dart';
import 'package:asset_optimizer/src/services/optimizers/optimizer.dart';

/// Optimizer for SVG files using svgo.
class SvgOptimizer({required final SvgConfig config}) extends Optimizer {
  @override
  String get name => 'svgo';

  @override
  List<String> get supportedExtensions => ['svg'];

  @override
  String get installInstructions => 'npm install -g svgo';

  @override
  Future<bool> isInstalled() async {
    try {
      final result = await runCommand('svgo', ['--version']);
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
        file.path,
        '-o',
        file.path, // Overwrite in place
      ];

      for (final plugin in config.disablePlugins) {
        args.addAll([
          '--config',
          '{"plugins":[{"name":"$plugin","active":false}]}',
        ]);
      }

      final result = await runCommand('svgo', args);

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
