/// Flavor-aware workspace preparation: env switch + envied regen + build-prepare.
///
/// Composes the existing env-switch and build-prepare building blocks into a
/// single idempotent `prepare` step that runs before a Flutter build.
library;

export 'src/prepare_command.dart';
export 'src/prepare_runner.dart';
export 'src/prepare_state.dart';
