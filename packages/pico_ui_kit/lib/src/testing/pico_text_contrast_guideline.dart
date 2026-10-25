import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.2 AA text contrast (SC 1.4.3), measured from colour tokens and
/// checked against the rendered frame.
///
/// Flutter's `textContrastGuideline` guesses the text colour from pixels: it
/// splits the box at its average lightness and takes the most frequent pixel
/// of the darker half. FreeType on the Linux runner draws a 12 px stem with
/// soft edges, so that mode is an anti-aliasing step (for example #868686 x25
/// against the real #535352 ink, which is also there): it measured 3.64:1, and
/// on CI 1.4:1, for text that is 7.26:1. CoreText on macOS draws the ink as
/// the mode, so the same test passed locally. Doubling the device pixel ratio
/// does not help: the stock guideline renders its image at 1/dpr, back to
/// logical pixels, and measures the same 3.64:1. It also skips text inside
/// `ExcludeSemantics` (a tile that reads as one label).
///
/// This guideline instead, for every visible, hit-testable [RenderParagraph]:
/// 1. reads the colour each text run declares and multiplies in the opacity
///    of its ancestors (exact token math, no sampling of glyphs);
/// 2. samples the background from the top and bottom pixel rows of the text
///    box, so a gradient or an image behind the text is measured at its
///    weakest part (5th percentile of those pixels);
/// 3. checks the frame: the most inked pixel in the box must lie on the line
///    from the background to the declared colour. A shader or colour filter
///    that changes the hue, or a wrong declared colour, fails here instead of
///    passing silently. (A filter that only fades the text towards the
///    background looks like anti-aliasing and is not caught; use opacity
///    widgets, which step 1 counts.)
///
/// Large text follows WCAG: at least 24 px, or 18.66 px at weight 700 or
/// more, after the text scaler. Disabled controls are exempt (WCAG 1.4.3).
const AccessibilityGuideline picoTextContrastGuideline =
    PicoTextContrastGuideline();

/// See [picoTextContrastGuideline].
class PicoTextContrastGuideline extends AccessibilityGuideline {
  /// Creates the guideline.
  const new();

  /// WCAG minimum ratio for normal text.
  static const double normal = 4.5;

  /// WCAG minimum ratio for large text.
  static const double large = 3;

  @override
  String get description =>
      'Text contrast meets WCAG 2.2 AA (declared colour over the rendered '
      'background)';

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    var result = const Evaluation.pass();
    for (final view in tester.binding.renderViews) {
      final layer = view.debugLayer! as OffsetLayer;
      final dpr = view.flutterView.devicePixelRatio;
      late final _Frame frame;
      await tester.binding.runAsync(() async {
        // Physical pixels: sample what the device would show.
        final image = await layer.toImage(view.paintBounds);
        final data = await image.toByteData();
        frame = _Frame(data!, image.width, image.height);
        image.dispose();
      });
      final paragraphs = <RenderParagraph>[];
      void visit(RenderObject o) {
        if (o is RenderParagraph) paragraphs.add(o);
        // ExcludeSemantics hides text from the screen reader, not the eye.
        if (o is RenderExcludeSemantics) {
          o.visitChildren(visit);
        } else {
          o.visitChildrenForSemantics(visit);
        }
      }

      view.visitChildren(visit);
      for (final p in paragraphs) {
        result += _evaluate(tester, view, p, frame, dpr);
      }
    }
    return result;
  }

  Evaluation _evaluate(
    WidgetTester tester,
    RenderView view,
    RenderParagraph p,
    _Frame frame,
    double dpr,
  ) {
    if (!p.attached || !p.hasSize || p.size.isEmpty) {
      return const Evaluation.pass();
    }
    final text = p.text.toPlainText(includePlaceholders: false).trim();
    // An icon is a glyph from a private-use font range: a graphic (1.4.11,
    // 3:1), not text. The token tests cover icon colours.
    final isIcon = text.runes.every(
      (r) => (r >= 0xE000 && r <= 0xF8FF) || r >= 0xF0000,
    );
    if (text.isEmpty || isIcon || _disabled(p)) {
      return const Evaluation.pass();
    }
    final opacity = _opacity(p);
    if (opacity == 0) return const Evaluation.pass();

    final box = MatrixUtils.transformRect(
      p.getTransformTo(null),
      Offset.zero & p.size,
    );
    final hit = HitTestResult();
    tester.binding.hitTestInView(hit, box.center, view.flutterView.viewId);
    if (!hit.path.any((e) => e.target == p)) return const Evaluation.pass();

    final rect = Rect.fromLTRB(
      box.left * dpr,
      box.top * dpr,
      box.right * dpr,
      box.bottom * dpr,
    );
    final ring = frame.edges(rect);
    if (ring.isEmpty) return const Evaluation.pass();

    var result = const Evaluation.pass();
    for (final run in _runs(p.text)) {
      final declared = run.color.withValues(alpha: run.color.a * opacity);
      final opaque = declared.withValues(alpha: 1);
      // Edge pixels that look like the ink itself are a glyph that reaches
      // the line box (accents, descenders), not background.
      final bg = [
        for (final c in ring)
          if (_ratio(c, opaque) > 1.15) c,
      ];
      if (bg.isEmpty) continue;
      final ratios = [for (final c in bg) (_ratio(_over(declared, c), c), c)]
        ..sort((a, b) => a.$1.compareTo(b.$1));
      final (ratio, background) = ratios[(ratios.length * .05).floor()];
      final size = p.textScaler.scale(run.fontSize);
      final isLarge =
          size >= 24 ||
          (size >= 18.66 && run.weight.value >= FontWeight.w700.value);
      final target = isLarge ? large : normal;
      final where =
          '"${_short(text)}" at ${box.topLeft} '
          '(${size.toStringAsFixed(1)} px, ${run.weight})';
      if (ratio + 0.005 < target) {
        result += Evaluation.fail(
          '$where: contrast ${ratio.toStringAsFixed(2)}:1, needs $target:1. '
          'Text ${_hex(declared)} on ${_hex(background)}.\n',
        );
        continue;
      }
      final painted = frame.inked(rect);
      if (painted == null) continue;
      final expect = _over(declared, painted.$2);
      final (t, residual) = _onLine(painted.$1, painted.$2, expect);
      final span = _dist(expect, painted.$2);
      if (t > 1.1 || residual > math.max(0.07, span * 0.2)) {
        result += Evaluation.fail(
          '$where: painted ${_hex(painted.$1)} is not ${_hex(declared)} '
          'over ${_hex(painted.$2)}; a shader, filter or opacity changes the '
          'text colour, so the declared colour cannot be trusted.\n',
        );
      }
    }
    return result;
  }

  static bool _disabled(RenderObject p) {
    for (RenderObject? o = p; o != null; o = o.parent) {
      var node = o.debugSemantics;
      if (node == null) continue;
      while (node != null) {
        final flags = node.getSemanticsData().flagsCollection;
        if (flags.isEnabled == ui.Tristate.isFalse) return true;
        if (!node.isMergedIntoParent) return false;
        node = node.parent;
      }
      return false;
    }
    return false;
  }

  static double _opacity(RenderObject p) {
    var a = 1.0;
    for (RenderObject? o = p.parent; o != null; o = o.parent) {
      a *= switch (o) {
        RenderOpacity(:final opacity) => opacity,
        RenderAnimatedOpacity(:final opacity) => opacity.value,
        RenderSliverOpacity(:final opacity) => opacity,
        RenderSliverAnimatedOpacity(:final opacity) => opacity.value,
        _ => 1,
      };
    }
    return a;
  }

  static List<_Run> _runs(InlineSpan root) {
    final seen = <(Color, double, FontWeight)>{};
    final out = <_Run>[];
    void walk(InlineSpan s, TextStyle? parent) {
      final style = parent == null ? s.style : parent.merge(s.style);
      if (s is TextSpan) {
        if ((s.text ?? '').trim().isNotEmpty) {
          final color =
              style?.foreground?.color ??
              style?.color ??
              const Color(0xFF000000);
          final run = _Run(
            color,
            style?.fontSize ?? 14,
            style?.fontWeight ?? FontWeight.w400,
          );
          if (seen.add((run.color, run.fontSize, run.weight))) out.add(run);
        }
        for (final c in s.children ?? const <InlineSpan>[]) {
          walk(c, style);
        }
      }
    }

    walk(root, null);
    return out;
  }

  static String _short(String s) =>
      s.length <= 40 ? s : '${s.substring(0, 37)}...';
}

