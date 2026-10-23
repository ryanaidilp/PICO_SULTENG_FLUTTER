import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Draws the mark shape of a data role (square, diamond, bars, triangle, ring).
class PicoMarkPainter extends CustomPainter {
  /// Creates a painter. [size] is the side of the mark in logical pixels.
  const new({required this.mark, required this.color});

  /// Shape.
  final PicoMark mark;

  /// Fill or stroke colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final fill = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, s.width / 8);
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    switch (mark) {
      case PicoMark.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: c,
            width: s.width * .8,
            height: s.height * .8,
          ),
          fill,
        );
      case PicoMark.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy)
            ..lineTo(c.dx, c.dy + r)
            ..lineTo(c.dx - r, c.dy)
            ..close(),
          line,
        );
      case PicoMark.bars:
        final h = s.height * .28;
        canvas
          ..drawRect(
            Rect.fromLTWH(s.width * .1, s.height * .12, s.width * .8, h),
            fill,
          )
          ..drawRect(
            Rect.fromLTWH(s.width * .1, s.height * .6, s.width * .8, h),
            fill,
          );
      case PicoMark.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy + r * .85)
            ..lineTo(c.dx - r, c.dy + r * .85)
            ..close(),
          line,
        );
      case PicoMark.ring:
        canvas.drawCircle(c, r * .75, line);
    }
  }

  @override
  bool shouldRepaint(PicoMarkPainter old) =>
      old.mark != mark || old.color != color;
}

/// A mark at a fixed size. Decorative: the label next to it carries the meaning.
class PicoMarkView extends StatelessWidget {
  /// Creates a mark view.
  const new({
    required this.mark,
    required this.color,
    this.size = 14,
    super.key,
  });

  /// Shape.
  final PicoMark mark;

  /// Colour.
  final Color color;

  /// Side length.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: PicoMarkPainter(mark: mark, color: color),
    ),
  );
}

/// Draws a short sample of a series line form (solid, dotted, doubled, dashed).
class PicoLineFormPainter extends CustomPainter {
  /// Creates a painter.
  const new({required this.form, required this.color, this.dash});

  /// Line form.
  final PicoLineForm form;

  /// Colour.
  final Color color;

  /// Dash pattern in logical pixels (`PicoState.dash`).
  final List<double>? dash;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = form == PicoLineForm.dotted
          ? StrokeCap.round
          : StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final y = s.height / 2;
    void seg(double dy) {
      final d = dash;
      if (d == null) {
        canvas.drawLine(Offset(0, dy), Offset(s.width, dy), p);
        return;
      }
      var x = 0.0;
      var i = 0;
      while (x < s.width) {
        final len = d[i % d.length];
        if (i.isEven) {
          canvas.drawLine(
            Offset(x, dy),
            Offset(math.min(x + len, s.width), dy),
            p,
          );
        }
        x += len;
        i++;
      }
    }

    if (form == PicoLineForm.doubled) {
      seg(y - 2.5);
      seg(y + 2.5);
    } else {
      seg(y);
    }
  }

  @override
  bool shouldRepaint(PicoLineFormPainter old) =>
      old.form != form || old.color != color || old.dash != dash;
}
