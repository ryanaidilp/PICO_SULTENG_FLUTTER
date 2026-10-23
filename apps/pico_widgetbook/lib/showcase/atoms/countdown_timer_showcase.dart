import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';

/// Creates the countdown timer showcase component for Widgetbook.
WidgetbookComponent countdownTimerShowcaseComponent() => WidgetbookComponent(
  name: 'Countdown Timer',
  useCases: [
    WidgetbookUseCase(
      name: 'PicoCountdownTimer',
      builder: _buildCountdownTimerUseCase,
    ),
  ],
);

Widget _buildCountdownTimerUseCase(BuildContext context) {
  final format = context.knobs.object.dropdown<PicoCountdownFormat>(
    label: 'Format',
    options: PicoCountdownFormat.values,
    initialOption: PicoCountdownFormat.mmss,
    labelBuilder: (f) => f.name,
  );

  final durationSeconds = context.knobs.double.slider(
    label: 'Duration (seconds)',
    initialValue: 60,
    min: 10,
    max: 3600,
    divisions: 36,
  );

  final separator = context.knobs.string(label: 'Separator', initialValue: ':');

  final hasDangerThreshold = context.knobs.boolean(
    label: 'Danger Threshold (10s)',
  );

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _CountdownTimerDemo(
        key: ValueKey('$format-$durationSeconds-$hasDangerThreshold'),
        duration: Duration(seconds: durationSeconds.toInt()),
        format: format,
        separator: separator.isEmpty ? ':' : separator,
        hasDangerThreshold: hasDangerThreshold,
      ),
    ),
  );
}

class const _CountdownTimerDemo({
  required final Duration duration,
  required final PicoCountdownFormat format,
  required final String separator,
  required final bool hasDangerThreshold,
  super.key,
}) extends StatefulWidget {
  @override
  State<_CountdownTimerDemo> createState() => _CountdownTimerDemoState();
}

class _CountdownTimerDemoState() extends State<_CountdownTimerDemo> {
  late final PicoCountdownController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = PicoCountdownController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.xl2,
            vertical: spacing.xl,
          ),
          decoration: BoxDecoration(
            color: colors.background.card,
            borderRadius: radius.border.xl,
            boxShadow: context.shadow.md,
          ),
          child: PicoCountdownTimer.duration(
            duration: widget.duration,
            format: widget.format,
            separator: widget.separator,
            controller: _controller,
            style: typography.display.large,
            dangerThreshold: widget.hasDangerThreshold
                ? const Duration(seconds: 10)
                : null,
            dangerStyle: typography.display.large.copyWith(
              color: colors.foreground.error,
            ),
            onFinished: () => setState(() => _finished = true),
          ),
        ),
        SizedBox(height: spacing.lg),
        if (_finished)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.md),
            child: Text(
              "Time's up!",
              style: typography.body.medium.copyWith(
                color: colors.foreground.error,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PicoIconButton(
              icon: Icons.play_arrow,
              variant: PicoIconButtonVariant.filled,
              onPressed: () {
                setState(() => _finished = false);
                _controller.start();
              },
            ),
            SizedBox(width: spacing.md),
            PicoIconButton(
              icon: Icons.pause,
              variant: PicoIconButtonVariant.filledTonal,
              onPressed: _controller.pause,
            ),
            SizedBox(width: spacing.md),
            PicoIconButton(
              icon: Icons.replay,
              variant: PicoIconButtonVariant.outlined,
              onPressed: () {
                setState(() => _finished = false);
                _controller.reset();
              },
            ),
          ],
        ),
      ],
    );
  }
}
