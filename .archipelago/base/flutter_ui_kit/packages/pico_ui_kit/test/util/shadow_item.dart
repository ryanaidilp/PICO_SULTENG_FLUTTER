import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Font family used for all test widgets.
const _testFontFamily = 'Plus Jakarta Sans';

/// A widget that displays a shadow sample.
///
/// Shows a card with the given shadow applied and a label.
class const ShadowItem({
  /// The label to display below the shadow sample.
  required final String label,

  /// The shadow to apply.
  required final List<BoxShadow> shadow,

  /// Size of the shadow sample card.
  final double size = 80.0,

  /// Background color of the sample card.
  final Color backgroundColor = Colors.white,
  super.key,
}) extends StatelessWidget {
  /// Creates a [ShadowItem].
  this;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size + 40,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: shadow,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: _testFontFamily,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _shadowDescription,
          style: TextStyle(
            fontSize: 9,
            fontFamily: _testFontFamily,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  String get _shadowDescription {
    if (shadow.isEmpty) return 'none';
    final first = shadow.first;
    return 'blur: ${first.blurRadius.toInt()}';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(IterableProperty<BoxShadow>('shadow', shadow));
    properties.add(DoubleProperty('size', size));
    properties.add(ColorProperty('backgroundColor', backgroundColor));
  }
}
