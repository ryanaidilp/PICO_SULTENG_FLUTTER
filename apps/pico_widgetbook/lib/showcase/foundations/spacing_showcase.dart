import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the spacing showcase component for Widgetbook.
WidgetbookComponent spacingShowcaseComponent() => WidgetbookComponent(
  name: 'Spacing',
  useCases: [
    WidgetbookUseCase(
      name: 'Spacing Scale',
      builder: (context) => const SpacingScaleShowcase(),
    ),
  ],
);

/// Showcases all spacing scale values with visual bars.
class const SpacingScaleShowcase({super.key}) extends StatelessWidget {
  /// Creates a [SpacingScaleShowcase].
  this;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        Text('Spacing Scale', style: typography.heading.h5),
        SizedBox(height: spacing.md),
        Text(
          'Based on 4px base unit',
          style: typography.body.small.copyWith(
            color: context.colors.foreground.muted,
          ),
        ),
        SizedBox(height: spacing.lg),
        _SpacingItem(
          label: 'none',
          accessor: 'spacing.none',
          value: spacing.none,
        ),
        _SpacingItem(
          label: 'xxs',
          accessor: 'spacing.xxs',
          value: spacing.xxs,
          description: '0.5x base',
        ),
        _SpacingItem(
          label: 'xs',
          accessor: 'spacing.xs',
          value: spacing.xs,
          description: '1x base',
        ),
        _SpacingItem(
          label: 'sm',
          accessor: 'spacing.sm',
          value: spacing.sm,
          description: '2x base',
        ),
        _SpacingItem(
          label: 'md',
          accessor: 'spacing.md',
          value: spacing.md,
          description: '3x base',
        ),
        _SpacingItem(
          label: 'lg',
          accessor: 'spacing.lg',
          value: spacing.lg,
          description: '4x base',
        ),
        _SpacingItem(
          label: 'xl',
          accessor: 'spacing.xl',
          value: spacing.xl,
          description: '6x base',
        ),
        _SpacingItem(
          label: 'xl2',
          accessor: 'spacing.xl2',
          value: spacing.xl2,
          description: '8x base',
        ),
        _SpacingItem(
          label: 'xl3',
          accessor: 'spacing.xl3',
          value: spacing.xl3,
          description: '12x base',
        ),
        _SpacingItem(
          label: 'xl4',
          accessor: 'spacing.xl4',
          value: spacing.xl4,
          description: '16x base',
        ),
        _SpacingItem(
          label: 'xl5',
          accessor: 'spacing.xl5',
          value: spacing.xl5,
          description: '20x base',
        ),
        _SpacingItem(
          label: 'xl6',
          accessor: 'spacing.xl6',
          value: spacing.xl6,
          description: '24x base',
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _SpacingItem({
  required final String label,
  required final String accessor,
  required final double value,
  final String? description,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final radius = context.radius;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: typography.label.captionMedium),
          ),
          SizedBox(
            width: 100,
            child: Text(
              accessor,
              style: typography.label.caption.copyWith(
                color: colors.foreground.muted,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text('${value.toInt()}px', style: typography.label.caption),
          ),
          if (description != null)
            SizedBox(
              width: 80,
              child: Text(
                description!,
                style: typography.label.caption.copyWith(
                  color: colors.foreground.subtle,
                ),
              ),
            ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Container(
              height: 24,
              alignment: Alignment.centerLeft,
              child: Container(
                width: value,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.action.primary.active,
                  borderRadius: radius.border.sm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
