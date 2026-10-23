import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_marks.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// A figure for one data role: label, mark, big tabular number, optional delta
/// and the date. It sits on plain surface, never on texture. A null [value]
/// reads "Tidak ada data", not 0.
class PicoStatTile extends StatelessWidget {
  /// Creates a tile.
  const new({
    required this.state,
    required this.date,
    this.value,
    this.delta,
    this.label,
    super.key,
  });

  /// Data role.
  final PicoState state;

  /// The figure. Null shows "no data".
  final int? value;

  /// Change from the previous day. Shown with sign and an arrow shape.
  final int? delta;

  /// Overrides the role label (for example "Positif hari ini").
  final String? label;

  /// Date of the figure.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final colors = context.picoStates;
    final color = colors.of(state);
    final text = context.typography;
    final name = label ?? t.stateLabel(state);
    final v = value;
    final d = delta;
    final figure = v == null ? t.noData : t.number(v);
    final deltaText = d == null
        ? null
        : '${d > 0
              ? '▲'
              : d < 0
              ? '▼'
              : '■'} ${d > 0 ? '+' : ''}${t.number(d)}';
    final semantic = [
      name,
      figure,
      ?deltaText == null
          ? null
          : '${d! > 0
                ? (t.english ? 'up' : 'naik')
                : d < 0
                ? (t.english ? 'down' : 'turun')
                : (t.english ? 'unchanged' : 'tetap')} ${t.number(d.abs())}',
      t.date(date),
    ].join(', ');
    return Semantics(
      container: true,
      label: semantic,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.background.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colors.outline.subtle),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    PicoMarkView(mark: state.mark, color: color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        name,
                        style: text.label.caption.copyWith(
                          color: context.colors.foreground.subtle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  figure,
                  style: (v == null ? text.body.large : text.display.small)
                      .copyWith(color: context.colors.foreground.main),
                ),
                if (deltaText != null)
                  Text(
                    deltaText,
                    style: text.body.small.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  t.date(date),
                  style: text.label.caption.copyWith(
                    color: context.colors.foreground.subtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
