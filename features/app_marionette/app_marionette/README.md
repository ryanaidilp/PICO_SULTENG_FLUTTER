# app_marionette

Installs [LeanCode Marionette](https://pub.dev/packages/marionette_flutter)'s
`MarionetteBinding` in **debug builds**, so an AI agent can drive the running
app over MCP: read the widget tree, tap, enter text, scroll, take screenshots
and read logs.

## Debug builds only

Every release and profile build removes this package. `build_prepare.yaml`
lists it under `debug_build_only`, and `build-prepare --mode release|profile`
swaps it for `app_marionette_noop` (same `ensureAppBinding`, plain
`WidgetsFlutterBinding`, no Marionette dependency) for every flavor.
`build-prepare --check-leaks --mode release` fails if `app_marionette`,
`marionette_flutter`, `marionette_mcp` or `marionette_logging` is resolved for
the app. A `kDebugMode` check inside `ensureAppBinding` is a second layer.

## Usage

`bootstrap.dart` calls it before anything else touches the binding:

```dart
ensureAppBinding(isInteractiveElement: isUiKitInteractive);
```

It returns the plain binding instead when:

- the build is not debug,
- the process runs under `flutter test` (`FLUTTER_TEST`),
- a binding already exists (integration and Patrol tests install theirs first).

`isUiKitInteractive` (from the UI kit) marks the kit's buttons, text fields
and checkboxes as interactive. App logs written through `package:logger`
reach the agent's `get_logs`.

## Connect an agent

```bash
dart pub global activate marionette_mcp
claude mcp add --transport stdio marionette -- marionette_mcp   # or use .mcp.json
flutter run --flavor development -t lib/main_development.dart   # debug
```

Copy the VM service URI that `flutter run` prints (`ws://127.0.0.1:<port>/<token>=/ws`)
and ask the agent to `connect` to it.
