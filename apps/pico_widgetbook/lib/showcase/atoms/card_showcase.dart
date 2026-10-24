import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the card showcase component for Widgetbook.
WidgetbookComponent cardShowcaseComponent() => WidgetbookComponent(
  name: 'Cards',
  useCases: [
    WidgetbookUseCase(name: 'PicoCard', builder: _buildPicoCardUseCase),
  ],
);

Widget _buildPicoCardUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown<PicoCardVariant>(
    label: 'Variant',
    options: PicoCardVariant.values,
    initialOption: PicoCardVariant.elevated,
    labelBuilder: (variant) => variant.name,
  );

  final size = context.knobs.object.dropdown<PicoCardSize>(
    label: 'Size',
    options: PicoCardSize.values,
    initialOption: PicoCardSize.md,
    labelBuilder: (size) => size.name,
  );

  final isTappable = context.knobs.boolean(label: 'Tappable');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoCard(
        variant: variant,
        size: size,
        width: 280,
        height: 160,
        onTap: isTappable ? () {} : null,
        child: const _CardContent(),
      ),
    ),
  );
}

class const _CardContent() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Card Title',
          style: typography.heading.h5.copyWith(color: colors.foreground.main),
        ),
        const SizedBox(height: 8),
        Text(
          'This is a sample card content demonstrating the PicoCard component.',
          style: typography.body.small.copyWith(
            color: colors.foreground.subtle,
          ),
        ),
      ],
    );
  }
}
