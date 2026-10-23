import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'color_item.dart';

/// Font family used for all test widgets.
const _testFontFamily = 'Plus Jakarta Sans';

/// A section that groups related colors with a title.
///
/// Each child [ColorItem] auto-resolves its token name by scanning all
/// known palettes.
class const ColorSection({
  required final String title,
  required final Map<String, Color> colors,
  final double itemSize = 48.0,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: _testFontFamily,
          ),
        ),
      ),
      Wrap(
        spacing: 4,
        runSpacing: 8,
        children: colors.entries
            .map(
              (entry) => ColorItem(
                label: entry.key,
                color: entry.value,
                size: itemSize,
              ),
            )
            .toList(),
      ),
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
    properties.add(DiagnosticsProperty<Map<String, Color>>('colors', colors));
    properties.add(DoubleProperty('itemSize', itemSize));
  }
}
