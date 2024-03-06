import 'package:config/config.dart';
import 'package:core/core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:i10n/i10n.dart';
import 'package:pico_sulteng_flutter/app.dart';
import 'package:pico_sulteng_flutter/bootstrap.dart';

void main() {
  bootstrap(
    () async {
      Flavor.flavor = FlavorStatus.STAGING;
      await Future.wait(
        [
          configureDependencies(),
        ],
      );
      FlutterNativeSplash.remove();
      return TranslationProvider(
        child: const App(),
      );
    },
  );
}
