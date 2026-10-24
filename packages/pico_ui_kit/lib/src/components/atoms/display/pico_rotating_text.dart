import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// Motion curves used for rotating text animations.
class const PicoMotionCurves._() {
  /// Curve for elements moving out of view.
  static const moveOut = Cubic(0.2, 1, 0.3, 1);

  /// Curve for elements moving into view.
  static const moveIn = Cubic(0.3, 0.28, 0.6, 1);
}

/// A widget that rotates through a list of text labels with smooth animation.
///
/// The text scrolls up and fades out while the next label scrolls in from
/// below. Useful for displaying rotating taglines, titles, or status messages.
///
/// ```dart
/// PicoRotatingText(
///   labels: [
///     TextSpan(text: 'Welcome'),
///     TextSpan(text: 'Hello'),
///     TextSpan(text: 'Hi there'),
///   ],
///   style: context.typography.heading.h3,
/// )
/// ```
class const PicoRotatingText({
  /// The list of TextSpan labels to rotate through.
  required final List<TextSpan> labels,

  /// Optional text style applied to all labels.
  final TextStyle? style,

  /// Duration of the scroll/fade animation between labels.
  final Duration animationDuration = const Duration(milliseconds: 600),

  /// Duration to pause on each label before rotating.
  final Duration pauseDuration = const Duration(milliseconds: 1500),
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoRotatingText].
  this;

  @override
  State<PicoRotatingText> createState() => _PicoRotatingTextState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<TextSpan>('labels', labels))
      ..add(DiagnosticsProperty<TextStyle?>('style', style))
      ..add(
        DiagnosticsProperty<Duration>('animationDuration', animationDuration),
      )
      ..add(DiagnosticsProperty<Duration>('pauseDuration', pauseDuration));
  }
}

class _PicoRotatingTextState()
    extends State<PicoRotatingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scrollAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _fadeInAnimation;

  int _currentIndex = 0;

  TextSpan get _currentLabel => widget.labels[_currentIndex];
  TextSpan get _nextLabel =>
      widget.labels[(_currentIndex + 1) % widget.labels.length];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(PicoRotatingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration ||
        oldWidget.pauseDuration != widget.pauseDuration) {
      _controller.dispose();
      _setupAnimations();
      _controller.forward();
    }
  }

  void _setupAnimations() {
    final totalDuration = widget.pauseDuration + widget.animationDuration;
    _controller = AnimationController(vsync: this, duration: totalDuration);

    final totalMs = totalDuration.inMilliseconds;
    final pauseMs = widget.pauseDuration.inMilliseconds;
    final animationStart = pauseMs / totalMs;
    const animationEnd = 1.0;

    _scrollAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          animationStart,
          animationEnd,
          curve: PicoMotionCurves.moveIn,
        ),
      ),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          animationStart,
          animationStart + (animationEnd - animationStart) * 0.6,
          curve: Curves.easeOut,
        ),
      ),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          animationStart + (animationEnd - animationStart) * 0.4,
          animationEnd,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.addStatusListener(_statusListener);
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _updateLabels();
      _controller.forward(from: 0);
    }
  }

  void _updateLabels() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.labels.length;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = (widget.style ?? context.typography.body.regular)
        .copyWith(color: widget.style?.color ?? context.colors.foreground.main);
    final direction = Directionality.of(context);

    var maxWidth = 0.0;
    var textHeight = 0.0;
    for (final label in widget.labels) {
      final tp = TextPainter(
        text: TextSpan(text: label.toPlainText(), style: defaultStyle),
        textDirection: direction,
      )..layout();
      if (tp.width > maxWidth) maxWidth = tp.width;
      if (tp.height > textHeight) textHeight = tp.height;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => SizedBox(
        width: maxWidth,
        height: textHeight,
        child: CustomPaint(
          size: Size(maxWidth, textHeight),
          painter: _RotatingTextPainter(
            currentLabel: _currentLabel,
            nextLabel: _nextLabel,
            textStyle: defaultStyle,
            scrollProgress: _scrollAnimation.value,
            currentOpacity: _fadeOutAnimation.value,
            nextOpacity: _fadeInAnimation.value,
            textDirection: direction,
            textHeight: textHeight,
          ),
        ),
      ),
    );
  }
}

class _RotatingTextPainter({
  required final TextSpan currentLabel,
  required final TextSpan nextLabel,
  required final TextStyle textStyle,
  required final double scrollProgress,
  required final double currentOpacity,
  required final double nextOpacity,
  required final TextDirection textDirection,
  required final double textHeight,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final currentTextPainter = TextPainter(
      text: TextSpan(
        text: currentLabel.toPlainText(),
        style: textStyle.copyWith(
          color: (textStyle.color ?? Colors.black).withValues(
            alpha: currentOpacity,
          ),
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final nextTextPainter = TextPainter(
      text: TextSpan(
        text: nextLabel.toPlainText(),
        style: textStyle.copyWith(
          color: (textStyle.color ?? Colors.black).withValues(
            alpha: nextOpacity,
          ),
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final currentOffset = Offset(0, -scrollProgress * textHeight);
    currentTextPainter.paint(canvas, currentOffset);

    final nextOffset = Offset(0, textHeight * (1 - scrollProgress));
    nextTextPainter.paint(canvas, nextOffset);
  }

  @override
  bool shouldRepaint(covariant _RotatingTextPainter oldDelegate) =>
      oldDelegate.scrollProgress != scrollProgress ||
      oldDelegate.currentOpacity != currentOpacity ||
      oldDelegate.nextOpacity != nextOpacity ||
      oldDelegate.currentLabel != currentLabel ||
      oldDelegate.nextLabel != nextLabel ||
      oldDelegate.textHeight != textHeight;
}
