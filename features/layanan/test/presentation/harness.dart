import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/bloc/hospitals_bloc.dart';
import 'package:layanan/src/presentation/bloc/hospitals_event.dart';
import 'package:layanan/src/presentation/ui/pages/isoman_page.dart';
import 'package:layanan/src/presentation/ui/pages/satgas_page.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import '../support.dart';

FakeDirectoryRepository directory({List<Hospital>? hospitals}) =>
    FakeDirectoryRepository()
      ..hospitals = fakeSnapshot(hospitals ?? all)
      ..regencies = fakeSnapshot(regencies);

Widget host(
  Widget page,
  FakeDirectoryRepository d, {
  ThemeData? theme,
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? PicoTheme.light(),
  locale: const Locale('id'),
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('id'), Locale('en')],
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(
      c,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: w!,
  ),
  home: TranslationProvider(
    child: Scaffold(
      body: BlocProvider(
        key: UniqueKey(),
        create: (_) => HospitalsBloc(d)..add(const HospitalsStarted()),
        child: page,
      ),
    ),
  ),
);

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 3000]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Like [host] with the four shell providers (satgas and isoman cubits too).
Widget hostAll(
  Widget page, {
  FakeDirectoryRepository? dir,
  FakeContentRepository? content,
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
}) {
  final d = dir ?? directory();
  final c = content ?? FakeContentRepository();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? PicoTheme.light(),
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('id'), Locale('en')],
    builder: (ctx, w) => MediaQuery(
      data: MediaQuery.of(
        ctx,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: w!,
    ),
    home: TranslationProvider(
      child: Scaffold(
        body: MultiBlocProvider(
          key: UniqueKey(),
          providers: [
            BlocProvider(
              create: (_) => HospitalsBloc(d)..add(const HospitalsStarted()),
            ),
            BlocProvider(create: (_) => SatgasCubit(d.watchTaskForces)),
            BlocProvider(create: (_) => DonationsCubit(c.watchDonations)),
            BlocProvider(
              create: (_) => TelemedicineCubit(c.watchTelemedicines),
            ),
          ],
          child: page,
        ),
      ),
    ),
  );
}
