import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the button showcase component for Widgetbook.
WidgetbookComponent buttonShowcaseComponent() => WidgetbookComponent(
  name: 'Buttons',
  useCases: [
    WidgetbookUseCase(name: 'PicoButton', builder: _buildPicoButtonUseCase),
  ],
);

Widget _buildPicoButtonUseCase(BuildContext context) {
  final style = context.knobs.object.dropdown<PicoButtonStyle>(
    label: 'Style',
    options: PicoButtonStyle.values,
    initialOption: PicoButtonStyle.filled,
    labelBuilder: (style) => style.name,
  );

  final color = context.knobs.object.dropdown<PicoButtonColor>(
    label: 'Color',
    options: PicoButtonColor.values,
    initialOption: PicoButtonColor.primary,
    labelBuilder: (color) => color.name,
  );

  final size = context.knobs.object.dropdown<PicoButtonSize>(
    label: 'Size',
    options: PicoButtonSize.values,
    initialOption: PicoButtonSize.md,
    labelBuilder: (size) => size.name,
  );

  final label = context.knobs.string(label: 'Label', initialValue: 'Button');

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final isLoading = context.knobs.boolean(label: 'Loading');

  final isExpanded = context.knobs.boolean(label: 'Expanded');

  final hasLeadingIcon = context.knobs.boolean(label: 'Leading Icon');

  final hasTrailingIcon = context.knobs.boolean(label: 'Trailing Icon');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoButton(
        label: label,
        style: style,
        color: color,
        size: size,
        onPressed: isDisabled ? null : () {},
        isLoading: isLoading,
        isExpanded: isExpanded,
        leadingIcon: hasLeadingIcon ? Icons.add : null,
        trailingIcon: hasTrailingIcon ? Icons.arrow_forward : null,
      ),
    ),
  );
}
