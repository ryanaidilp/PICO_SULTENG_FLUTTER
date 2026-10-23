import 'package:flutter_test/flutter_test.dart';

import '../golden_test_helper.dart';

/// Runs a golden test with fonts preloaded.
///
/// App fonts (Plus Jakarta Sans, JetBrains Mono) are loaded from test/fonts/
/// before the test body is executed.
void testGoldenSceneWithFonts(
  String description,
  WidgetTesterCallback test, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
}) {
  testWidgets(
    description,
    (tester) async {
      await GoldenTestHelper.loadStandardFonts();
      await test(tester);
    },
    skip: skip ?? false,
    timeout: timeout ?? const Timeout(Duration(minutes: 2)),
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
    retry: retry,
  );
}
