import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/foundations/icons/pico_icon_registry.dart';

/// A brand icon by registry key (for example `state.recovered`). The key is
/// persisted, never an index. An unknown key draws the `info` icon.
class PicoBrandIcon extends StatelessWidget {
  /// Creates a brand icon.
  const new(
    this.iconKey, {
    this.duotone = false,
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  });

  /// Registry key.
  final String iconKey;

  /// Use the two-tone variant.
  final bool duotone;

  /// Side length in logical pixels.
  final double size;

  /// Colour. Defaults to the ambient icon colour.
  final Color? color;

  /// Screen reader label. Null hides the icon (use next to visible text).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon =
        PicoIconRegistry.resolve(iconKey) ?? PicoIconRegistry.resolve('info')!;
    final tint =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      duotone ? icon.duotone : icon.mono,
      package: 'pico_ui_kit',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
