import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_marks.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/weave_shader_cache.dart';
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

  /// Data role: its weave fills the bar and its mark leads the label.
  final PicoState state;
}

/// Horizontal bars. Length carries the value, the fill is the weave of the
/// role, and the value label sits outside the bar (never on texture).
class PicoWovenBar extends StatefulWidget {
  /// Creates the bars.
  const new({required this.items, this.valueFormat, super.key});

  /// Bars, top to bottom.
  final List<WovenBarItem> items;

  /// Formats a value. Defaults to the locale grouped integer.
  final String Function(int value)? valueFormat;

  @override
  State<PicoWovenBar> createState() => _PicoWovenBarState();
}

class _PicoWovenBarState extends State<PicoWovenBar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = Theme.of(context).brightness;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    WeaveShaderCache.instance.warmUp(b, dpr).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final b = Theme.of(context).brightness;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fmt = widget.valueFormat ?? t.number;
    final colors = context.picoStates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in widget.items)
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
                        PicoMarkView(
                          mark: item.state.mark,
                          color: colors.of(item.state),
                          size: 12,
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
                          child: CustomPaint(
                            size: const Size.fromHeight(16),
                            painter: _BarPainter(
                              fraction: item.value == null || item.max <= 0
                                  ? 0
                                  : (item.value! / item.max)
                                        .clamp(0, 1)
                                        .toDouble(),
                              fill: colors.of(item.state),
                              shader: WeaveShaderCache.instance.shaderIfReady(
                                item.state,
                                b,
                                dpr,
                              ),
                              track: context.chartSurface.cottonDeep,
                              edge: context.colors.outline.subtle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.value == null ? t.noData : fmt(item.value!),
                          style: context.typography.body.small.copyWith(
                            color: context.colors.foreground.main,
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
  new({
    required this.fraction,
    required this.fill,
    required this.shader,
    required this.track,
    required this.edge,
  });

  final double fraction;
  final Color fill;
  final ui.Shader? shader;
  final Color track;
  final Color edge;

  @override
  void paint(Canvas canvas, Size s) {
    final full = RRect.fromRectAndRadius(
      Offset.zero & s,
      const Radius.circular(2),
    );
    canvas.drawRRect(full, Paint()..color = track);
    if (fraction > 0) {
      final w = (s.width * fraction).clamp(2.0, s.width);
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, s.height),
        const Radius.circular(2),
      );
      final p = Paint()..color = fill;
      if (shader != null) p.shader = shader;
      canvas.drawRRect(bar, p);
    }
    canvas.drawRRect(
      full,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(_BarPainter o) =>
      o.fraction != fraction ||
      o.fill != fill ||
      o.shader != shader ||
      o.track != track;
}
