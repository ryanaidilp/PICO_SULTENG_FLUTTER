import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the animated entrance showcase component for Widgetbook.
WidgetbookComponent animatedEntranceShowcaseComponent() => WidgetbookComponent(
  name: 'Animated Entrance',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoAnimatedEntrance',
      builder: _buildPicoAnimatedEntranceUseCase,
    ),
    WidgetbookUseCase(
      name: 'PicoAnimatedVisibility',
      builder: _buildPicoAnimatedVisibilityUseCase,
    ),
  ],
);

Widget _buildPicoAnimatedEntranceUseCase(BuildContext context) {
  final durationMs = context.knobs.double.slider(
    label: 'Duration (ms)',
    initialValue: 300,
    min: 100,
    max: 1000,
    divisions: 18,
  );

  final slideOffset = context.knobs.double.slider(
    label: 'Slide Offset',
    initialValue: 0.15,
    max: 0.5,
    divisions: 10,
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tap the button to replay the animation',
            style: context.typography.body.small.copyWith(
              color: context.colors.foreground.muted,
            ),
          ),
          const SizedBox(height: 24),
          _AnimatedEntranceDemo(
            duration: Duration(milliseconds: durationMs.toInt()),
            slideOffset: slideOffset,
          ),
        ],
      ),
    ),
  );
}

class const _AnimatedEntranceDemo({
  required final Duration duration,
  required final double slideOffset,
}) extends StatefulWidget {
  @override
  State<_AnimatedEntranceDemo> createState() => _AnimatedEntranceDemoState();
}

class _AnimatedEntranceDemoState() extends State<_AnimatedEntranceDemo> {
  int _key = 0;

  void _replay() {
    setState(() => _key++);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final radius = context.radius;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PicoAnimatedEntrance(
          key: ValueKey(_key),
          duration: widget.duration,
          slideOffset: widget.slideOffset,
          child: Container(
            width: 240,
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              color: colors.background.card,
              borderRadius: radius.border.lg,
              boxShadow: context.shadow.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: colors.action.primary.active,
                  size: 40,
                ),
                SizedBox(height: spacing.sm),
                Text(
                  'Animated Entrance',
                  style: typography.heading.h5,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.xs),
                Text(
                  'Slides in with a fade effect',
                  style: typography.body.small.copyWith(
                    color: colors.foreground.subtle,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.lg),
        PicoButton(
          label: 'Replay Animation',
          onPressed: _replay,
          leadingIcon: Icons.replay,
        ),
      ],
    );
  }
}

Widget _buildPicoAnimatedVisibilityUseCase(BuildContext context) {
  final isVisible = context.knobs.boolean(label: 'Visible', initialValue: true);

  final maintainSize = context.knobs.boolean(label: 'Maintain Size');

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PicoAnimatedVisibility(
            visible: isVisible,
            maintainSize: maintainSize,
            child: Container(
              width: 200,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.action.primary.active,
                borderRadius: context.radius.border.md,
              ),
              alignment: Alignment.center,
              child: Text(
                'I am visible!',
                style: context.typography.body.medium.copyWith(
                  color: context.colors.foreground.inverse,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Toggle "Visible" knob to animate',
            style: context.typography.body.small.copyWith(
              color: context.colors.foreground.muted,
            ),
          ),
        ],
      ),
    ),
  );
}
