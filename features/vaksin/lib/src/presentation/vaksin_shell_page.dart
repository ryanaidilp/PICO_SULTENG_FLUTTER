import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:vaksin/src/di/vaksin_container.dart';
import 'package:vaksin/src/l10n/translations.g.dart' as sl;
import 'package:vaksin/src/presentation/bloc/vaksin_bloc.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';

/// Shell page for the Vaksin feature.
///
/// Serves as the container for nested Vaksin routes and
/// owns what those pages share: a lease on the feature's
/// container and the presentation state holder.
///
/// ## Dependency Injection
///
/// The shell takes a lease on `vaksinContainer` in
/// `initState` and releases it in `dispose`. The container is built by the
/// first lease and torn down after the last release. The shell resolves
/// what the state holder needs with `_lease.get<T>()` and passes it to its
/// constructor; pages never read GetIt.
///
/// ## Scoped Localization
///
/// The shell syncs the feature-specific locale settings with the global
/// [LocaleSettings.currentLocale] on every content build.
@RoutePage()
class const VaksinShellPage({super.key}) extends StatefulWidget {
  @override
  State<VaksinShellPage> createState() => _VaksinShellPageState();
}

class _VaksinShellPageState() extends State<VaksinShellPage> {
  /// Whether the container and the initial locale are ready.
  final _isReady = ValueNotifier<bool>(false);

  late final FeatureLease _lease;
  StreamSubscription<PicoLocale>? _localeSub;

  /// The last synced locale to avoid redundant loads.
  PicoLocale? _lastSyncedLocale;

  @override
  void initState() {
    super.initState();
    _lease = vaksinContainer.acquire();
    // Follow language changes while the page is open.
    _localeSub = LocaleSettings.getLocaleStream().listen(
      (l) => unawaited(_syncLocale(l)),
    );
    // Build the content only once the container is ready.
    unawaited(
      _lease.ready
          .then((_) => _syncLocale(LocaleSettings.currentLocale))
          .catchError(_reportContainerError),
    );
  }

  @override
  void dispose() {
    unawaited(_localeSub?.cancel());
    _isReady.dispose();
    // The container is torn down after the last lease is released.
    unawaited(_lease.release().catchError(_reportContainerError));
    super.dispose();
  }

  /// Sync the feature's locale with the global locale.
  ///
  /// Only triggers setState after the locale is loaded to avoid blinking.
  Future<void> _syncLocale(PicoLocale locale) async {
    // Skip if already synced to this locale.
    if (_lastSyncedLocale == locale) return;
    _lastSyncedLocale = locale;

    // The feature's own slang follows the app-wide language.
    final featureLocale = sl.AppLocale.values.firstWhere(
      (l) => l.languageCode == locale.languageCode,
      orElse: () => sl.AppLocale.id,
    );
    await sl.LocaleSettings.setLocale(featureLocale);

    if (mounted) {
      _isReady.value = true;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _isReady,
    builder: (context, isReady, _) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isReady
          ? Builder(
              key: const ValueKey('content'),
              builder: (context) {
                // Sync locale change without showing loading indicator.
                _syncLocale(LocaleSettings.currentLocale);
                // Created once the container is ready; the provider closes
                // it with this shell. Pass it what it needs from
                // `_lease.get<T>()`.
                return sl.TranslationProvider(
                  child: BlocProvider(
                    create: (_) => VaksinBloc(
                      _lease.get<StatsRepository>(),
                      _lease.get<DirectoryRepository>(),
                    )..add(const VaksinStarted()),
                    // This route sits above the tab bar, so it brings its own
                    // Material surface, safe area and title.
                    child: Scaffold(
                      appBar: AppBar(title: Text(sl.t.title)),
                      body: const SafeArea(child: AutoRouter()),
                    ),
                  ),
                );
              },
            )
          : const Scaffold(
              key: ValueKey('loading'),
              body: Center(child: CircularProgressIndicator()),
            ),
    ),
  );
}

/// Routes a container build or teardown failure to `FlutterError.onError`
/// (and so to monitoring) instead of leaving it an unhandled async error.
void _reportContainerError(Object error, StackTrace stack) =>
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'vaksin'),
    );
