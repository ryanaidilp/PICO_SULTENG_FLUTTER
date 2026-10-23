import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Section title with a selvedge rule (indigo band with sky and primary warp
/// blocks) and an optional trailing action. The title is a heading for screen
/// readers.
class PicoSectionHeader extends StatelessWidget {
  /// Creates a header.
  const new({required this.title, this.trailing, super.key});

  /// Title.
  final String title;

  /// Optional action, for example a "Lihat semua" button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final band = dark
        ? PicoBrandPalette.indigoDark
        : PicoBrandPalette.indigoLight;
    final sky = dark ? PicoBrandPalette.skyDark : PicoBrandPalette.skyLight;
    final primary = dark
        ? PicoBrandPalette.primaryDark
        : PicoBrandPalette.primaryLight;
    Widget block(Color c) =>
        ColoredBox(color: c, child: const SizedBox(width: 10, height: 4));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.typography.heading.h4),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            block(sky),
            block(primary),
            block(sky),
            Expanded(
              child: ColoredBox(color: band, child: const SizedBox(height: 2)),
            ),
          ],
        ),
      ],
    );
  }
}
