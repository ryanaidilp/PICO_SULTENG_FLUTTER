import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:vaksin/src/l10n/translations.g.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_bloc.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';
import 'package:vaksin/src/presentation/ui/pages/vaksin_page.dart';

import '../support.dart';

class CountingStats extends FakeStatsRepository {
  final Map<VaccinationScope, int> calls = {};

  @override
  Watch<VaccinationSeries> watchVaccination(
    VaccinationScope scope, {
    bool forceRefresh = false,
  }) {
    calls[scope] = (calls[scope] ?? 0) + 1;
    return super.watchVaccination(scope, forceRefresh: forceRefresh);
  }
}

CountingStats stats() => CountingStats()
  ..vaccination = {
    VaccinationScope.sulteng: sultengSeries(),
    VaccinationScope.national: nationalSeries(),
  };

FakeDirectoryRepository directory() => FakeDirectoryRepository()
  ..vaccineLocations = fakeSnapshot([mapolda, withQuota])
  ..regencies = fakeSnapshot(regencies);

Widget host(
  FakeStatsRepository s,
  FakeDirectoryRepository d, {
  Locale locale = const Locale('id'),
  ThemeData? theme,
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? PicoTheme.light(),
  locale: locale,
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
        create: (_) => VaksinBloc(s, d)..add(const VaksinStarted()),
        child: const VaksinPage(),
      ),
    ),
  ),
);

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 4000]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
