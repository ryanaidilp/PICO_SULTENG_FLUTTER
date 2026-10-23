import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Slide direction for [PicoSlidingText] character animations.
enum PicoSlideDirection() {
  /// Characters slide upward when transitioning.
  up,

  /// Characters slide downward when transitioning.
  down,
}

/// A text widget where individual characters animate with a slide/odometer
/// effect when the value changes.
///
/// Each character animates independently, creating a flip-clock or
/// counter-style transition. Useful for prices, scores, timers, and counters.
///
/// ```dart
/// PicoSlidingText(
///   value: '1,234.56',
///   style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
///   direction: PicoSlideDirection.up,
///   duration: Duration(milliseconds: 300),
/// )
/// ```
class const PicoSlidingText({
  /// The text value to display. When changed, characters animate.
  required final String value,

  /// Text style for the displayed text.
  final TextStyle? style,

  /// Direction characters slide when transitioning.
  final PicoSlideDirection direction = PicoSlideDirection.up,

  /// Duration of each character's slide animation.
  final Duration duration = const Duration(milliseconds: 300),

  /// Curve applied to the slide animation.
  final Curve curve = Curves.easeOutCubic,

  /// Clip behavior for the character cells.
  final Clip clipBehavior = Clip.hardEdge,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoSlidingText].
  this;

  @override
  State<PicoSlidingText> createState() => _PicoSlidingTextState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('value', value))
      ..add(DiagnosticsProperty<TextStyle?>('style', style))
      ..add(EnumProperty<PicoSlideDirection>('direction', direction))
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(DiagnosticsProperty<Curve>('curve', curve))
      ..add(EnumProperty<Clip>('clipBehavior', clipBehavior));
  }
}

class _PicoSlidingTextState() extends State<PicoSlidingText> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle =
        widget.style ??
        theme.textTheme.headlineMedium ??
        const TextStyle(fontSize: 32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.value.length; i++)
          _SlidingCharacter(
            key: ValueKey('sliding_char_$i'),
            character: widget.value[i],
            style: effectiveStyle,
            direction: widget.direction,
            duration: widget.duration,
            curve: widget.curve,
            clipBehavior: widget.clipBehavior,
          ),
      ],
    );
  }
}

/// Internal widget for a single sliding character.
class const _SlidingCharacter({
  required final String character,
  required final TextStyle style,
  required final PicoSlideDirection direction,
  required final Duration duration,
  required final Curve curve,
  required final Clip clipBehavior,
  super.key,
}) extends StatefulWidget {
  @override
  State<_SlidingCharacter> createState() => _SlidingCharacterState();
}

class _SlidingCharacterState()
    extends State<_SlidingCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _newCharSlide;
  late Animation<Offset> _oldCharSlide;
  late Animation<double> _newCharOpacity;
  late Animation<double> _oldCharOpacity;

  String _currentChar = '';
  String _oldChar = '';

  @override
  void initState() {
    super.initState();
    _currentChar = widget.character;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _setupAnimations();
  }

  void _setupAnimations() {
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    final slideMultiplier = widget.direction == PicoSlideDirection.up
        ? -1.0
        : 1.0;

    _newCharSlide = Tween<Offset>(
      begin: Offset(0, -slideMultiplier),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _oldCharSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, slideMultiplier),
    ).animate(curvedAnimation);

    _newCharOpacity = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    _oldCharOpacity = Tween<double>(begin: 1, end: 0).animate(curvedAnimation);
  }

  @override
  void didUpdateWidget(_SlidingCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration ||
        oldWidget.curve != widget.curve ||
        oldWidget.direction != widget.direction) {
      _controller.duration = widget.duration;
      _setupAnimations();
    }

    if (oldWidget.character != widget.character) {
      _oldChar = _currentChar;
      _currentChar = widget.character;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Measure the widest character to maintain consistent width
    final painter = TextPainter(
      text: TextSpan(text: 'W', style: widget.style),
      textDirection: TextDirection.ltr,
    )..layout();
    final charHeight = painter.height;

    // Measure the actual character width for proper sizing
    final charPainter = TextPainter(
      text: TextSpan(text: _currentChar, style: widget.style),
      textDirection: TextDirection.ltr,
    )..layout();
    final charWidth = charPainter.width;

    return SizedBox(
      width: charWidth,
      height: charHeight,
      child: ClipRect(
        clipBehavior: widget.clipBehavior,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Stack(
            children: [
              // Old character sliding out
              if (_oldChar.isNotEmpty && _controller.isAnimating)
                Positioned.fill(
                  child: SlideTransition(
                    position: _oldCharSlide,
                    child: Opacity(
                      opacity: _oldCharOpacity.value,
                      child: Center(child: Text(_oldChar, style: widget.style)),
                    ),
                  ),
                ),
              // New character sliding in
              Positioned.fill(
                child: _controller.isAnimating
                    ? SlideTransition(
                        position: _newCharSlide,
                        child: Opacity(
                          opacity: _newCharOpacity.value,
                          child: Center(
                            child: Text(_currentChar, style: widget.style),
                          ),
                        ),
                      )
                    : Center(child: Text(_currentChar, style: widget.style)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
