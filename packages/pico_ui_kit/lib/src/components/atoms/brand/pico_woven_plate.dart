import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// The shared illustration frame (DESIGN.md): a tint disc with a faint warp and
/// weft, bound by a woven ring, with at most one crimson knot.
class PicoWovenPlate extends StatelessWidget {
  /// Creates a plate around [child].
  const new({
    required this.child,
    this.knot = true,
    this.size = 200,
    super.key,
  });

  /// Content, drawn inside the ring.
  final Widget child;

  /// Draw the single crimson knot.
  final bool knot;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PlatePainter(
          tint: dark ? PicoBrandPalette.tintDark : PicoBrandPalette.tintLight,
          thread: dark ? PicoBrandPalette.lineDark : PicoBrandPalette.lineLight,
          ring: dark
              ? PicoBrandPalette.indigoDark
              : PicoBrandPalette.indigoLight,
          knot: knot
              ? (dark
                    ? PicoBrandPalette.crimsonDark
                    : PicoBrandPalette.crimsonLight)
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  new({
    required this.tint,
    required this.thread,
    required this.ring,
    this.knot,
  });

  final Color tint;
  final Color thread;
  final Color ring;
  final Color? knot;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = tint);
    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final p = Paint()
      ..color = thread.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y <= size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    canvas.restore();
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = ring,
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = tint,
    );
    final k = knot;
    if (k != null) {
      canvas.drawCircle(c + Offset(r * 0.72, -r * 0.72), 5, Paint()..color = k);
    }
  }

  @override
  bool shouldRepaint(_PlatePainter o) =>
      o.tint != tint || o.thread != thread || o.ring != ring || o.knot != knot;
}
