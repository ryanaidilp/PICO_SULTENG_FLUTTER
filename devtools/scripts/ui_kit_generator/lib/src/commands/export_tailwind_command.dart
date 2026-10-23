import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_scripts/shared_scripts.dart';
import 'package:ui_kit_generator/src/tailwind/tailwind_preset.dart';
import 'package:ui_kit_generator/src/tailwind/ui_kit_tokens.dart';

/// Writes the app's real ui_kit tokens as a Tailwind preset for web content
/// (mini-apps) that must match the host theme.
class ExportTailwindCommand() extends Command<int> {
  /// Creates a new [ExportTailwindCommand].
  this {
    argParser
      ..addOption(
        'ui-kit-path',
        help: 'Path to the UI Kit package.',
        defaultsTo: 'packages/pico_ui_kit',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Tailwind v4 CSS output path (relative to the workspace root).',
        defaultsTo: 'build/theme/tailwind-theme.css',
      )
      ..addOption(
        'v3-config',
        help: 'Also write a Tailwind v3 theme.extend module to this path.',
      );
  }

  @override
  String get name => 'export-tailwind';

  @override
  String get description =>
      'Export UI Kit tokens as a Tailwind v4 preset (CSS variables, light + '
      'dark).';

  @override
  Future<int> run() async {
    final logger = CliLogger();
    try {
      final root = MonorepoFinder.requireRoot();
      final tokens = readUiKitTokens(
        p.join(root, argResults!['ui-kit-path'] as String),
      );
      final outputs = {
        argResults!['output'] as String: renderTailwindV4(tokens),
        if (argResults!['v3-config'] case final String v3)
          v3: renderTailwindV3(tokens),
      };
      for (final e in outputs.entries) {
        final file = File(p.join(root, e.key));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(e.value);
        logger.success('Generated: ${e.key}');
      }
      return 0;
    } on Exception catch (e) {
      logger.error('Failed to export Tailwind preset: $e');
      return 1;
    }
  }
}
