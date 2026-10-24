import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico/app.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico_data_api/testing.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell_test.dart' show registryWithFeatures;

/// Opaque fills behind the content, as the framework draws them.
Iterable<Color> opaqueFills(WidgetTester tester) => [
  for (final e in find.byType(ColoredBox).evaluate())
    (e.widget as ColoredBox).color,
  for (final e in find.byType(Material).evaluate())
    if ((e.widget as Material).color != null) (e.widget as Material).color!,
].where((c) => c.a == 1);

void main() {
  testWidgets('dark mode: no light fill at any frame of a route change', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = AppRouter(registryWithFeatures());
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 892),
          platformBrightness: Brightness.dark,
        ),
        child: PicoApp(router: router, settings: FakeSettingsRepository()),
      ),
    );
    await tester.pumpAndSettle();
    final path = PicoRoutes.provinsi('72');
    final nav = router.navigatePath(path);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      for (final c in opaqueFills(tester)) {
        expect(
          c.computeLuminance(),
          lessThan(0.2),
          reason: 'light fill $c at frame $i of the route change',
        );
      }
    }
    await nav;
    await tester.pumpAndSettle();
  });

  testWidgets(
    'every route uses a plain fade: opacity follows the animation, no slide or scrim',
    (tester) async {
      final type = AppRouter(registryWithFeatures()).defaultRouteType;
      expect(type, isA<CustomRouteType>());
      final build = (type as CustomRouteType).transitionsBuilder!;
      final animation = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );
      addTearDown(animation.dispose);
      animation.value = 0.5;
      await tester.pumpWidget(
        Builder(
          builder: (context) => build(
            context,
            animation,
            kAlwaysDismissedAnimation,
            const SizedBox(key: Key('page')),
          ),
        ),
      );
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, closeTo(0.5, 0.001));
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(
        find.descendant(
          of: find.byType(FadeTransition),
          matching: find.byKey(const Key('page')),
        ),
        findsOneWidget,
      );
    },
  );

  for (final dark in [true, false]) {
    testWidgets(
      'boot screen shows the logo on the ${dark ? 'dark' : 'light'} ground without a Theme',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              platformBrightness: dark ? Brightness.dark : Brightness.light,
            ),
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: PicoBootScreen(),
            ),
          ),
        );
        final fill = tester
            .widget<ColoredBox>(find.byType(ColoredBox).first)
            .color;
        expect(
          fill,
          dark ? PicoBrandPalette.paperDark : PicoBrandPalette.paperLight,
        );
        expect(find.bySemanticsLabel('PICO SulTeng'), findsOneWidget);
      },
    );
  }
}
