import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the gradient border container showcase component for Widgetbook.
WidgetbookComponent gradientBorderShowcaseComponent() => WidgetbookComponent(
  name: 'Gradient Border',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoGradientBorderContainer',
      builder: _buildGradientBorderUseCase,
    ),
    WidgetbookUseCase(
      name: 'Presets',
      builder: (context) => const _GradientBorderPresetsShowcase(),
    ),
  ],
);

enum _GradientPreset() {
  linear,
  rainbow,
  primary,
  sweep,
  radial,
}

Widget _buildGradientBorderUseCase(BuildContext context) {
  final preset = context.knobs.object.dropdown<_GradientPreset>(
    label: 'Gradient Type',
    options: _GradientPreset.values,
    initialOption: _GradientPreset.linear,
    labelBuilder: (p) => p.name,
  );

  final borderWidth = context.knobs.double.slider(
    label: 'Border Width',
    initialValue: 2,
    min: 1,
    max: 8,
    divisions: 7,
  );

  final radiusValue = context.knobs.double.slider(
    label: 'Border Radius',
    initialValue: 12,
    max: 40,
    divisions: 10,
  );

  final borderRadius = BorderRadius.circular(radiusValue);

  final colors = context.colors;

  final Gradient gradient = switch (preset) {
    _GradientPreset.linear => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.action.primary.active, colors.foreground.info],
    ),
    _GradientPreset.rainbow => const SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFF7F00),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFF4B0082),
        Color(0xFF8F00FF),
        Color(0xFFFF0000),
      ],
    ),
    _GradientPreset.primary => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.action.primary.hover,
        colors.action.primary.active,
        colors.action.primary.disabled,
      ],
    ),
    _GradientPreset.sweep => SweepGradient(
      colors: [
        colors.action.primary.active,
        colors.foreground.success,
        colors.foreground.warning,
        colors.action.primary.active,
      ],
    ),
    _GradientPreset.radial => RadialGradient(
      colors: [colors.action.primary.active, colors.foreground.info],
    ),
  };

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PicoGradientBorderContainer(
        gradient: gradient,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        padding: const EdgeInsets.all(24),
        child: const _CardContent(),
      ),
    ),
  );
}

class const _GradientBorderPresetsShowcase() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;

    return ListView(
      padding: EdgeInsets.all(spacing.lg),
      children: [
        Text('Gradient Border Presets', style: typography.heading.h5),
        SizedBox(height: spacing.lg),
        Text('Rainbow', style: typography.label.captionMedium),
        SizedBox(height: spacing.sm),
        PicoGradientBorderContainer.rainbow(
          padding: EdgeInsets.all(spacing.lg),
          child: const _CardContent(),
        ),
        SizedBox(height: spacing.xl),
        Text('Primary Theme', style: typography.label.captionMedium),
        SizedBox(height: spacing.sm),
        PicoGradientBorderContainer.primary(
          context: context,
          padding: EdgeInsets.all(spacing.lg),
          child: const _CardContent(),
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

class const _CardContent() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, color: colors.action.primary.active, size: 32),
        SizedBox(height: spacing.sm),
        Text(
          'Gradient Border',
          style: typography.heading.h5.copyWith(color: colors.foreground.main),
        ),
        SizedBox(height: spacing.xs),
        Text(
          'Supports linear, radial, and sweep gradients',
          style: typography.body.small.copyWith(
            color: colors.foreground.subtle,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
