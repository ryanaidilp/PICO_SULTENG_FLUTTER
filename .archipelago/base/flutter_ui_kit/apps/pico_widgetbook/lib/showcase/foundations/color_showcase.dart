import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the color showcase component for Widgetbook.
WidgetbookComponent colorShowcaseComponent() => WidgetbookComponent(
  name: 'Colors',
  useCases: [
    WidgetbookUseCase(
      name: 'Color Tokens',
      builder: (context) => const ColorTokensShowcase(),
    ),
  ],
);

/// Showcases all semantic color tokens organized by category.
class const ColorTokensShowcase({super.key}) extends StatelessWidget {
  /// Creates a [ColorTokensShowcase].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        _SectionTitle(title: 'Foreground Colors', typography: typography),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'main': colors.foreground.main,
            'subtle': colors.foreground.subtle,
            'muted': colors.foreground.muted,
            'disabled': colors.foreground.disabled,
            'inverse': colors.foreground.inverse,
            'primary': colors.foreground.primary,
            'success': colors.foreground.success,
            'warning': colors.foreground.warning,
            'error': colors.foreground.error,
            'info': colors.foreground.info,
          },
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Background Colors', typography: typography),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'main': colors.background.main,
            'subtle': colors.background.subtle,
            'strong': colors.background.strong,
            'inverse': colors.background.inverse,
            'card': colors.background.card,
            'cardSecondary': colors.background.cardSecondary,
            'success': colors.background.success,
            'warning': colors.background.warning,
            'error': colors.background.error,
            'info': colors.background.info,
          },
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Action Colors - Primary', typography: typography),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'active': colors.action.primary.active,
            'hover': colors.action.primary.hover,
            'disabled': colors.action.primary.disabled,
          },
        ),
        SizedBox(height: spacing.lg),
        _SectionTitle(
          title: 'Action Colors - Secondary',
          typography: typography,
        ),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'active': colors.action.secondary.active,
            'hover': colors.action.secondary.hover,
            'disabled': colors.action.secondary.disabled,
          },
        ),
        SizedBox(height: spacing.lg),
        _SectionTitle(
          title: 'Action Colors - Destructive',
          typography: typography,
        ),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'active': colors.action.destructive.active,
            'hover': colors.action.destructive.hover,
            'disabled': colors.action.destructive.disabled,
          },
        ),
        SizedBox(height: spacing.lg),
        _SectionTitle(title: 'Action Colors - Success', typography: typography),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'active': colors.action.success.active,
            'hover': colors.action.success.hover,
            'disabled': colors.action.success.disabled,
          },
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Outline Colors', typography: typography),
        SizedBox(height: spacing.sm),
        _ColorGrid(
          colors: {
            'main': colors.outline.main,
            'strong': colors.outline.strong,
            'subtle': colors.outline.subtle,
            'focus': colors.outline.focus,
          },
        ),
        SizedBox(height: spacing.xl),
        _SectionTitle(title: 'Overlay', typography: typography),
        SizedBox(height: spacing.sm),
        _ColorGrid(colors: {'overlay': colors.overlay}),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _SectionTitle({
  required final String title,
  required final PicoTypographyExtension typography,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(title, style: typography.heading.h5);
}

class const _ColorGrid({required final Map<String, Color> colors})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.spacing.sm,
    runSpacing: context.spacing.md,
    children: colors.entries
        .map((entry) => _ColorItem(label: entry.key, color: entry.value))
        .toList(),
  );
}

class const _ColorItem({
  required final String label,
  required final Color color,
}) extends StatelessWidget {
  String get _hexCode {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
    if (a == 'ff') {
      return '#$r$g$b'.toUpperCase();
    }
    return '#$a$r$g$b'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final radius = context.radius;
    final colors = context.colors;

    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: typography.label.captionMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.xs),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius.border.md,
              border: Border.all(color: colors.outline.subtle),
              boxShadow: context.shadow.sm,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            _hexCode,
            style: typography.label.caption.copyWith(
              color: colors.foreground.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
