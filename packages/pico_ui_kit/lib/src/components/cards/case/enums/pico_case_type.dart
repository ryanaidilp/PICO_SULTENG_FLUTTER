import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/cards/case/models/case_data.dart';

enum PicoCaseType {
  treatment,
  cured,
  death;

  CaseData data(BuildContext context) => switch (this) {
        treatment => CaseData(
            iconColor: context.picoColors.icon.semantic.warning,
            bgColor:
                context.picoColors.semantic.warning.shade100.withOpacity(0.4),
            iconData: PicoIcons.hospitalBedOutline,
            label: context.i10n.card_case_label.under_treatment,
          ),
        cured => CaseData(
            iconColor: context.picoColors.icon.semantic.success,
            bgColor:
                context.picoColors.semantic.success.shade100.withOpacity(0.4),
            iconData: PicoIcons.selfIsolation,
            label: context.i10n.card_case_label.recovered,
          ),
        death => CaseData(
            iconColor: context.picoColors.icon.semantic.error,
            bgColor:
                context.picoColors.semantic.error.shade100.withOpacity(0.4),
            iconData: PicoIcons.cemetery,
            label: context.i10n.card_case_label.deceased,
          ),
      };
}
