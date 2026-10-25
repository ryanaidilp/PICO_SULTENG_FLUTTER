import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/chart_base.dart';

/// Every colour pair the kit composes, in light and dark, checked against
/// WCAG 2.2 AA from the tokens alone (no rendering, so no raster or font
/// differences between machines):
/// - text 4.5:1 (SC 1.4.3),
/// - graphics and component boundaries 3:1 (SC 1.4.11),
/// - focus indicator 3:1 against its ground (SC 2.4.13).
///
/// Translucent colours are composited over their real ground first.
/// Disabled controls and decorative lines (outline.subtle, the chart grid)
/// are exempt by WCAG and are not listed.
///
/// `PICO_CONTRAST_REPORT=1 flutter test test/foundations/themes/pico_contrast_test.dart`
/// prints the table used in docs/contrast-audit.md.
void main() {
  final report = Platform.environment['PICO_CONTRAST_REPORT'] == '1';
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    group('contrast ($mode)', () {
      for (final p in _pairs(dark: dark)) {
        test('${p.need.name}: ${p.name}', () {
          final r = ratio(p.fg, p.bg);
          if (report) {
            // ignore: avoid_print
            print(
              '| $mode | ${p.need.name} | ${p.name} | ${_hex(p.fg)} | '
              '${_hex(p.bg)} | ${r.toStringAsFixed(2)} | ${p.need.min} |',
            );
          }
          expect(
            r,
            greaterThanOrEqualTo(p.need.min),
            reason: '${p.name}: ${_hex(p.fg)} on ${_hex(p.bg)}',
          );
        });
      }
    });
  }

  // Colour-blind check of the four case series. They are also told apart by
  // mark shape and line form (PicoState), so colour is never the only cue
  // (SC 1.4.1). Where a dichromat would see two series as one colour, the
  // shapes must differ.
  const series = [
    PicoState.positive,
    PicoState.active,
    PicoState.recovered,
    PicoState.deceased,
  ];
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    final s = dark ? PicoStateColors.dark : PicoStateColors.light;
    test('series are distinct for normal vision ($mode)', () {
      for (var i = 0; i < series.length; i++) {
        for (var j = i + 1; j < series.length; j++) {
          expect(
            deltaE(s.of(series[i]), s.of(series[j])),
            greaterThan(20),
            reason: '${series[i].name} vs ${series[j].name}',
          );
        }
      }
    });
    test(
      'series that merge for colour-blind vision differ in shape ($mode)',
      () {
        final merged = <String>[];
        for (final cvd in Cvd.values) {
          for (var i = 0; i < series.length; i++) {
            for (var j = i + 1; j < series.length; j++) {
              final a = series[i];
              final b = series[j];
              final d = deltaE(simulate(s.of(a), cvd), simulate(s.of(b), cvd));
              if (report) {
                // ignore: avoid_print
                print(
                  '| $mode | ${cvd.name} | ${a.name} / ${b.name} | '
                  '${d.toStringAsFixed(1)} |',
                );
              }
              if (d < 10) {
                merged.add('$mode ${cvd.name} ${a.name}/${b.name}');
                expect(a.mark, isNot(b.mark));
                expect(a.line, isNot(b.line));
              }
            }
          }
        }
        // The one known exception: the legacy amber and red steps share a
        // lightness, so a deuteranope sees Dirawat and Meninggal as one
        // colour in the light theme. A new merge is a palette regression.
        expect(merged, dark ? isEmpty : ['light deutan active/deceased']);
      },
    );
  }

  // The original palette (feature/monorepo pico_colors.dart): the series and
  // the blues are steps of its families, so a contrast fix cannot drift the
  // brand silently. Changing one of these is a design decision.
  test('series and blue tokens are the pinned legacy steps', () {
    for (final (name, token, hex, legacy) in [
      (
        'positive light',
        PicoBrandPalette.positiveLight,
        0xFF09689B,
        'primary 600/700',
      ),
      (
        'recovered light',
        PicoBrandPalette.recoveredLight,
        0xFF087443,
        'success 700',
      ),
      (
        'deceased light',
        PicoBrandPalette.deceasedLight,
        0xFFB42318,
        'error 700',
      ),
      // Between warning 700 (B28000, 3.3:1 on paper) and 800 (7A5900): the
      // nearest amber at 4.5:1 on every ground.
      (
        'active light',
        PicoBrandPalette.activeLight,
        0xFF8A5A00,
        'warning 700 to 800',
      ),
      ('rt light', PicoBrandPalette.rtLight, 0xFF5E3BC6, 'secondary 700'),
      (
        'positive dark',
        PicoBrandPalette.positiveDark,
        0xFF40BBF0,
        'primary 400',
      ),
      (
        'recovered dark',
        PicoBrandPalette.recoveredDark,
        0xFF3CCB7F,
        'success 400',
      ),
      ('deceased dark', PicoBrandPalette.deceasedDark, 0xFFF97066, 'error 400'),
      ('active dark', PicoBrandPalette.activeDark, 0xFFFDC941, 'warning 400'),
      ('rt dark', PicoBrandPalette.rtDark, 0xFFA197EE, 'secondary 400'),
      ('logo blue', PicoBrandPalette.primaryLight, 0xFF0B92D5, 'primary 500'),
      (
        'blue, text step',
        PicoBrandPalette.primaryStrongLight,
        0xFF09689B,
        'primary 600/700',
      ),
      ('blue, deep', PicoBrandPalette.indigoLight, 0xFF0C5880, 'primary 800'),
      ('blue, tint', PicoBrandPalette.tintLight, 0xFFE1F2FD, 'primary 100'),
      (
        'blue, dark theme',
        PicoBrandPalette.primaryDark,
        0xFF40BBF0,
        'primary 400',
      ),
      (
        'blue, dark theme deep',
        PicoBrandPalette.indigoDark,
        0xFF82D2F7,
        'primary 300',
      ),
    ]) {
      expect(token.toARGB32(), hex, reason: '$name ($legacy)');
    }
  });
}