class const _Run(
  final Color color,
  final double fontSize,
  final FontWeight weight,
);

/// The captured frame, RGBA rows.
class _Frame(final ByteData data, final int width, final int height) {
  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      255,
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }

  Rect _clip(Rect r) =>
      r.intersect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  /// The first and last pixel rows inside [r]: the text's own background,
  /// above the ascenders and below the descenders. A ring outside the box
  /// would pick up a neighbouring card edge or app bar.
  List<Color> edges(Rect r) {
    final box = _clip(r);
    if (box.isEmpty) return const [];
    final top = box.top.ceil();
    final bottom = math.max(top, box.bottom.floor() - 1);
    return [
      for (final y in {top, bottom})
        for (var x = box.left.ceil(); x < box.right.floor(); x++) at(x, y),
    ];
  }

  /// The pixel in [r] furthest from the background, with the background of
  /// its own column on the top row (a horizontal gradient stays exact).
  (Color, Color)? inked(Rect r) {
    final box = _clip(r);
    if (box.isEmpty) return null;
    (Color, Color)? best;
    var bestD = 0.0;
    final top = box.top.ceil();
    for (var y = box.top.floor(); y < box.bottom.ceil(); y++) {
      for (var x = box.left.floor(); x < box.right.ceil(); x++) {
        final c = at(x, y);
        final local = at(x, top);
        final d = _dist(c, local);
        if (d > bestD) {
          bestD = d;
          best = (c, local);
        }
      }
    }
    return best;
  }
}

double _lum(Color c) => c.computeLuminance();

double _ratio(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

double _dist(Color a, Color b) => math.sqrt(
  math.pow(a.r - b.r, 2) + math.pow(a.g - b.g, 2) + math.pow(a.b - b.b, 2),
);

/// Projects [p] on the segment [bg] to [fg]: (position, distance off it).
(double, double) _onLine(Color p, Color bg, Color fg) {
  final d = [fg.r - bg.r, fg.g - bg.g, fg.b - bg.b];
  final v = [p.r - bg.r, p.g - bg.g, p.b - bg.b];
  final dd = d[0] * d[0] + d[1] * d[1] + d[2] * d[2];
  if (dd == 0) return (0, _dist(p, bg));
  final t = (v[0] * d[0] + v[1] * d[1] + v[2] * d[2]) / dd;
  final off = math.sqrt(
    math.pow(v[0] - t * d[0], 2) +
        math.pow(v[1] - t * d[1], 2) +
        math.pow(v[2] - t * d[2], 2),
  );
  return (t, off);
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'
    '${c.a < 1 ? ' @${(c.a * 100).round()}%' : ''}';
