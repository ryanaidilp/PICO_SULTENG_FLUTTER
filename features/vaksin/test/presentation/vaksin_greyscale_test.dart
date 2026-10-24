import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';
import 'package:vaksin/src/l10n/translations.g.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';

import '../support.dart';
import 'harness.dart';

void main() {
  setUp(() {
    WeaveShaderCache.instance.clear();
    PicoSvgSource.clearCache();
  });

  testWidgets('dose 1 and dose 2 differ by pattern and label in greyscale', (
    tester,
  ) async {
    await setup(tester, AppLocale.id);
    tester.view.physicalSize = const Size(412, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => WeaveShaderCache.instance.warmUp(Brightness.light, 1),
    );
    await tester.pumpWidget(
      ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: host(stats(), directory()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ColorFiltered),
      matchesGoldenFile('goldens/vaksin_greyscale.png'),
    );
  }, tags: ['golden']);
}
