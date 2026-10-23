import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the input showcase component for Widgetbook.
WidgetbookComponent inputShowcaseComponent() => WidgetbookComponent(
  name: 'Inputs',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoTextField',
      builder: _buildPicoTextFieldUseCase,
    ),
    WidgetbookUseCase(name: 'PicoCheckbox', builder: _buildPicoCheckboxUseCase),
  ],
);

Widget _buildPicoTextFieldUseCase(BuildContext context) {
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

  final label = context.knobs.string(label: 'Label', initialValue: 'Email');

  final hint = context.knobs.string(
    label: 'Hint',
    initialValue: 'Enter your email',
  );

  final helperText = context.knobs.string(label: 'Helper Text');

  final errorText = context.knobs.string(label: 'Error Text');

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final isRequired = context.knobs.boolean(label: 'Required');

  final hasPrefixIcon = context.knobs.boolean(label: 'Prefix Icon');

  final hasSuffixIcon = context.knobs.boolean(label: 'Suffix Icon');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 320,
        child: PicoTextField(
          variant: variant,
          size: size,
          label: label.isEmpty ? null : label,
          hint: hint.isEmpty ? null : hint,
          helperText: helperText.isEmpty ? null : helperText,
          errorText: errorText.isEmpty ? null : errorText,
          enabled: !isDisabled,
          isRequired: isRequired,
          prefixIcon: hasPrefixIcon ? const Icon(Icons.email_outlined) : null,
          suffixIcon: hasSuffixIcon ? const Icon(Icons.check_circle) : null,
        ),
      ),
    ),
  );
}

Widget _buildPicoCheckboxUseCase(BuildContext context) {
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Accept terms and conditions',
  );

  final isChecked = context.knobs.boolean(label: 'Checked');

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final isError = context.knobs.boolean(label: 'Error State');

  final tristate = context.knobs.boolean(label: 'Tristate');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoCheckbox(
        value: tristate ? (isChecked ? true : null) : isChecked,
        onChanged: (value) {},
        label: label.isEmpty ? null : label,
        isDisabled: isDisabled,
        isError: isError,
        tristate: tristate,
      ),
    ),
  );
}
