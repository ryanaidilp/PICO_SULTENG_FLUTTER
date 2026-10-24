import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_marks.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Legend of data roles: mark, line form and text label. Never a colour chip
/// alone (DESIGN.md "Data roles").
class PicoMarkLegend extends StatelessWidget {
  /// Creates a legend for [states].
  const new({required this.states, this.labels, super.key});

  /// Roles to list.
  final List<PicoState> states;

  /// Optional text per role, same order as [states]. A null entry keeps the
  /// role label.
  final List<String?>? labels;

  String _label(PicoKitText t, int i, PicoState s) =>
      (labels != null && i < labels!.length ? labels![i] : null) ??
      t.stateLabel(s);

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final colors = context.picoStates;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final (i, s) in states.indexed)
          Semantics(
            container: true,
            label: _label(t, i, s),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PicoMarkView(mark: s.mark, color: colors.of(s)),
                  const SizedBox(width: 6),
                  CustomPaint(
                    size: const Size(28, 10),
                    painter: PicoLineFormPainter(
                      form: s.line,
                      color: colors.of(s),
                      dash: s.dash,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _label(t, i, s),
                    style: context.typography.label.caption.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
