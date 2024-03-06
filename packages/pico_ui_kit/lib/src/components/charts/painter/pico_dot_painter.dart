import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class PicoDotPainter extends FlDotPainter {
  const PicoDotPainter({
    required this.color,
    required this.radius,
    required this.strokeColor,
    required this.strokeWidth,
  });
  final Color color;
  final double radius;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final shadowPath = Path();
    final size = radius + (strokeWidth / 2);
    shadowPath.addOval(
      Rect.fromCircle(
        center:
            Offset(offsetInCanvas.dx, offsetInCanvas.dy - radius - strokeWidth),
        radius: size,
      ),
    );

    canvas.drawShadow(
      shadowPath,
      Colors.grey,
      size + radius + strokeWidth,
      true,
    );

    if (strokeWidth != 0 && strokeColor.opacity != 0) {
      canvas.drawCircle(
        offsetInCanvas,
        size,
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawCircle(
      offsetInCanvas,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) =>
      a.lerp(a, b, t);

  @override
  Color get mainColor => color;

  @override
  List<Object?> get props => [
        color,
        radius,
        strokeColor,
        strokeWidth,
      ];
}
