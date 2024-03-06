import 'package:flutter/widgets.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

enum PicoTestStatus {
  reactive,
  nonReactive,
  invalid,
  onProcess;

  Color textColor(BuildContext context) => switch (this) {
        invalid => context.picoColors.text.semantic.error,
        _ => context.picoColors.text.neutral.main,
      };

  String label(BuildContext context) => switch (this) {
        reactive => context.translations.statistics.cardLabel.caseType.reactive,
        nonReactive =>
          context.translations.statistics.cardLabel.caseType.nonReactive,
        invalid => context.translations.statistics.cardLabel.caseType.invalid,
        onProcess => context.translations.statistics.cardLabel.caseType.process,
      };
}
