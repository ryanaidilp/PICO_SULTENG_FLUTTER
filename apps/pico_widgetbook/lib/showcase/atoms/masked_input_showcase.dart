import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the masked input showcase component for Widgetbook.
WidgetbookComponent maskedInputShowcaseComponent() => WidgetbookComponent(
  name: 'Masked Input',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoMaskedInput',
      builder: _buildPicoMaskedInputUseCase,
    ),
  ],
);

/// Preset mask patterns for the dropdown.
enum _MaskPreset(final String label, final String mask, final String hint) {
  date('Date', '##/##/####', 'DD/MM/YYYY'),
  phone('Phone', '### ### ####', '081 234 5678'),
  card('Card Number', '#### #### #### ####', '1234 5678 9012 3456'),
  idNumber('ID Number (KTP)', '################', '3201234567890001'),
  custom('Custom', '##-##-##', ''),
}

Widget _buildPicoMaskedInputUseCase(BuildContext context) {
  final preset = context.knobs.object.dropdown<_MaskPreset>(
    label: 'Mask Preset',
    options: _MaskPreset.values,
    initialOption: _MaskPreset.date,
    labelBuilder: (p) => p.label,
  );

  final customMask = context.knobs.string(
    label: 'Custom Mask',
    initialValue: '##-##-##',
  );

  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Date of Birth',
  );

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final hasError = context.knobs.boolean(label: 'Show Error');

  final hasPrefixIcon = context.knobs.boolean(label: 'Prefix Icon');

  final effectiveMask = preset == _MaskPreset.custom ? customMask : preset.mask;
  final effectiveHint = preset == _MaskPreset.custom ? '' : preset.hint;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 320,
        child: PicoMaskedInput(
          key: ValueKey(effectiveMask),
          mask: effectiveMask,
          label: label.isEmpty ? null : label,
          hint: effectiveHint.isEmpty ? null : effectiveHint,
          enabled: !isDisabled,
          errorText: hasError ? 'Invalid format' : null,
          prefixIcon: hasPrefixIcon ? const Icon(Icons.calendar_today) : null,
          keyboardType: TextInputType.number,
        ),
      ),
    ),
  );
}
