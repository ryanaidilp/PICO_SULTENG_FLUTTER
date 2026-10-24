import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the rotating text showcase component for Widgetbook.
WidgetbookComponent rotatingTextShowcaseComponent() => WidgetbookComponent(
  name: 'Rotating Text',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoRotatingText',
      builder: _buildPicoRotatingTextUseCase,
    ),
  ],
);

Widget _buildPicoRotatingTextUseCase(BuildContext context) {
  final animationDurationMs = context.knobs.double.slider(
    label: 'Animation Duration (ms)',
    initialValue: 600,
    min: 200,
    max: 2000,
    divisions: 18,
  );

  final pauseDurationMs = context.knobs.double.slider(
    label: 'Pause Duration (ms)',
    initialValue: 1500,
    min: 500,
    max: 5000,
    divisions: 18,
  );

  final typography = context.typography;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ship your Flutter app',
            style: typography.heading.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          PicoRotatingText(
            key: ValueKey('$animationDurationMs-$pauseDurationMs'),
            labels: [
              TextSpan(
                text: 'in days, not weeks',
                style: typography.heading.h3.copyWith(
                  color: context.colors.action.primary.active,
                ),
              ),
              TextSpan(
                text: 'faster than ever',
                style: typography.heading.h3.copyWith(
                  color: context.colors.foreground.success,
                ),
              ),
              TextSpan(
                text: 'with confidence',
                style: typography.heading.h3.copyWith(
                  color: context.colors.foreground.info,
                ),
              ),
            ],
            style: typography.heading.h3,
            animationDuration: Duration(
              milliseconds: animationDurationMs.toInt(),
            ),
            pauseDuration: Duration(milliseconds: pauseDurationMs.toInt()),
          ),
          const SizedBox(height: 32),
          Text(
            'Adjust "Animation Duration" and "Pause Duration" knobs above',
            style: typography.body.small.copyWith(
              color: context.colors.foreground.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
