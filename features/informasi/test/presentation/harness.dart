import 'dart:io';

import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:informasi/src/domain/tip_source.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:informasi/src/presentation/bloc/informasi_bloc.dart';
import 'package:informasi/src/presentation/bloc/informasi_event.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Reads the real bundled articles from disk.
class DiskTipSource implements TipSource {
  const new();

  @override
  Future<String> read(String slug, String locale) async =>
      // Sync read: real I/O would need the real async zone at every step.
      File('assets/tips/$slug.$locale.md').readAsStringSync();
}

Widget host(
  Widget page, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
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
        create: (_) =>
            InformasiBloc(const DiskTipSource())..add(const TipsStarted()),
        child: page,
      ),
    ),
  ),
);

/// Real file I/O needs the real async zone.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pumpAndSettle();
}

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 3000]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
