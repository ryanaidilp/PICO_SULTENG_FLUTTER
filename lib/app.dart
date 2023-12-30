// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_sulteng_flutter/router/pico_router.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => PCComponentInit(
        builder: (_) => MaterialApp.router(
          title: 'PICO SulTeng',
          routerConfig: PicoRouter().config(),
          theme: PicoTheme.light(ThemeData.light()).themeData,
          darkTheme: PicoTheme.dark(ThemeData.dark()).themeData,
          locale: LocaleSettings.currentLocale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      );
}
