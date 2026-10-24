import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_state_icon.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// One bar of a [PicoWovenBar].
class WovenBarItem {
  /// Creates an item. [max] is the value that fills the whole bar.
  const new({
    required this.label,
    required this.value,
    required this.max,
    required this.state,
  });

  /// Text label above the bar.
  final String label;

  /// Value. Null is "no data" and draws an empty track.
  final int? value;

  /// Full scale.
  final int max;

  /// Data role: its colour fills the bar and its icon leads the label.
  final PicoState state;
}

/// Horizontal bars that grow from zero in 700 ms (the original chart motion,
/// off with reduced motion). Length carries the value, the fill is the colour
/// of the role, the icon of the role leads the label and the value label sits
/// outside the bar. (The class keeps its first name; there is no weave
/// texture any more.)
class PicoWovenBar extends StatelessWidget {
  /// Creates the bars.
  const new({required this.items, this.valueFormat, super.key});

  /// Bars, top to bottom.
  final List<WovenBarItem> items;

  /// Formats a value. Defaults to the locale grouped integer.
  final String Function(int value)? valueFormat;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final fmt = valueFormat ?? t.number;
    final colors = context.picoStates;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Semantics(
              container: true,
              label:
                  '${item.label}, ${item.value == null ? t.noData : fmt(item.value!)}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PicoStateIcon(
                          state: item.state,
                          size: 12,
                          badge: false,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.label,
                            style: context.typography.label.caption.copyWith(
                              color: context.colors.foreground.main,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: item.value == null || item.max <= 0
                                  ? 0
                                  : (item.value! / item.max)
                                        .clamp(0, 1)
                                        .toDouble(),
                            ),
                            duration: animate
                                ? const Duration(milliseconds: 700)
                                : Duration.zero,
                            curve: Curves.easeInOutCubic,
                            builder: (context, fraction, _) => CustomPaint(
                              size: const Size.fromHeight(16),
                              painter: _BarPainter(
                                fraction: fraction,
                                fill: colors.of(item.state),
                                track: context.colors.background.subtle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.value == null ? t.noData : fmt(item.value!),
                          style: context.typography.body.small.copyWith(
                            color: context.colors.foreground.main,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  new({required this.fraction, required this.fill, required this.track});

  final double fraction;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size s) {
    const radius = Radius.circular(8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, radius),
      Paint()..color = track,
    );
    if (fraction > 0) {
      final w = (s.width * fraction).clamp(8.0, s.width);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, s.height), radius),
        Paint()..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter o) =>
      o.fraction != fraction || o.fill != fill || o.track != track;
}
