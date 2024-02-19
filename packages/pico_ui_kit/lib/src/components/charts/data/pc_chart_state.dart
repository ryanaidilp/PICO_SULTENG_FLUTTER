import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

enum PCChartState {
  success,
  loading,
  failed;

  Color lineColor(
    BuildContext context, {
    Color? lineColor,
  }) =>
      switch (this) {
        loading => context.picoColors.outline.neutral.subtle,
        _ => lineColor ?? context.picoColors.semantic.primary,
      };

  Color dotColor(
    BuildContext context, {
    Color? dotColor,
  }) =>
      switch (this) {
        loading => context.picoColors.icon.neutral.subtle,
        _ => dotColor ?? context.picoColors.icon.semantic.primary,
      };

  EdgeInsets get padding => switch (this) {
        loading => const EdgeInsets.symmetric(
            vertical: PCSpacing.s16,
          ),
        _ => EdgeInsets.zero,
      };
}
