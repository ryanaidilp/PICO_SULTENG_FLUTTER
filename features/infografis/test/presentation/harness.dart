import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:infografis/src/presentation/bloc/infografis_bloc.dart';
import 'package:infografis/src/presentation/bloc/infografis_event.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Image hosts that never answer: the missing state shows at once.
const dead = 'https://banuacoders.com/x.png';

Infographic item(int id, {int images = 3}) => Infographic(
  id: id,
  title: 'Infografis $id',
  source: Uri.parse('https://www.instagram.com/p/$id/'),
  imageUrls: List.filled(images, dead),
);

/// Pages of two items, newest first, [pages] pages; the last has no next.
class PagedContent extends FakeContentRepository {
  new({this.pages = 3});

  final int pages;
  final List<int> requested = [];

  @override
  Watch<InfographicPage> watchInfographics({
    required int page,
    bool forceRefresh = false,
  }) {
    requested.add(page);
    final first = 100 - (page - 1) * 2;
    return Stream.value(
      fakeSnapshot(
        InfographicPage(
          items: [item(first), item(first - 1)],
          page: page,
          hasNext: page < pages,
        ),
      ),
    );
  }
}

Widget host(
  Widget page,
  FakeContentRepository c, {
  ThemeData? theme,
  double scale = 1,
  Locale locale = const Locale('id'),
}) => MaterialApp(
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
      body: BlocProvider(
        key: UniqueKey(),
        create: (_) => InfografisBloc(c)..add(const InfografisStarted()),
        child: page,
      ),
    ),
  ),
);

Future<void> setup(WidgetTester tester, AppLocale l) =>
    tester.runAsync(() => LocaleSettings.setLocale(l));

void big(WidgetTester tester, [double h = 2400]) {
  tester.view.physicalSize = Size(412, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
