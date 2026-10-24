import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico/di/injector.dart';
import 'package:pico/router/app_router.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// The root app widget (TEMPORARY l10n wiring: Archipelago-z879t): theme mode from [SettingsRepository] (C08) and the
/// language from `locale_core`, both applied at once with no restart.
class PicoApp extends StatefulWidget {
  /// Creates the app. [settings] defaults to the one in the root container.
  const PicoApp({required this.router, this.settings, super.key});

  /// The app router.
  final AppRouter router;

  /// Settings source, replaced in tests.
  final SettingsRepository? settings;

  @override
  State<PicoApp> createState() => _PicoAppState();
}

class _PicoAppState extends State<PicoApp> {
  late final SettingsRepository _settings =
      widget.settings ?? getIt<SettingsRepository>();
  late final RouterConfig<UrlState> _config = widget.router.config(
    deepLinkBuilder: (_) => DeepLink.path(widget.router.initialPath),
    // Brick-owned: observer bricks' post_gen fill this region. auto_route
    // calls the builder once per navigator, so return new instances.
    navigatorObservers: () => [
      // archipelago:navigator_observers:start
      // archipelago:navigator_observers:end
    ],
  );
  late PicoThemeMode _mode = _settings.themeMode;
  StreamSubscription<PicoThemeMode>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _settings.themeModeChanges.listen((m) => setState(() => _mode = m));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
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
        // Brick-owned: app_debugger's post_gen fills this region.
        // archipelago:app_builder:start
        // archipelago:app_builder:end
      ),
    ),
  );
}
