import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_asset_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_radius_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_shadow_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_spacing_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';

/// Extension on [BuildContext] for easy access to theme extensions.
extension PicoThemeContextExtension on BuildContext {
  PicoColorExtension get colors =>
      Theme.of(this).extension<PicoColorExtension>()!;
  PicoColorExtension? get colorsOrNull =>
      Theme.of(this).extension<PicoColorExtension>();
  PicoTypographyExtension get typography =>
      Theme.of(this).extension<PicoTypographyExtension>()!;
  PicoTypographyExtension? get typographyOrNull =>
      Theme.of(this).extension<PicoTypographyExtension>();
  PicoSpacingExtension get spacing =>
      Theme.of(this).extension<PicoSpacingExtension>()!;
  PicoSpacingExtension? get spacingOrNull =>
      Theme.of(this).extension<PicoSpacingExtension>();
  PicoRadiusExtension get radius =>
      Theme.of(this).extension<PicoRadiusExtension>()!;
  PicoRadiusExtension? get radiusOrNull =>
      Theme.of(this).extension<PicoRadiusExtension>();
  PicoShadowExtension get shadow =>
      Theme.of(this).extension<PicoShadowExtension>()!;
  PicoShadowExtension? get shadowOrNull =>
      Theme.of(this).extension<PicoShadowExtension>();
  PicoAssetExtension get assets =>
      Theme.of(this).extension<PicoAssetExtension>()!;
  PicoAssetExtension? get assetsOrNull =>
      Theme.of(this).extension<PicoAssetExtension>();
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;
}
