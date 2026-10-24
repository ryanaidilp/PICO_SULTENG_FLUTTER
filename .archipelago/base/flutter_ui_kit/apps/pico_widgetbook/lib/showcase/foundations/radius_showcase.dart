import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the radius showcase component for Widgetbook.
WidgetbookComponent radiusShowcaseComponent() => WidgetbookComponent(
  name: 'Radius',
  useCases: [
    WidgetbookUseCase(
      name: 'Radius Scale',
      builder: (context) => const RadiusScaleShowcase(),
    ),
  ],
);

/// Showcases all radius scale values with visual squares.
class const RadiusScaleShowcase({super.key}) extends StatelessWidget {
  /// Creates a [RadiusScaleShowcase].
  this;

  @override
  Widget build(BuildContext context) {
    final radius = context.radius;
    final spacing = context.spacing;
    final typography = context.typography;

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        Text('Radius Scale', style: typography.heading.h5),
        SizedBox(height: spacing.md),
        Text(
          'Border radius tokens for consistent corner rounding',
          style: typography.body.small.copyWith(
            color: context.colors.foreground.muted,
          ),
        ),
        SizedBox(height: spacing.lg),
        _RadiusItem(
          label: 'none',
          accessor: 'radius.none',
          value: radius.none,
          description: '0px — sharp corners',
        ),
        _RadiusItem(
          label: 'xs',
          accessor: 'radius.xs',
          value: radius.xs,
          description: '2px — subtle rounding',
        ),
        _RadiusItem(
          label: 'sm',
          accessor: 'radius.sm',
          value: radius.sm,
          description: '4px — small rounding',
        ),
        _RadiusItem(
          label: 'md',
          accessor: 'radius.md',
          value: radius.md,
          description: '8px — default',
        ),
        _RadiusItem(
          label: 'lg',
          accessor: 'radius.lg',
          value: radius.lg,
          description: '12px — large rounding',
        ),
        _RadiusItem(
          label: 'xl',
          accessor: 'radius.xl',
          value: radius.xl,
          description: '16px — extra large',
        ),
        _RadiusItem(
          label: 'xl2',
          accessor: 'radius.xl2',
          value: radius.xl2,
          description: '24px — 2X large',
        ),
        _RadiusItem(
          label: 'full',
          accessor: 'radius.full',
          value: radius.full,
          description: '9999px — pill shape',
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _RadiusItem({
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
    final clampedRadius = value.clamp(0.0, 40.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: typography.label.captionMedium),
          ),
          SizedBox(
            width: 110,
            child: Text(
              accessor,
              style: typography.label.caption.copyWith(
                color: colors.foreground.muted,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text('${value.toInt()}px', style: typography.label.caption),
          ),
          if (description != null)
            Expanded(
              child: Text(
                description!,
                style: typography.label.caption.copyWith(
                  color: colors.foreground.subtle,
                ),
              ),
            ),
          SizedBox(width: spacing.md),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.action.primary.active.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(clampedRadius),
              border: Border.all(color: colors.action.primary.active, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}
