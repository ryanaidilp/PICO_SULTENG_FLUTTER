import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Font family used for all test widgets.
const _testFontFamily = 'SourceSans3';

/// Data class representing a typography style for golden tests.
@immutable
class const TypographyItem({
  /// Human readable label (e.g., "Display Large").
  required final String label,

  /// Class/method name for reference (e.g., "display.large").
  required final String className,

  /// The text style to display.
  required final TextStyle style,
}) {
  /// Creates a [TypographyItem].
  this;
}

/// A widget that displays a single typography sample.
///
/// Shows the style name, sample text, and style properties.
class const TypographyItemWidget({
  /// The typography item to display.
  required final TypographyItem item,

  /// Sample text to render.
  final String sampleText = 'The quick brown fox',
  super.key,
}) extends StatelessWidget {
  /// Creates a [TypographyItemWidget].
  this;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: _testFontFamily,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                item.className,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: _testFontFamily,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '${item.style.fontSize?.toInt() ?? '-'}px',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: _testFontFamily,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                _fontWeightName(item.style.fontWeight),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: _testFontFamily,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sampleText,
          style: item.style.copyWith(color: Colors.black),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Divider(height: 16),
      ],
    ),
  );

  String _fontWeightName(FontWeight? weight) {
    if (weight == null) return 'normal';
    return switch (weight) {
      FontWeight.w100 => 'Thin',
      FontWeight.w200 => 'ExtraLight',
      FontWeight.w300 => 'Light',
      FontWeight.w400 => 'Regular',
      FontWeight.w500 => 'Medium',
      FontWeight.w600 => 'SemiBold',
      FontWeight.w700 => 'Bold',
      FontWeight.w800 => 'ExtraBold',
      FontWeight.w900 => 'Black',
      _ => 'normal',
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TypographyItem>('item', item));
    properties.add(StringProperty('sampleText', sampleText));
  }
}
