import 'package:flutter/widgets.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/style/styles.dart';

enum PicoTestStatus {
  reactive,
  nonReactive,
  invalid,
  onProcess;

  Color textColor(BuildContext context) => switch (this) {
        invalid => PicoColors.error.shade400,
        _ => context.picoColors.text.main,
      };

  String label(BuildContext context) => switch (this) {
        reactive => context.i10n.card_case_label.reactive,
        nonReactive => context.i10n.card_case_label.non_reactive,
        invalid => context.i10n.card_case_label.invalid,
        onProcess => context.i10n.card_case_label.process,
      };
}
