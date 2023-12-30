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
            iconColor: context.picoColors.semantic.warning,
            bgColor: context.picoColors.semantic.warning.shade100,
            iconData: Icons.local_hospital_rounded,
            label: context.i10n.card_case_label.under_treatment,
          ),
        cured => CaseData(
            iconColor: context.picoColors.semantic.success,
            bgColor: context.picoColors.semantic.success.shade100,
            iconData: Icons.check_rounded,
            label: context.i10n.card_case_label.recovered,
          ),
        death => CaseData(
            iconColor: context.picoColors.semantic.error,
            bgColor: context.picoColors.semantic.error.shade100,
            iconData: Icons.close_rounded,
            label: context.i10n.card_case_label.deceased,
          ),
      };
}
