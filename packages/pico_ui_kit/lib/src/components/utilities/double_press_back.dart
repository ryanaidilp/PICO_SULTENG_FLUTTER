import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that requires the user to press back twice to exit.
///
/// On the first back press, a snackbar is shown with a configurable
/// message. If the user presses back again within the [exitDuration],
/// the pop action proceeds. Otherwise, the timer resets.
///
/// ```dart
/// DoublePressBack(
///   message: 'Press back again to exit',
///   child: Scaffold(...),
/// )
/// ```
class const DoublePressBack({
  /// The child widget to wrap.
  required final Widget child,

  /// The message to show on the first back press.
  final String message = 'Press back again to exit',

  /// Duration within which the second press must occur.
  final Duration exitDuration = const Duration(seconds: 2),

  /// Duration the snackbar is visible.
  final Duration snackBarDuration = const Duration(seconds: 2),
  super.key,
}) extends StatefulWidget {
  /// Creates a [DoublePressBack].
  this;

  @override
  State<DoublePressBack> createState() => _DoublePressBackState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(DiagnosticsProperty<Duration>('exitDuration', exitDuration))
      ..add(
        DiagnosticsProperty<Duration>('snackBarDuration', snackBarDuration),
      );
  }
}

class _DoublePressBackState() extends State<DoublePressBack> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;

      final now = DateTime.now();
      final lastPress = _lastBackPressTime;

      if (lastPress != null &&
          now.difference(lastPress) < widget.exitDuration) {
        Navigator.of(context).pop();
        return;
      }

      _lastBackPressTime = now;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(widget.message),
            duration: widget.snackBarDuration,
          ),
        );
    },
    child: widget.child,
  );
}
