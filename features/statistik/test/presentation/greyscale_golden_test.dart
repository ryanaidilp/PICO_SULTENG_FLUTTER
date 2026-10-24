import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/l10n/translations.g.dart';

import '../support.dart';
import 'area_page_test.dart' as area;
import 'rt_test.dart' as rt;

/// T29: colour-only check. Every chart page is drawn through a luminance
/// filter, so a reader cannot tell the series apart by hue. The goldens are
/// looked at once by a person (series differ by line style, marker, label and
/// legend text, never by colour alone).
const _grey = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

void main() {
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  final pages = <String, Widget Function()>{
    'province': () => area.host(
      CountingCases(sultengSeries(), provinces: provinceSummaries()),
      const AreaQuery(area: AreaRef.province('72')),
    ),
    'rt': () => rt.host(rt.RtCases(rt.nationalRt()), const AreaRef.national()),
  };

  for (final entry in pages.entries) {
    testWidgets('greyscale ${entry.key}', (tester) async {
      await area.setup(tester, AppLocale.id);
      tester.view.physicalSize = const Size(412, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ColorFiltered(colorFilter: _grey, child: entry.value()),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ColorFiltered),
        matchesGoldenFile('goldens/greyscale_${entry.key}.png'),
      );
    }, tags: ['golden']);
  }
}
