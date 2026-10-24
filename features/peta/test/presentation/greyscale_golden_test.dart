import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peta/src/l10n/translations.g.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

import 'peta_test.dart' show big, host, repo, setup, settle;

/// T29: colour-only check. The map is drawn through a luminance filter: marks
/// differ by size, the legend gives six sizes with ranges, and values are text.
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

  testWidgets('greyscale peta', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 1500);
    await tester.pumpWidget(
      ColorFiltered(colorFilter: _grey, child: host(repo())),
    );
    await settle(tester);
    await expectLater(
      find.byType(ColorFiltered),
      matchesGoldenFile('goldens/greyscale_peta.png'),
    );
  }, tags: ['golden']);
}
