import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:pico/app.dart';
import 'package:pico/bootstrap.dart';

import 'patrol_config.dart';

void main() {
  patrolTest('app launches without crash', config: patrolAppConfig, ($) async {
    // bootstrap installs the app's own error handlers; the test framework
    // needs its own back, or a failure never reaches Patrol and it hangs.
    final onError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = onError);

    // bootstrap calls runApp itself and builds the app only after the
    // pre-launch phase, so wait for it instead of pumping a second tree.
    await bootstrap(
      flavor: 'development',
      builder: (result) => PicoApp(router: result.requireRouter),
    );
    final app = find.byType(PicoApp);
    for (var i = 0; i < 100 && app.evaluate().isEmpty; i++) {
      await $.pump(const Duration(milliseconds: 100));
    }

    expect(app, findsOneWidget);
    FlutterError.onError = onError;
  });
}