enum Need {
  text(4.5),
  graphic(3),
  focus(3);

  const Need(this.min);
  final double min;
}

class _Pair {
  const _Pair(this.name, this.fg, this.bg, this.need);
  final String name;
  final Color fg;
  final Color bg;
  final Need need;
}

List<_Pair> _pairs({required bool dark}) {
  final c = dark ? PicoColorExtension.dark() : PicoColorExtension.light();
  final s = dark ? PicoStateColors.dark : PicoStateColors.light;
  final cloth = dark ? PicoClothSurface.dark : PicoClothSurface.light;
  final scheme = (dark ? PicoTheme.dark() : PicoTheme.light()).colorScheme;
  final grounds = {
    'page': c.background.main,
    'card': c.background.card,
    'subtle': c.background.subtle,
    'strong': c.background.strong,
  };
  final paper = {'page': c.background.main, 'card': c.background.card};
  Color over(Color fg, Color bg) => Color.alphaBlend(fg, bg);
  final out = <_Pair>[];
  void add(String n, Color fg, Color bg, Need need) =>
      out.add(_Pair(n, over(fg, bg), bg, need));

  // Body, secondary and muted text on every ground.
  for (final (n, fg) in [
    ('foreground.main', c.foreground.main),
    ('foreground.subtle', c.foreground.subtle),
    ('foreground.muted', c.foreground.muted),
  ]) {
    grounds.forEach((g, bg) => add('$n on $g', fg, bg, Need.text));
  }
  // Status text on page and card, and on its own status surface.
  for (final (n, fg, own) in [
    ('success', c.foreground.success, c.background.success),
    ('warning', c.foreground.warning, c.background.warning),
    ('error', c.foreground.error, c.background.error),
    ('info', c.foreground.info, c.background.info),
    ('primary', c.foreground.primary, c.background.info),
  ]) {
    paper.forEach((g, bg) => add('foreground.$n on $g', fg, bg, Need.text));
    add('foreground.$n on its status surface', fg, own, Need.text);
  }
  // Text buttons, links, the selected tab label; filled actions.
  for (final (n, a) in [
    ('primary', c.action.primary),
    ('secondary', c.action.secondary),
    ('destructive', c.action.destructive),
    ('success', c.action.success),
  ]) {
    paper.forEach(
      (g, bg) => add('action.$n as text on $g', a.active, bg, Need.text),
    );
    add(
      'foreground.inverse on action.$n',
      c.foreground.inverse,
      a.active,
      Need.text,
    );
    add(
      'foreground.inverse on action.$n hover',
      c.foreground.inverse,
      a.hover,
      Need.text,
    );
  }
  add(
    'foreground.inverse on background.inverse',
    c.foreground.inverse,
    c.background.inverse,
    Need.text,
  );
  // Material roles the stock widgets read (buttons, chips, segmented
  // buttons, navigation bar, snack bar, dialogs).
  for (final (n, fg, bg) in [
    ('onPrimary / primary', scheme.onPrimary, scheme.primary),
    ('onSecondary / secondary', scheme.onSecondary, scheme.secondary),
    ('onTertiary / tertiary', scheme.onTertiary, scheme.tertiary),
    ('onError / error', scheme.onError, scheme.error),
    (
      'onPrimaryContainer / primaryContainer',
      scheme.onPrimaryContainer,
      scheme.primaryContainer,
    ),
    (
      'onSecondaryContainer / secondaryContainer (selected chip, segment)',
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
    ),
    ('onSurface / surface', scheme.onSurface, scheme.surface),
    ('onSurfaceVariant / surface', scheme.onSurfaceVariant, scheme.surface),
    (
      'onSurfaceVariant / surfaceContainerHighest',
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHighest,
    ),
    (
      'onInverseSurface / inverseSurface (snack bar)',
      scheme.onInverseSurface,
      scheme.inverseSurface,
    ),
    (
      'inversePrimary / inverseSurface (snack bar action)',
      scheme.inversePrimary,
      scheme.inverseSurface,
    ),
    ('primary / surface (text button)', scheme.primary, scheme.surface),
  ]) {
    add('scheme $n', fg, bg, Need.text);
  }
  // Hero figure: white text on the lightest point under the text column.
  add(
    'hero white text on its lightest ground',
    Colors.white,
    over(PicoHeroStat.textGround, c.background.main),
    Need.text,
  );
  add(
    'hero white text on the dark end',
    Colors.white,
    PicoBrandPalette.primaryStrongLight,
    Need.text,
  );
  // Map: kabupaten names over the region fill and over a selected region.
  add('map label on region', c.foreground.main, cloth.tint, Need.text);
  for (final st in PicoState.values) {
    final sel = over(s.of(st).withValues(alpha: .28), cloth.tint);
    add(
      'map label on selected ${st.name} region',
      c.foreground.main,
      sel,
      Need.text,
    );
    add('${st.name} mark on selected region', s.of(st), sel, Need.graphic);
  }

  // Non-text: component boundaries and focus.
  grounds.forEach(
    (g, bg) => add(
      'outline.main (control edge) on $g',
      c.outline.main,
      bg,
      Need.graphic,
    ),
  );
  paper.forEach(
    (g, bg) => add('outline.focus on $g', c.outline.focus, bg, Need.focus),
  );
  add(
    'selected nav icon on its indicator',
    c.action.primary.active,
    c.background.strong,
    Need.graphic,
  );
  add(
    'map region outline on region',
    c.outline.strong,
    cloth.tint,
    Need.graphic,
  );
  // Series lines, marks, bars and icons.
  for (final st in PicoState.values) {
    final col = s.of(st);
    grounds.forEach(
      (g, bg) => add('${st.name} mark on $g', col, bg, Need.graphic),
    );
    add(
      '${st.name} icon in its badge',
      col,
      over(col.withValues(alpha: .14), c.background.card),
      Need.graphic,
    );
  }
  // Rt credible band: its edge carries the bound (the fill is a wash).
  paper.forEach(
    (g, bg) => add(
      'Rt band edge on $g',
      s.rt.withValues(alpha: ChartPainter.bandEdgeAlpha),
      bg,
      Need.graphic,
    ),
  );
  paper.forEach(
    (g, bg) => add(
      'chart axis and Rt = 1 rule on $g',
      c.outline.main,
      bg,
      Need.graphic,
    ),
  );
  return out;
}

double ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Dichromat simulation (Machado, Oliveira and Fernandes 2009, severity 1).
enum Cvd {
  protan([
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ]),
  deutan([
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ]),
  tritan([
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ]);

  const Cvd(this.m);
  final List<List<double>> m;
}

double _lin(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _gam(double v) => v <= 0.0031308
    ? 12.92 * v
    : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;

/// [c] as seen with [cvd].
Color simulate(Color c, Cvd cvd) {
  final l = [_lin(c.r), _lin(c.g), _lin(c.b)];
  final o = [
    for (final row in cvd.m)
      _gam((row[0] * l[0] + row[1] * l[1] + row[2] * l[2]).clamp(0, 1)),
  ];
  return Color.from(alpha: 1, red: o[0], green: o[1], blue: o[2]);
}

/// CIE76 colour difference in CIELAB (D65).
double deltaE(Color a, Color b) {
  List<double> lab(Color c) {
    final r = _lin(c.r);
    final g = _lin(c.g);
    final bl = _lin(c.b);
    final x = (0.4124 * r + 0.3576 * g + 0.1805 * bl) / 0.95047;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * bl;
    final z = (0.0193 * r + 0.1192 * g + 0.9505 * bl) / 1.08883;
    double f(double t) =>
        t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
  }

  final p = lab(a);
  final q = lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}
