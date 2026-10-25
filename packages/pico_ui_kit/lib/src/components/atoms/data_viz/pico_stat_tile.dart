import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_state_icon.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';
import 'package:pico_ui_kit/src/foundations/radius/pico_radius_token.dart';

/// A figure for one data role, in the original PICO card style: a rounded
/// card with a thin outline, a round role icon, the label, the big tabular
/// number, the daily change and the date. A null [value] reads "Tidak ada
/// data", not 0. The role is told by its icon shape, its label and its text,
/// never by colour alone.
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
    final color = context.picoStates.of(state);
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
            borderRadius: PicoRadiusToken.borderMd,
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
                    PicoStateIcon(state: state, size: 14),
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
                const SizedBox(height: 8),
                // One line that scales down instead of breaking a number.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    figure,
                    maxLines: 1,
                    softWrap: false,
                    style: (v == null ? text.body.large : text.heading.h3)
                        .copyWith(color: context.colors.foreground.main),
                  ),
                ),
                if (deltaText != null)
                  Text(
                    deltaText,
                    style: text.body.small.copyWith(
                      color: context.colors.foreground.subtle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  t.date(date),
                  style: text.label.caption.copyWith(
                    color: context.colors.foreground.subtle,
                  ),
                ),
                // Role colour as a quiet accent under the date.
                const SizedBox(height: 8),
                SizedBox(
                  height: 3,
                  width: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: PicoRadiusToken.borderFull,
                    ),
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

/// The headline figure of a block (original "total confirmed" card): a blue
/// gradient card with the big white number, the daily change and the virus
/// picture. The gradient is the original one (dark blue to the logo blue,
/// left to right) whenever the text ends before [textEnd] of the width,
/// where white text still measures 4.5:1. When the text reaches further (a
/// long label, English, a larger text setting), the stretch under the text
/// stops at [textGround] and the rest of the card still ends on the
/// original light blue. White on the original light end measures 2.9:1 in
/// light mode and 4.3:1 in dark mode.
class PicoHeroStat extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.label,
    required this.date,
    this.value,
    this.delta,
    super.key,
  });

  /// Small caps label, for example "TOTAL KASUS POSITIF".
  final String label;

  /// The figure. Null shows "no data".
  final int? value;

  /// Change from the previous day.
  final int? delta;

  /// Date of the figure.
  final DateTime date;

  /// Width of the picture column on the right, which the text never enters.
  static const double pictureColumn = 88;

  /// Light end of the gradient: the logo blue over the page.
  static final Color lightEnd = PicoBrandPalette.primaryLight.withValues(
    alpha: 0.85,
  );

  /// How far along the gradient white text still passes 4.5:1, with a
  /// small margin (light mode, the stricter one).
  static const double textEnd = 0.33;

  /// The lightest colour under the text, before it meets the page.
  static final Color textGround = Color.lerp(
    PicoBrandPalette.primaryStrongLight,
    lightEnd,
    textEnd,
  )!;

  static const double _padStart = 16;

  /// Width of the widest text line, as laid out in the column.
  static double _widest(
    BuildContext context,
    double column,
    List<(String, TextStyle)> lines,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final (s, style) in lines) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: column);
      widest = math.max(widest, tp.width);
      tp.dispose();
    }
    return widest;
  }

  static Gradient _gradient(double split) => split <= textEnd
      ? LinearGradient(colors: [PicoBrandPalette.primaryStrongLight, lightEnd])
      : LinearGradient(
          colors: [PicoBrandPalette.primaryStrongLight, textGround, lightEnd],
          stops: [0, split.clamp(textEnd, 0.95), 1],
        );

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final text = context.typography;
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
      label,
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
    const onHero = Colors.white;
    final labelStyle = text.label.caption.copyWith(
      color: onHero,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    final figureStyle = text.heading.h1.copyWith(color: onHero);
    final deltaStyle = text.body.small.copyWith(
      color: onHero,
      fontWeight: FontWeight.w700,
    );
    final dateStyle = text.label.caption.copyWith(color: onHero);
    return Semantics(
      container: true,
      label: semantic,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth.isFinite ? box.maxWidth : 360.0;
            final column = math.max(1.0, w - _padStart - pictureColumn);
            final widest = _widest(context, column, [
              (label.toUpperCase(), labelStyle),
              (figure, figureStyle),
              if (deltaText != null) (deltaText, deltaStyle),
              (t.date(date), dateStyle),
            ]);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: PicoRadiusToken.borderMd,
                gradient: _gradient((_padStart + widest) / w),
                boxShadow: [
                  BoxShadow(
                    color: PicoBrandPalette.primaryLight.withValues(
                      alpha: 0.28,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: PicoRadiusToken.borderMd,
                child: Stack(
                  children: [
                    Positioned(
                      right: -6,
                      top: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: 0.9,
                        child: Image.asset(
                          'assets/images/covid.png',
                          package: 'pico_ui_kit',
                          fit: BoxFit.contain,
                          width: 76,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _padStart,
                        12,
                        pictureColumn,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label.toUpperCase(), style: labelStyle),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              figure,
                              maxLines: 1,
                              softWrap: false,
                              style: figureStyle,
                            ),
                          ),
                          if (deltaText != null)
                            Text(deltaText, style: deltaStyle),
                          const SizedBox(height: 2),
                          Text(t.date(date), style: dateStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
