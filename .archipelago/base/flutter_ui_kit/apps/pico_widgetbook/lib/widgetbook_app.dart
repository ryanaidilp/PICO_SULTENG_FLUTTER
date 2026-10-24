// archipelago:widgetbook_showcase_imports:end
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
// archipelago:widgetbook_showcase_imports:start
import 'package:pico_widgetbook/showcase/atoms/animated_entrance_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/asset_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/avatar_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/button_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/card_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/countdown_timer_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/gradient_border_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/icon_button_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/icon_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/input_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/keyboard_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/masked_input_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/password_field_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/pin_input_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/rotating_text_showcase.dart';
import 'package:pico_widgetbook/showcase/atoms/sliding_text_showcase.dart';
import 'package:pico_widgetbook/showcase/foundations/color_showcase.dart';
import 'package:pico_widgetbook/showcase/foundations/radius_showcase.dart';
import 'package:pico_widgetbook/showcase/foundations/shadow_showcase.dart';
import 'package:pico_widgetbook/showcase/foundations/spacing_showcase.dart';
import 'package:pico_widgetbook/showcase/foundations/typography_showcase.dart';
import 'package:pico_widgetbook/showcase/molecules/otp_input_showcase.dart';
import 'package:pico_widgetbook/showcase/molecules/product_card_showcase.dart';
import 'package:pico_widgetbook/showcase/molecules/sheet_showcase.dart';
import 'package:pico_widgetbook/showcase/organisms/app_bar_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/centered_page_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/empty_state_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/error_page_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/loading_page_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/page_template_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/scaffold_template_showcase.dart';
import 'package:pico_widgetbook/showcase/templates/sliver_scaffold_showcase.dart';
import 'package:widgetbook/widgetbook.dart';

/// The main Widgetbook application for showcasing pico_ui_kit components.
///
/// Uses [MaterialThemeAddon] for light/dark theme switching and organizes
/// components using [WidgetbookComponent] and [WidgetbookUseCase] pattern.
class const WidgetbookApp({super.key}) extends StatelessWidget {
  /// Creates a new Widgetbook application instance.
  this;

  @override
  Widget build(BuildContext context) => Widgetbook.material(
    directories: [
      WidgetbookCategory(
        name: 'Foundations',
        children: [
          colorShowcaseComponent(),
          typographyShowcaseComponent(),
          spacingShowcaseComponent(),
          radiusShowcaseComponent(),
          shadowShowcaseComponent(),
        ],
      ),
      WidgetbookCategory(
        name: 'Atoms',
        children: [
          // archipelago:widgetbook_atoms:start
          buttonShowcaseComponent(),
          iconButtonShowcaseComponent(),
          cardShowcaseComponent(),
          gradientBorderShowcaseComponent(),
          inputShowcaseComponent(),
          passwordFieldShowcaseComponent(),
          pinInputShowcaseComponent(),
          keyboardShowcaseComponent(),
          maskedInputShowcaseComponent(),
          avatarShowcaseComponent(),
          iconShowcaseComponent(),
          assetShowcaseComponent(),
          animatedEntranceShowcaseComponent(),
          countdownTimerShowcaseComponent(),
          rotatingTextShowcaseComponent(),
          slidingTextShowcaseComponent(),
          // archipelago:widgetbook_atoms:end
        ],
      ),
      WidgetbookCategory(
        name: 'Molecules',
        children: [
          // archipelago:widgetbook_molecules:start
          productCardShowcaseComponent(),
          otpInputShowcaseComponent(),
          sheetShowcaseComponent(),
          // archipelago:widgetbook_molecules:end
        ],
      ),
      WidgetbookCategory(
        name: 'Organisms',
        children: [
          // archipelago:widgetbook_organisms:start
          appBarShowcaseComponent(),
          // archipelago:widgetbook_organisms:end
        ],
      ),
      WidgetbookCategory(
        name: 'Templates',
        children: [
          // archipelago:widgetbook_templates:start
          pageTemplateShowcaseComponent(),
          centeredPageShowcaseComponent(),
          scaffoldTemplateShowcaseComponent(),
          sliverScaffoldShowcaseComponent(),
          emptyStateShowcaseComponent(),
          errorPageShowcaseComponent(),
          loadingPageShowcaseComponent(),
          // archipelago:widgetbook_templates:end
        ],
      ),
    ],
    addons: [
      MaterialThemeAddon(
        themes: [
          WidgetbookTheme(name: 'Light', data: PicoTheme.light()),
          WidgetbookTheme(name: 'Dark', data: PicoTheme.dark()),
        ],
      ),
      TextScaleAddon(min: 0.8),
      ViewportAddon(Viewports.all),
    ],
  );
}
