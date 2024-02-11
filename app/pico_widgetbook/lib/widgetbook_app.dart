import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_widgetbook/widgetbook_app.directories.g.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) => TranslationProvider(
        child: PCComponentInit(
          builder: (_) => Widgetbook.material(
            directories: directories,
            addons: [
              TextScaleAddon(
                scales: [1.0, 1.1],
                initialScale: 1,
              ),
              ZoomAddon(),
              InspectorAddon(enabled: true),
              DeviceFrameAddon(
                devices: [
                  Devices.ios.iPhone13ProMax,
                  Devices.ios.iPhone12ProMax,
                  Devices.ios.iPhoneSE,
                  Devices.android.bigPhone,
                  Devices.android.samsungGalaxyA50,
                  Devices.android.samsungGalaxyS20,
                  Devices.android.onePlus8Pro,
                  Devices.android.mediumPhone,
                ],
                initialDevice: Devices.android.samsungGalaxyA50,
              ),
              MaterialThemeAddon(
                themes: [
                  WidgetbookTheme(
                    name: 'Light',
                    data: PicoTheme.light(ThemeData.light()).themeData,
                  ),
                  WidgetbookTheme(
                    name: 'Dark',
                    data: PicoTheme.dark(ThemeData.dark()).themeData,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
