import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/ui/pages/isoman_page.dart';
import 'package:layanan/src/presentation/ui/pages/satgas_page.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';

import '../support.dart';
import 'harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(PicoSvgSource.clearCache);

  final content = FakeContentRepository()
    ..donations = fakeSnapshot([donation])
    ..telemedicines = fakeSnapshot(doctors);

  testWidgets('golden satgas open light x1', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 1400);
    await tester.pumpWidget(
      hostAll(
        const SatgasPage(),
        dir: directory()..taskForces = fakeSnapshot(taskForces),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Banggai').last);
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/satgas_light_x1.png'),
    );
  }, tags: ['golden']);

  testWidgets('golden isoman donation dark x1', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 1700);
    await tester.pumpWidget(
      hostAll(const IsomanPage(), content: content, theme: PicoTheme.dark()),
    );
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/isoman_donation_dark.png'),
    );
  }, tags: ['golden']);

  testWidgets('golden isoman telemedicine light x2', (tester) async {
    await setup(tester, AppLocale.id);
    big(tester, 2600);
    await tester.pumpWidget(
      hostAll(const IsomanPage(), content: content, scale: 2),
    );
    await _settle(tester);
    await tester.tap(find.text('Telemedicine'));
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/isoman_telemedicine_light_x2.png'),
    );
  }, tags: ['golden']);
}
