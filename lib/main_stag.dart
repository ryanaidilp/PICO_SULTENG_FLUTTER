import 'package:core/core.dart';

import 'package:i10n/i10n.dart';
import 'package:pico_sulteng_flutter/app.dart';
import 'package:pico_sulteng_flutter/bootstrap.dart';

void main() {
  bootstrap(
    () async {
      await Future.wait(
        [
          configureDependencies(),
        ],
      );
      return TranslationProvider(
        child: const App(),
      );
    },
  );
}
