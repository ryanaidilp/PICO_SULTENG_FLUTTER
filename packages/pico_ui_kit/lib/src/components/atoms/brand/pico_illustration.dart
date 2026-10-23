import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';

/// A brand illustration by file stem (for example `pico-state-empty`), with
/// theme colours. Decorative unless [semanticLabel] is set.
class PicoIllustration extends StatelessWidget {
  /// Creates an illustration.
  const new(
    this.name, {
    this.width,
    this.height,
    this.semanticLabel,
    super.key,
  });

  /// File stem under `assets/illustrations/`.
  final String name;

  /// Width.
  final double? width;

  /// Height.
  final double? height;

  /// Screen reader label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => PicoThemedSvg(
    'assets/illustrations/$name.svg',
    width: width,
    height: height,
    semanticLabel: semanticLabel,
  );
}
