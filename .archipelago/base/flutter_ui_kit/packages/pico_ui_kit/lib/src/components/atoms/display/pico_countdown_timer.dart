import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/display/pico_countdown_controller.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// Display format for the countdown timer.
enum PicoCountdownFormat() {
  /// Hours, minutes, seconds (HH:MM:SS).
  hhmmss,

  /// Minutes, seconds (MM:SS).
  mmss,

  /// Seconds only (SS).
  ss,
}

/// A countdown timer widget that counts down from a [Duration] or to a
/// [DateTime].
///
/// Supports configurable format, auto-start, manual control via a controller,
/// and danger styling when time is running low.
///
/// ```dart
/// PicoCountdownTimer.duration(
///   duration: Duration(minutes: 5),
///   format: PicoCountdownFormat.mmss,
///   onFinished: () => print('Done!'),
///   dangerThreshold: Duration(seconds: 10),
///   dangerStyle: TextStyle(color: Colors.red, fontSize: 24),
/// )
/// ```
class PicoCountdownTimer extends StatefulWidget {
  /// Creates a countdown timer from a [Duration].
  const new duration({
    required this._duration,
    this.format = PicoCountdownFormat.mmss,
    this.onFinished,
    this.onTick,
    this.style,
    this.separator = ':',
    this.autoStart = true,
    this.controller,
    this.dangerThreshold,
    this.dangerStyle,
    this.padWithZeros = true,
    super.key,
  }) : _targetDate = null;

  /// Creates a countdown timer that counts down to a specific [DateTime].
  const new toDate({
    required this._targetDate,
    this.format = PicoCountdownFormat.hhmmss,
    this.onFinished,
    this.onTick,
    this.style,
    this.separator = ':',
    this.autoStart = true,
    this.controller,
    this.dangerThreshold,
    this.dangerStyle,
    this.padWithZeros = true,
    super.key,
  }) : _duration = null;

  final Duration? _duration;
  final DateTime? _targetDate;

  /// Display format for the timer.
  final PicoCountdownFormat format;

  /// Called when the countdown reaches zero.
  final VoidCallback? onFinished;

  /// Called on each tick with the remaining duration.
  final ValueChanged<Duration>? onTick;

  /// Text style for the countdown text.
  final TextStyle? style;

  /// Separator character between time segments.
  final String separator;

  /// Whether to start counting down immediately.
  final bool autoStart;

  /// Controller for pause/resume/reset.
  final PicoCountdownController? controller;

  /// Threshold below which danger styling is applied.
  final Duration? dangerThreshold;

  /// Text style applied when remaining time is below [dangerThreshold].
  final TextStyle? dangerStyle;

  /// Whether to pad single-digit values with leading zeros.
  final bool padWithZeros;

  @override
  State<PicoCountdownTimer> createState() => _PicoCountdownTimerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration?>('duration', _duration))
      ..add(DiagnosticsProperty<DateTime?>('targetDate', _targetDate))
      ..add(EnumProperty<PicoCountdownFormat>('format', format))
      ..add(DiagnosticsProperty<TextStyle?>('style', style))
      ..add(StringProperty('separator', separator))
      ..add(DiagnosticsProperty<bool>('autoStart', autoStart))
      ..add(
        DiagnosticsProperty<PicoCountdownController?>('controller', controller),
      )
      ..add(DiagnosticsProperty<Duration?>('dangerThreshold', dangerThreshold))
      ..add(DiagnosticsProperty<TextStyle?>('dangerStyle', dangerStyle))
      ..add(DiagnosticsProperty<bool>('padWithZeros', padWithZeros))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onFinished', onFinished))
      ..add(ObjectFlagProperty<ValueChanged<Duration>?>.has('onTick', onTick));
  }
}

class _PicoCountdownTimerState()
    extends State<PicoCountdownTimer>
    with PicoCountdownControllerMixin {
  Timer? _timer;
  late Duration _remaining;
  late Duration _initialDuration;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initialDuration = _computeInitialDuration();
    _remaining = _initialDuration;
    attachController(widget.controller);

    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(PicoCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      detachController(oldWidget.controller);
      attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    detachController(widget.controller);
    super.dispose();
  }

  Duration _computeInitialDuration() {
    if (widget._duration != null) return widget._duration!;
    if (widget._targetDate != null) {
      final diff = widget._targetDate!.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    }
    return Duration.zero;
  }

  void _startTimer() {
    _timer?.cancel();
    _isFinished = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (widget._targetDate != null) {
          final diff = widget._targetDate!.difference(DateTime.now());
          _remaining = diff.isNegative ? Duration.zero : diff;
        } else {
          _remaining -= const Duration(seconds: 1);
          if (_remaining.isNegative) _remaining = Duration.zero;
        }
      });
      widget.onTick?.call(_remaining);
      if (_remaining == Duration.zero && !_isFinished) {
        _isFinished = true;
        _timer?.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void onPause() {
    _timer?.cancel();
  }

  @override
  void onResume() {
    _startTimer();
  }

  @override
  void onReset() {
    _timer?.cancel();
    setState(() {
      _remaining = _computeInitialDuration();
      _isFinished = false;
    });
    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void onStart() {
    _startTimer();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    String pad(int n) =>
        widget.padWithZeros ? n.toString().padLeft(2, '0') : n.toString();

    return switch (widget.format) {
      PicoCountdownFormat.hhmmss =>
        '${pad(hours)}${widget.separator}${pad(minutes)}${widget.separator}${pad(seconds)}',
      PicoCountdownFormat.mmss =>
        '${pad(minutes)}${widget.separator}${pad(seconds)}',
      PicoCountdownFormat.ss => pad(seconds),
    };
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = (widget.style ?? context.typography.heading.h3)
        .copyWith(
          color: widget.style?.color ?? context.colors.foreground.main,
          fontFeatures: [
            ...?widget.style?.fontFeatures,
            const FontFeature.tabularFigures(),
          ],
        );

    final isInDanger =
        widget.dangerThreshold != null &&
        _remaining <= widget.dangerThreshold! &&
        _remaining > Duration.zero;

    final effectiveStyle = isInDanger
        ? (widget.dangerStyle ??
              defaultStyle.copyWith(color: context.colors.foreground.error))
        : defaultStyle;

    return Text(_formatDuration(_remaining), style: effectiveStyle);
  }
}
