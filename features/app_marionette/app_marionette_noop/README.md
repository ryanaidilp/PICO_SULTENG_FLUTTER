# app_marionette_noop

Release and profile twin of `app_marionette`. `ensureAppBinding` installs the
plain `WidgetsFlutterBinding` and ignores its arguments. It has no Marionette
dependency, so a release or profile build contains no Marionette code.

`build-prepare --mode release|profile` swaps `app_marionette` for this package
(the `debug_build_only` list in `build_prepare.yaml`) and rewrites the host's
imports. Keep every public name and library of `app_marionette` mirrored here:
the swap fails when a rewritten import points to a missing library.
