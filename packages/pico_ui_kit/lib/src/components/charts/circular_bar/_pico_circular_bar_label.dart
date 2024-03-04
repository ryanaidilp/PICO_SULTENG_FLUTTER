part of 'circular_bar.dart';

class _PicoCircularBarLabel extends StatelessWidget {
  const _PicoCircularBarLabel({
    required this.value,
    this.valueFormatter,
  });

  final double value;
  final String Function(num value)? valueFormatter;

  Color valueColor(BuildContext context) => switch (value) {
        > 0 => context.picoColors.icon.semantic.error,
        < 0 => context.picoColors.icon.semantic.success,
        _ => context.picoColors.icon.neutral.main,
      };

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Builder(
            builder: (context) {
              Widget child = const SizedBox.shrink();
              if (value != 0) {
                final rotationFactor = value.isNegative ? 1.95 : 1.48;

                child = AnimatedRotation(
                  turns: pi / rotationFactor,
                  duration: 300.milliseconds,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 16.sp,
                    color: valueColor(context),
                  ),
                );
              }

              return AnimatedSwitcher(
                duration: 300.milliseconds,
                child: child,
              );
            },
          ),
          AnimatedDefaultTextStyle(
            style: PicoTextStyle.bodyXs(
              color: valueColor(context),
            ),
            duration: 300.milliseconds,
            child: Text(
              valueFormatter != null
                  ? valueFormatter!.call(value)
                  : value.toString(),
            ),
          ),
        ],
      );
}
