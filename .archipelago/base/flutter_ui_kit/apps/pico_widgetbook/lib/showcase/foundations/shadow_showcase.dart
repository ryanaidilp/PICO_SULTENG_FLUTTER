import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the shadow showcase component for Widgetbook.
WidgetbookComponent shadowShowcaseComponent() => WidgetbookComponent(
  name: 'Shadows',
  useCases: [
    WidgetbookUseCase(
      name: 'Shadow Scale',
      builder: (context) => const ShadowScaleShowcase(),
    ),
  ],
);

/// Showcases all shadow elevation levels with visual cards.
class const ShadowScaleShowcase({super.key}) extends StatelessWidget {
  /// Creates a [ShadowScaleShowcase].
  this;

  @override
  Widget build(BuildContext context) {
    final shadow = context.shadow;
    final spacing = context.spacing;
    final typography = context.typography;

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        Text('Shadow Scale', style: typography.heading.h5),
        SizedBox(height: spacing.md),
        Text(
          'Elevation shadows for light and dark themes',
          style: typography.body.small.copyWith(
            color: context.colors.foreground.muted,
          ),
        ),
        SizedBox(height: spacing.xl),
        _ShadowItem(
          label: 'none',
          accessor: 'shadow.none',
          shadows: shadow.none,
          description: 'No shadow',
        ),
        _ShadowItem(
          label: 'xs',
          accessor: 'shadow.xs',
          shadows: shadow.xs,
          description: 'blur: 2px, offset: (0, 1)',
        ),
        _ShadowItem(
          label: 'sm',
          accessor: 'shadow.sm',
          shadows: shadow.sm,
          description: 'blur: 4px, offset: (0, 2)',
        ),
        _ShadowItem(
          label: 'md',
          accessor: 'shadow.md',
          shadows: shadow.md,
          description: 'blur: 8px, offset: (0, 4)',
        ),
        _ShadowItem(
          label: 'lg',
          accessor: 'shadow.lg',
          shadows: shadow.lg,
          description: 'blur: 16px, offset: (0, 8)',
        ),
        _ShadowItem(
          label: 'xl',
          accessor: 'shadow.xl',
          shadows: shadow.xl,
          description: 'blur: 24px, offset: (0, 12)',
        ),
        _ShadowItem(
          label: 'xl2',
          accessor: 'shadow.xl2',
          shadows: shadow.xl2,
          description: 'blur: 32px, offset: (0, 16)',
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _ShadowItem({
  required final String label,
  required final String accessor,
  required final List<BoxShadow> shadows,
  final String? description,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final radius = context.radius;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: typography.label.captionMedium),
          ),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  accessor,
                  style: typography.label.caption.copyWith(
                    color: colors.foreground.muted,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: typography.label.caption.copyWith(
                      color: colors.foreground.subtle,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: spacing.xl),
          Container(
            width: 120,
            height: 72,
            decoration: BoxDecoration(
              color: colors.background.card,
              borderRadius: radius.border.md,
              boxShadow: shadows,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: typography.label.captionMedium.copyWith(
                color: colors.foreground.subtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
