import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A container with gradient-colored borders rendered using [CustomPainter].
///
/// Supports any [Gradient] type (linear, radial, sweep) and provides
/// convenience constructors for common patterns.
///
/// ```dart
/// PicoGradientBorderContainer(
///   gradient: LinearGradient(
///     colors: [Colors.purple, Colors.blue],
///   ),
///   borderWidth: 2,
///   borderRadius: BorderRadius.circular(12),
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Gradient border!'),
///   ),
/// )
/// ```
class const PicoGradientBorderContainer({
  /// The gradient to apply to the border.
  required final Gradient gradient,

  /// The child widget inside the container.
  required final Widget child,

  /// Width of the gradient border.
  final double borderWidth = 2.0,

  /// Border radius for the container.
  final BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),

  /// Background color for the inner area.
  final Color? backgroundColor,

  /// Padding inside the container.
  final EdgeInsetsGeometry? padding,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoGradientBorderContainer] with a custom gradient.
  this;

  /// Creates a rainbow gradient border container.
  factory rainbow({
    required Widget child,
    double borderWidth = 2.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    Key? key,
  }) => PicoGradientBorderContainer(
    key: key,
    gradient: const SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFF7F00),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFF4B0082),
        Color(0xFF8F00FF),
        Color(0xFFFF0000),
      ],
    ),
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
    padding: padding,
    child: child,
  );

  /// Creates a gradient border using the theme's primary color.
  ///
  /// Generates a gradient from a lighter to darker shade of the primary color.
  factory primary({
    required Widget child,
    required BuildContext context,
    double borderWidth = 2.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    Key? key,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(primary);

    return PicoGradientBorderContainer(
      key: key,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          hsl.withLightness((hsl.lightness + 0.15).clamp(0, 1)).toColor(),
          primary,
          hsl.withLightness((hsl.lightness - 0.15).clamp(0, 1)).toColor(),
        ],
      ),
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      padding: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? Theme.of(context).colorScheme.surface;

    return CustomPaint(
      painter: _GradientBorderPainter(
        gradient: gradient,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: borderRadius.subtract(
            BorderRadius.all(Radius.circular(borderWidth)),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Gradient>('gradient', gradient))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('padding', padding));
  }
}

/// Custom painter for rendering gradient borders.
class _GradientBorderPainter({
  required final Gradient gradient,
  required final double borderWidth,
  required final BorderRadius borderRadius,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw the border centered on the edge
    final deflatedRRect = rrect.deflate(borderWidth / 2);
    canvas.drawRRect(deflatedRRect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderRadius != borderRadius;
}
