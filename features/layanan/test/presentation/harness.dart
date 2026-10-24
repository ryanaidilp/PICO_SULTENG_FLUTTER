import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/bloc/hospitals_bloc.dart';
import 'package:layanan/src/presentation/bloc/hospitals_event.dart';
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
