/// Debug-build UI driver for AI agents (LeanCode Marionette).
///
/// Swapped for `app_marionette_noop` in every release and profile build by
/// `build-prepare --mode` (`debug_build_only` in build_prepare.yaml).
library;

export 'src/app_binding.dart' show ensureAppBinding;
