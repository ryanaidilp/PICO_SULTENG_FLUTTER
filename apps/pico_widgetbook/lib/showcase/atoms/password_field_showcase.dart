import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the password field showcase component for Widgetbook.
WidgetbookComponent passwordFieldShowcaseComponent() => WidgetbookComponent(
  name: 'Password Field',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoPasswordField',
      builder: _buildPicoPasswordFieldUseCase,
    ),
  ],
);

Widget _buildPicoPasswordFieldUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown<PicoTextFieldVariant>(
    label: 'Variant',
    options: PicoTextFieldVariant.values,
    initialOption: PicoTextFieldVariant.bordered,
    labelBuilder: (variant) => variant.name,
  );

  final size = context.knobs.object.dropdown<PicoTextFieldSize>(
    label: 'Size',
    options: PicoTextFieldSize.values,
    initialOption: PicoTextFieldSize.md,
    labelBuilder: (size) => size.name,
  );

  final label = context.knobs.string(label: 'Label', initialValue: 'Password');

  final hint = context.knobs.string(
    label: 'Hint',
    initialValue: 'Enter your password',
  );

  final helperText = context.knobs.string(label: 'Helper Text');

  final errorText = context.knobs.string(label: 'Error Text');

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final isRequired = context.knobs.boolean(label: 'Required');

  final showStrengthIndicator = context.knobs.boolean(
    label: 'Show Strength Indicator',
  );

  final initiallyObscured = context.knobs.boolean(
    label: 'Initially Obscured',
    initialValue: true,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 320,
        child: PicoPasswordField(
          variant: variant,
          size: size,
          label: label.isEmpty ? null : label,
          hint: hint.isEmpty ? null : hint,
          helperText: helperText.isEmpty ? null : helperText,
          errorText: errorText.isEmpty ? null : errorText,
          enabled: !isDisabled,
          isRequired: isRequired,
          showStrengthIndicator: showStrengthIndicator,
          initiallyObscured: initiallyObscured,
        ),
      ),
    ),
  );
}
