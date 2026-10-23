import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// A modal bottom sheet molecule with consistent design system styling.
///
/// Use the static [PicoSheet.show] method to display the sheet:
///
/// ```dart
/// final result = await PicoSheet.show<String>(
///   context: context,
///   title: 'Select Option',
///   child: Column(
///     children: [
///       ListTile(
///         title: Text('Option A'),
///         onTap: () => Navigator.pop(context, 'A'),
///       ),
///     ],
///   ),
/// );
/// ```
class const PicoSheet<T>._({
  /// The content to display inside the sheet.
  required final Widget child,

  /// Whether to add bottom padding for the keyboard.
  required final bool paddedKeyboard,
  super.key,

  /// Optional title displayed at the top of the sheet.
  final String? title,

  /// Background color override. Defaults to theme background color.
  final Color? bgColor,

  /// Called when the close button is tapped (if title is provided).
  final ValueChanged<BuildContext>? onClose,

  /// Height as a fraction of screen height (0..1].
  /// When set, the sheet uses [Expanded] instead of [Flexible].
  final double? heightFactor,

  /// Custom content padding override.
  final EdgeInsets? padding,
}) extends StatelessWidget {
  this
    : assert(
        heightFactor == null || (heightFactor > 0 && heightFactor <= 1),
        'heightFactor must be a fraction between 0 and 1',
      );

  /// Shows an [PicoSheet] as a modal bottom sheet.
  ///
  /// Returns a [Future] that resolves to the value (if any) passed to
  /// [Navigator.pop] when the sheet is closed.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool enableDrag = true,
    bool isDismissible = true,
    Color? bgColor,
    ValueChanged<BuildContext>? onClose,
    double? heightFactor,
    bool paddedKeyboard = true,
    EdgeInsets? padding,
  }) {
    final radius = context.radius;

    return showModalBottomSheet<T>(
      context: context,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: radius.border.lg.topLeft),
      ),
      builder: (_) {
        final sheet = PicoSheet<T>._(
          onClose: onClose,
          bgColor: bgColor,
          heightFactor: heightFactor,
          paddedKeyboard: paddedKeyboard,
          padding: padding,
          title: title,
          child: child,
        );

        if (heightFactor != null) {
          return FractionallySizedBox(heightFactor: heightFactor, child: sheet);
        }

        return sheet;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = context.radius;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: bgColor ?? colors.background.main,
        borderRadius: BorderRadius.vertical(top: radius.border.lg.topLeft),
      ),
      padding: (padding ?? EdgeInsets.symmetric(horizontal: spacing.md)).add(
        EdgeInsets.only(
          bottom: paddedKeyboard ? MediaQuery.viewInsetsOf(context).bottom : 0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heightFactor != null)
            Expanded(child: child)
          else
            Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
