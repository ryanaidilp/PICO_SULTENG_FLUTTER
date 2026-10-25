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
/// This guideline instead, for every visible [RenderParagraph] (including
/// text under `ExcludeSemantics`):
/// 1. reads the colour each text run declares and multiplies in the opacity
///    of its `Opacity`/`AnimatedOpacity` (and sliver) ancestors: exact token
///    math, no guessing of the ink from pixels;
/// 2. paints the paragraph again, alone, as a mask on the same physical
///    pixels, and takes as background every pixel of the text box that the
///    glyphs and their anti-aliased edges (one pixel wider) do not touch.
///    Nothing is dropped for being close to the ink colour. The ratio is the
///    2nd percentile over those pixels, so a gradient or image is measured
///    at its weak end and only stray pixels are ignored. No visible
///    background at all is a failure;
/// 3. checks the frame: where the mask covers a pixel by 60 % or more, the
///    frame must show the declared colour blended over the local background
///    by that coverage (median within 20/255), so a shader, a colour filter
///    or a wrong declared colour fails.
///
/// Large text follows WCAG: at least 24 px, or 18.66 px at weight 700 or
/// more, after the text scaler. Disabled controls are exempt (WCAG 1.4.3).
///
/// Limits:
/// - Only text that is hit-testable at the centre of its box is checked:
///   text under `IgnorePointer`, or covered at its centre, is skipped.
/// - The background is the text box only. Text whose box is all glyph has
///   nothing to measure against and fails.
/// - The frame check needs at least 3 pixels covered 60 % or more and one
///   text colour per paragraph. Paragraphs with several colours get the token
///   check only.
/// - `ShaderMask` and `TextOverflow.fade` paint through shaders the mask does
///   not reproduce; the frame check is lenient there and the declared colour
///   is used. Colour filters (`ColorFiltered`) are not counted in step 1;
///   they are only caught by the frame check.
/// - Paragraphs with inline widgets (`WidgetSpan`) are not masked; their
///   background is the most frequent colour of the box.
/// - Icon glyphs (private-use code points) are graphics (3:1, SC 1.4.11),
///   covered by the token test, not here.
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
      final todo = [
        for (final p in paragraphs)
          if (_candidate(tester, view, p)) p,
      ];
      late final _Frame frame;
      final masks = <RenderParagraph, _Mask?>{};
      await tester.binding.runAsync(() async {
        // Physical pixels: sample what the device would show.
        final image = await layer.toImage(view.paintBounds);
        final data = await image.toByteData();
        frame = _Frame(data!, image.width, image.height);
        image.dispose();
        for (final p in todo) {
          masks[p] = await _Mask.of(p, dpr);
        }
      });
      for (final p in todo) {
        result += _evaluate(p, frame, masks[p], dpr);
      }
    }
    return result;
  }

  /// Visible, enabled, hit-testable text (not an icon glyph).
  bool _candidate(WidgetTester tester, RenderView view, RenderParagraph p) {
    if (!p.attached || !p.hasSize || p.size.isEmpty) return false;
    final text = p.text.toPlainText(includePlaceholders: false).trim();
    // An icon is a glyph from a private-use font range: a graphic (1.4.11,
    // 3:1), not text. The token tests cover icon colours.
    final isIcon = text.runes.every(
      (r) => (r >= 0xE000 && r <= 0xF8FF) || r >= 0xF0000,
    );
    if (text.isEmpty || isIcon || _disabled(p) || _opacity(p) == 0) {
      return false;
    }
    final box = MatrixUtils.transformRect(
      p.getTransformTo(null),
      Offset.zero & p.size,
    );
    final hit = HitTestResult();
    tester.binding.hitTestInView(hit, box.center, view.flutterView.viewId);
    return hit.path.any((e) => e.target == p);
  }

  Evaluation _evaluate(
    RenderParagraph p,
    _Frame frame,
    _Mask? mask,
    double dpr,
  ) {
    final text = p.text.toPlainText(includePlaceholders: false).trim();
    final opacity = _opacity(p);
    final box = MatrixUtils.transformRect(
      p.getTransformTo(null),
      Offset.zero & p.size,
    );
    final where0 = '"${_short(text)}" at ${box.topLeft}';
    // Background: every pixel of the text box that the glyphs (and their
    // anti-aliased edges, one pixel wider) do not touch. Nothing is dropped
    // for looking like the ink: a ground close to the text colour is exactly
    // the failure to find.
    final ground = mask == null
        ? frame.box(box, dpr)
        : [
            for (final (x, y) in mask.background())
              if (frame.has(x, y)) frame.at(x, y),
          ];
    if (ground.isEmpty) {
      return Evaluation.fail(
        '$where0: no background pixel is visible around the text, so its '
        'contrast cannot be measured.\n',
      );
    }
    var result = const Evaluation.pass();
    for (final run in _runs(p.text)) {
      final declared = run.color.withValues(alpha: run.color.a * opacity);
      final ratios = [
        for (final c in ground) (_ratio(_over(declared, c), c), c),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      // Weakest 2 % dropped as outliers (a stray pixel of a neighbour).
      final (ratio, background) = ratios[(ratios.length * .02).floor()];
      final size = p.textScaler.scale(run.fontSize);
      final isLarge =
          size >= 24 ||
          (size >= 18.66 && run.weight.value >= FontWeight.w700.value);
      final target = isLarge ? large : normal;
      final where = '$where0 (${size.toStringAsFixed(1)} px, ${run.weight})';
      if (ratio + 0.005 < target) {
        result += Evaluation.fail(
          '$where: contrast ${ratio.toStringAsFixed(2)}:1, needs $target:1. '
          'Text ${_hex(declared)} on ${_hex(background)}.\n',
        );
        continue;
      }
      // Frame check: where the glyph fully covers a pixel, the frame must
      // show the declared colour over the local background.
      final m = mask;
      if (m == null || _runs(p.text).length > 1) continue;
      final devs = <double>[];
      for (final (x, y, cover) in m.core()) {
        if (!frame.has(x, y)) continue;
        final local = m.localGround(x, y, frame) ?? background;
        // A pixel the glyph covers by [cover] blends ink and ground.
        final expected = Color.lerp(local, _over(declared, local), cover)!;
        devs.add(_dist(frame.at(x, y), expected));
      }
      if (devs.length < 3) continue;
      devs.sort();
      final median = devs[devs.length ~/ 2];
      if (median > 0.08) {
        result += Evaluation.fail(
          '$where: the frame does not show ${_hex(declared)} where the glyphs '
          'are solid (median off by ${(median * 255).round()}/255); a shader, '
          'filter or opacity changes the text colour.\n',
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
  bool has(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      255,
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }

  /// Fallback without a mask: the most frequent colour of the box.
  List<Color> box(Rect logical, double dpr) {
    final count = <Color, int>{};
    for (
      var y = (logical.top * dpr).floor();
      y < (logical.bottom * dpr).ceil();
      y++
    ) {
      for (
        var x = (logical.left * dpr).floor();
        x < (logical.right * dpr).ceil();
        x++
      ) {
        if (has(x, y)) count.update(at(x, y), (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (count.isEmpty) return const [];
    return [count.entries.reduce((a, b) => a.value >= b.value ? a : b).key];
  }
}

/// The paragraph painted again, alone, in black: where its glyphs cover the
/// frame. Same text painter settings and the same transform, so it lands on
/// the same physical pixels.
class _Mask(
  final Uint8List alpha,
  final int left,
  final int top,
  final int width,
  final int height,
) {
  static Future<_Mask?> of(RenderParagraph p, double dpr) async {
    if (_hasPlaceholder(p.text)) return null;
    final t = p.getTransformTo(null);
    final r = MatrixUtils.transformRect(t, Offset.zero & p.size);
    final left = (r.left * dpr).floor();
    final top = (r.top * dpr).floor();
    final w = (r.right * dpr).ceil() - left;
    final h = (r.bottom * dpr).ceil() - top;
    if (w <= 0 || h <= 0) return null;
    final tp = TextPainter(
      text: p.text,
      textAlign: p.textAlign,
      textDirection: p.textDirection,
      textScaler: p.textScaler,
      maxLines: p.maxLines,
      ellipsis: p.overflow == TextOverflow.ellipsis ? '\u2026' : null,
      locale: p.locale,
      strutStyle: p.strutStyle,
      textWidthBasis: p.textWidthBasis,
      textHeightBehavior: p.textHeightBehavior,
    )..layout(minWidth: p.size.width, maxWidth: p.size.width);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)
      ..translate(-left.toDouble(), -top.toDouble())
      ..scale(dpr)
      ..transform(t.storage)
      ..clipRect(Offset.zero & p.size)
      ..saveLayer(
        null,
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0xFF000000),
            BlendMode.srcIn,
          ),
      );
    tp.paint(c, Offset.zero);
    c.restore();
    final image = await rec.endRecording().toImage(w, h);
    final data = (await image.toByteData())!;
    image.dispose();
    tp.dispose();
    final a = Uint8List(w * h);
    var max = 0;
    for (var i = 0; i < a.length; i++) {
      a[i] = data.getUint8(i * 4 + 3);
      if (a[i] > max) max = a[i];
    }
    // Translucent text colours: normalise to coverage.
    if (max > 0 && max < 255) {
      for (var i = 0; i < a.length; i++) {
        a[i] = (a[i] * 255 / max).round().clamp(0, 255);
      }
    }
    return _Mask(a, left, top, w, h);
  }

  static bool _hasPlaceholder(InlineSpan s) {
    var found = false;
    s.visitChildren((c) {
      if (c is PlaceholderSpan) found = true;
      return !found;
    });
    return found;
  }

  int _a(int x, int y) =>
      x < 0 || y < 0 || x >= width || y >= height ? 0 : alpha[y * width + x];

  /// Touched by a glyph, its anti-aliasing, or one pixel around it.
  bool _glyph(int x, int y) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (_a(x + dx, y + dy) > 4) return true;
      }
    }
    return false;
  }

  /// Frame coordinates of the box pixels no glyph touches.
  Iterable<(int, int)> background() sync* {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!_glyph(x, y)) yield (left + x, top + y);
      }
    }
  }

  /// Frame coordinates of pixels the glyphs cover by 60 % or more, with
  /// their coverage. Thin text at 1x rarely covers a pixel fully.
  Iterable<(int, int, double)> core() sync* {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final a = _a(x, y);
        if (a >= 153) yield (left + x, top + y, a / 255);
      }
    }
  }

  /// The nearest background pixel in the same column.
  Color? localGround(int fx, int fy, _Frame frame) {
    final x = fx - left;
    final y = fy - top;
    for (var d = 1; d < height; d++) {
      for (final yy in [y - d, y + d]) {
        if (yy < 0 || yy >= height || _glyph(x, yy)) continue;
        if (frame.has(fx, top + yy)) return frame.at(fx, top + yy);
      }
    }
    return null;
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

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'
    '${c.a < 1 ? ' @${(c.a * 100).round()}%' : ''}';
