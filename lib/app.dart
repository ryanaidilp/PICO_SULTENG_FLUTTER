// ignore_for_file: public_member_api_docs

import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/home.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final _router = PicoRouter();

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
            routerDelegate: AutoRouterDelegate(
              _router,
              navigatorObservers: () => [
                PicoRouteObserver(),
              ],
            ),
            routeInformationParser: _router.defaultRouteParser(),
            theme: PicoTheme.light(ThemeData.light()).themeData,
            darkTheme: PicoTheme.dark(ThemeData.dark()).themeData,
            locale: LocaleSettings.currentLocale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      );
}
