// ignore_for_file: public_member_api_docs

import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/home.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_sulteng_flutter/router/pico_router.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => BannerBloc(),
          ),
          BlocProvider(
            create: (context) => LatestStatisticBloc(),
          ),
          BlocProvider(
            create: (context) => LatestCovidTestBloc(),
          ),
        ],
        child: PCComponentInit(
          builder: (_) => MaterialApp.router(
            title: 'PICO SulTeng',
            debugShowCheckedModeBanner: false,
            routerConfig: PicoRouter().config(),
            theme: PicoTheme.light(ThemeData.light()).themeData,
            darkTheme: PicoTheme.dark(ThemeData.dark()).themeData,
            locale: LocaleSettings.currentLocale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      );
}
