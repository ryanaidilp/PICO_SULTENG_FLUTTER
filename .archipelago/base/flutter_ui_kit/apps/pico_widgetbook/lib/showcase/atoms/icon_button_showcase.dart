import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the icon button showcase component for Widgetbook.
WidgetbookComponent iconButtonShowcaseComponent() => WidgetbookComponent(
  name: 'Icon Buttons',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoIconButton',
      builder: _buildPicoIconButtonUseCase,
    ),
  ],
);

Widget _buildPicoIconButtonUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown<PicoIconButtonVariant>(
    label: 'Variant',
    options: PicoIconButtonVariant.values,
    initialOption: PicoIconButtonVariant.filled,
    labelBuilder: (variant) => variant.name,
  );

  final size = context.knobs.object.dropdown<PicoIconButtonSize>(
    label: 'Size',
    options: PicoIconButtonSize.values,
    initialOption: PicoIconButtonSize.md,
    labelBuilder: (size) => size.name,
  );

  final isDisabled = context.knobs.boolean(label: 'Disabled');

  final isLoading = context.knobs.boolean(label: 'Loading');

  final isSelected = context.knobs.boolean(label: 'Selected');

  final hasTooltip = context.knobs.boolean(label: 'Show Tooltip');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoIconButton(
        icon: Icons.add,
        variant: variant,
        size: size,
        isLoading: isLoading,
        isSelected: isSelected,
        tooltip: hasTooltip ? 'Add item' : null,
        onPressed: isDisabled ? null : () {},
      ),
    ),
  );
}
