import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that adjusts its padding based on keyboard visibility.
///
/// When the keyboard is shown, it adds bottom padding equal to the
/// keyboard height to ensure content remains visible above the keyboard.
///
/// ```dart
/// KeyboardAttachable(
///   child: Column(
///     children: [
///       TextField(),
///       PicoButton(label: 'Submit', onPressed: () {}),
///     ],
///   ),
/// )
/// ```
class const KeyboardAttachable({
  /// The child widget to wrap.
  required final Widget child,

  /// Optional background color behind the keyboard padding area.
  final Color? backgroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates a [KeyboardAttachable].
  this;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      color: backgroundColor,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
  }
}
