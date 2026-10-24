import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico/di/injector.dart';
import 'package:pico/host/push/push_tap_router.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// The root app widget (TEMPORARY l10n wiring: Archipelago-z879t): theme mode from [SettingsRepository] (C08) and the
/// language from `locale_core`, both applied at once with no restart.
class PicoApp extends StatefulWidget {
  /// Creates the app. [settings] defaults to the one in the root container.
  const PicoApp({
    required this.router,
    this.settings,
    this.pushTaps,
    super.key,
  });

  /// The app router.
  final AppRouter router;

  /// Notification taps, replaced in tests. Defaults to the one the bootstrap
  /// registered, if push exists.
  final PushTapRouter? pushTaps;

  /// Settings source, replaced in tests.
  final SettingsRepository? settings;

  @override
  State<PicoApp> createState() => _PicoAppState();
}

class _PicoAppState extends State<PicoApp> {
  late final SettingsRepository _settings =
      widget.settings ?? getIt<SettingsRepository>();
  late final RouterConfig<UrlState> _config = widget.router.config(
    // A cold start by a notification tap opens its route as the first
    // route; Beranda otherwise. Setting it here (not after the first
    // frame) keeps the router's own initial navigation from overriding it.
    deepLinkBuilder: (_) =>
        DeepLink.path(_coldStartRoute ?? widget.router.initialPath),
    // Brick-owned: observer bricks' post_gen fill this region. auto_route
    // calls the builder once per navigator, so return new instances.
    navigatorObservers: () => [
      // archipelago:navigator_observers:start
      // archipelago:navigator_observers:end
    ],
  );
  late PicoThemeMode _mode = _settings.themeMode;
  StreamSubscription<PicoThemeMode>? _sub;
  late final PushTapRouter? _taps = widget.pushTaps ?? _registeredTapRouter();

  /// The route of the tap that cold-started the app, read before any frame.
  String? _coldStartRoute;

  @override
  void initState() {
    super.initState();
    _sub = _settings.themeModeChanges.listen((m) => setState(() => _mode = m));
    // Notification taps open their route once the router has built its first
    // frame (a cold-start tap waits in the PushTapRouter until then).
    // Read now: the router asks for its first route only after this frame.
    _coldStartRoute = _taps?.takePending();
    final taps = _taps;
    if (taps != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        taps.attach((path) => unawaited(widget.router.navigatePath(path)));
      });
    }
  }

  static PushTapRouter? _registeredTapRouter() =>
      getIt.isRegistered<PushTapRouter>() ? getIt<PushTapRouter>() : null;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _taps?.detach();
    super.dispose();
  }

  ThemeMode get _themeMode => switch (_mode) {
    PicoThemeMode.system => ThemeMode.system,
    PicoThemeMode.light => ThemeMode.light,
    PicoThemeMode.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) => TranslationProvider(
    child: Builder(
      builder: (context) => MaterialApp.router(
        title: 'PICO Sulteng',
        debugShowCheckedModeBanner: false,
        theme: PicoTheme.light(),
        darkTheme: PicoTheme.dark(),
        themeMode: _themeMode,
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _config,
        // The themed colour sits under every route: no light frame.
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
        // Brick-owned: app_debugger's post_gen fills this region.
        // archipelago:app_builder:start
        // archipelago:app_builder:end
      ),
    ),
  );
}
