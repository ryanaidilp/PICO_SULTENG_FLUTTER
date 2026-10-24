import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the sliding text showcase component for Widgetbook.
WidgetbookComponent slidingTextShowcaseComponent() => WidgetbookComponent(
  name: 'Sliding Text',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoSlidingText',
      builder: _buildPicoSlidingTextUseCase,
    ),
  ],
);

Widget _buildPicoSlidingTextUseCase(BuildContext context) {
  final direction = context.knobs.object.dropdown<PicoSlideDirection>(
    label: 'Direction',
    options: PicoSlideDirection.values,
    initialOption: PicoSlideDirection.up,
    labelBuilder: (d) => d.name,
  );

  final durationMs = context.knobs.double.slider(
    label: 'Duration (ms)',
    initialValue: 300,
    min: 100,
    max: 1000,
    divisions: 18,
  );

  final value = context.knobs.string(label: 'Value', initialValue: '1,234.56');

  final typography = context.typography;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current Balance',
            style: typography.label.captionMedium.copyWith(
              color: context.colors.foreground.muted,
            ),
          ),
          const SizedBox(height: 8),
          PicoSlidingText(
            value: value.isEmpty ? '0' : value,
            direction: direction,
            duration: Duration(milliseconds: durationMs.toInt()),
            style: typography.display.large.copyWith(
              color: context.colors.foreground.main,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Change the "Value" knob to see characters animate',
            style: typography.body.small.copyWith(
              color: context.colors.foreground.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _CounterDemo(direction: direction),
        ],
      ),
    ),
  );
}

class const _CounterDemo({required final PicoSlideDirection direction})
    extends StatefulWidget {
  @override
  State<_CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState() extends State<_CounterDemo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Interactive Counter',
          style: typography.label.captionMedium.copyWith(
            color: colors.foreground.subtle,
          ),
        ),
        SizedBox(height: spacing.sm),
        PicoSlidingText(
          value: _count.toString(),
          direction: widget.direction,
          style: typography.heading.h1.copyWith(color: colors.foreground.main),
        ),
        SizedBox(height: spacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PicoIconButton(
              icon: Icons.remove,
              variant: PicoIconButtonVariant.filledTonal,
              onPressed: () => setState(() => _count--),
            ),
            SizedBox(width: spacing.md),
            PicoIconButton(
              icon: Icons.add,
              variant: PicoIconButtonVariant.filled,
              onPressed: () => setState(() => _count++),
            ),
          ],
        ),
      ],
    );
  }
}
