import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// Scrolls [child] into view above the keyboard when [focusNode] gains
/// focus, leaving [padding] of breathing room instead of a flush edge.
///
/// Wrap a single field (typically an `PicoTextField`) inside a
/// scrollable ancestor such as `PicoPageTemplate`. Re-checks on
/// every keyboard show/hide via `WidgetsBindingObserver.didChangeMetrics`, so
/// it keeps the field visible if the keyboard toggles while the field is
/// already focused.
///
/// ```dart
/// final _emailFocus = FocusNode();
///
/// AppEnsureFieldVisible(
///   focusNode: _emailFocus,
///   child: PicoTextField(focusNode: _emailFocus, label: 'Email'),
/// )
/// ```
class const AppEnsureFieldVisible({
  /// The wrapped field.
  required final Widget child,

  /// Focus node to observe. Created and owned internally when omitted.
  final FocusNode? focusNode,

  /// Breathing room, in logical pixels, kept above the keyboard. Defaults to
  /// `context.spacing.md`.
  final double? padding,

  /// Duration of the reveal scroll animation.
  final Duration duration = const Duration(milliseconds: 200),

  /// Curve of the reveal scroll animation.
  final Curve curve = Curves.easeInOutCubicEmphasized,
  super.key,
}) extends StatefulWidget {
  /// Creates an [AppEnsureFieldVisible].
  this;

  @override
  State<AppEnsureFieldVisible> createState() => _AppEnsureFieldVisibleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode))
      ..add(DoubleProperty('padding', padding))
      ..add(DiagnosticsProperty<Duration>('duration', duration));
  }
}

class _AppEnsureFieldVisibleState()
    extends State<AppEnsureFieldVisible>
    with WidgetsBindingObserver {
  static const _maxWaitFrames = 60;
  static const _fallbackSettleDelay = Duration(milliseconds: 120);
  static const _requiredStableFrames = 2;

  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _revealInFlight = false;

  @override
  void initState() {
    super.initState();
    _bindFocusNode(widget.focusNode);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant AppEnsureFieldVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) _focusNode.dispose();
      _bindFocusNode(widget.focusNode);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _bindFocusNode(FocusNode? external) {
    _ownsFocusNode = external == null;
    _focusNode = external ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) unawaited(_awaitKeyboardThenReveal());
  }

  @override
  void didChangeMetrics() {
    if (_focusNode.hasFocus) unawaited(_awaitKeyboardThenReveal());
  }

  double get _bottomInset => MediaQuery.viewInsetsOf(context).bottom;

  /// Waits for the keyboard to open, then for consecutive frames to report
  /// the same inset -- a cleaner "the show animation settled" signal than a
  /// fixed delay -- before revealing. Bounded by [_maxWaitFrames] rather than
  /// a wall-clock duration, since frame delivery (not elapsed time) is what
  /// actually drives the signal; falls back to [_fallbackSettleDelay] if the
  /// budget runs out before the inset stabilizes.
  Future<void> _awaitKeyboardThenReveal() async {
    if (_revealInFlight || !mounted) return;
    _revealInFlight = true;
    try {
      var framesWaited = 0;
      while (mounted && _bottomInset <= 0) {
        if (framesWaited++ >= _maxWaitFrames) return;
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;

      var lastInset = _bottomInset;
      var stableFrames = 0;
      framesWaited = 0;
      while (mounted && stableFrames < _requiredStableFrames) {
        if (framesWaited++ >= _maxWaitFrames) {
          await Future<void>.delayed(_fallbackSettleDelay);
          break;
        }
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final current = _bottomInset;
        if (current == lastInset) {
          stableFrames++;
        } else {
          stableFrames = 0;
          lastInset = current;
        }
      }

      if (!mounted || !_focusNode.hasFocus) return;
      _reveal();
    } finally {
      _revealInFlight = false;
    }
  }

  void _reveal() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;

    final resolvedPadding = widget.padding ?? context.spacing.md;
    final paddedRect = (Offset.zero & renderObject.size).inflate(
      resolvedPadding,
    );

    final position = scrollable.position;
    final leadingEdge = viewport
        .getOffsetToReveal(renderObject, 0, rect: paddedRect)
        .offset;
    final trailingEdge = viewport
        .getOffsetToReveal(renderObject, 1, rect: paddedRect)
        .offset;

    double? target;
    if (position.pixels > leadingEdge) {
      target = leadingEdge;
    } else if (position.pixels < trailingEdge) {
      target = trailingEdge;
    }
    if (target == null) return;

    unawaited(
      position.animateTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
        duration: widget.duration,
        curve: widget.curve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
