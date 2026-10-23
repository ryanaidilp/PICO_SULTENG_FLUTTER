import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_marks.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Legend of data roles: mark, line form and text label. Never a colour chip
/// alone (DESIGN.md "Data roles").
class PicoMarkLegend extends StatelessWidget {
  /// Creates a legend for [states].
  const new({required this.states, super.key});

  /// Roles to list.
  final List<PicoState> states;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final colors = context.picoStates;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final s in states)
          Semantics(
            container: true,
            label: t.stateLabel(s),
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
                    t.stateLabel(s),
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
