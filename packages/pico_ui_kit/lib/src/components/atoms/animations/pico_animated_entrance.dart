import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Default animation duration for entrance transitions.
const kPicoEntranceAnimationDuration = Duration(milliseconds: 300);

/// A widget that animates its child with a slide fade entrance.
///
/// When the widget appears, it slides up and fades in.
/// When it disappears, it slides down and fades out.
///
/// ```dart
/// PicoAnimatedEntrance(
///   child: Text('Hello'),
/// )
/// ```
class const PicoAnimatedEntrance({
  /// The child widget to animate.
  required final Widget child,

  /// The duration of the animation.
  final Duration duration = kPicoEntranceAnimationDuration,

  /// The curve used for the animation.
  final Curve curve = Curves.easeOut,

  /// Optional delay before the animation starts.
  final Duration delay = Duration.zero,

  /// The vertical slide offset (as a fraction of the parent height).
  final double slideOffset = 0.15,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoAnimatedEntrance].
  this;

  @override
  State<PicoAnimatedEntrance> createState() => _PicoAnimatedEntranceState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(DiagnosticsProperty<Curve>('curve', curve))
      ..add(DiagnosticsProperty<Duration>('delay', delay))
      ..add(DoubleProperty('slideOffset', slideOffset));
  }
}

class _PicoAnimatedEntranceState()
    extends State<PicoAnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) {
      await _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fadeAnimation,
    child: SlideTransition(position: _slideAnimation, child: widget.child),
  );
}

/// A widget that conditionally shows/hides content with slide fade animation.
///
/// Uses [AnimatedSwitcher] internally to animate between visible/hidden states.
///
/// ```dart
/// PicoAnimatedVisibility(
///   visible: isLoading,
///   child: CircularProgressIndicator(),
/// )
/// ```
class const PicoAnimatedVisibility({
  /// Whether the child is visible.
  required final bool visible,

  /// The child widget to show/hide.
  required final Widget child,

  /// The duration of the animation.
  final Duration duration = kPicoEntranceAnimationDuration,

  /// The vertical slide offset for animation.
  final double slideOffset = 0.3,

  /// Whether to maintain the state when hidden.
  final bool maintainState = false,

  /// Whether to maintain the size when hidden.
  final bool maintainSize = false,

  /// The replacement widget when hidden.
  final Widget replacement = const SizedBox.shrink(),
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoAnimatedVisibility].
  this;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, slideOffset),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: visible
        ? KeyedSubtree(key: const ValueKey('visible'), child: child)
        : KeyedSubtree(
            key: const ValueKey('hidden'),
            child: maintainSize
                ? Visibility(
                    visible: false,
                    maintainState: maintainState,
                    maintainSize: true,
                    maintainAnimation: true,
                    child: child,
                  )
                : replacement,
          ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('visible', visible))
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(DoubleProperty('slideOffset', slideOffset))
      ..add(DiagnosticsProperty<bool>('maintainState', maintainState))
      ..add(DiagnosticsProperty<bool>('maintainSize', maintainSize));
  }
}

/// A widget that animates content transitions with slide fade effect.
///
/// Similar to [AnimatedSwitcher] but with preconfigured slide fade animation.
///
/// ```dart
/// PicoAnimatedSwitcher(
///   child: isLoading
///       ? LoadingWidget(key: ValueKey('loading'))
///       : ContentWidget(key: ValueKey('content')),
/// )
/// ```
class const PicoAnimatedSwitcher({
  /// The current child widget to display.
  required final Widget child,

  /// The duration of the animation.
  final Duration duration = kPicoEntranceAnimationDuration,

  /// The vertical slide offset for animation.
  final double slideOffset = 0.3,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoAnimatedSwitcher].
  this;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, slideOffset),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(DoubleProperty('slideOffset', slideOffset));
  }
}
