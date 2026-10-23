import 'package:flutter/foundation.dart';
import 'package:locale_core/locale_core.dart';

/// The single owner of the app's **durable** locale preference.
///
/// slang's `LocaleSettings` is in-memory only: it mutates a plain in-process
/// singleton, so a locale set through it is gone the moment the process dies.
/// [AppLocaleController] is the thin layer around it that makes the choice
/// survive a cold start.
///
/// ## The contract
///
/// | Concern | Owner |
/// | --- | --- |
/// | Writing the choice to disk | `AppLocaleController.setLocale` |
/// | Restoring it before the first frame | `AppLocaleController.restore` |
/// | Where it is stored | [LocaleStore] (swap via [store]) |
/// | Applying it to a *feature-scoped* slang instance | that feature's shell |
///
/// **Every** language control in the app — the Settings toggle, a switcher on
/// an auth screen, a debug menu — must route its app-wide change through
/// [setLocale] rather than calling `LocaleSettings.setLocale` directly, or the
/// choice is not persisted. Feature-scoped `LocaleSettings.setLocale` calls
/// (e.g. `HomeLocale`) stay as they are: they exist only to rebuild that
/// feature's own `TranslationProvider` immediately.
///
/// ## Cold start
///
/// `bootstrap.dart` awaits [restore] **before `runApp`**, so the app-wide
/// locale is already correct when the first widget builds. Each feature shell
/// seeds its own scoped slang instance from
/// `app_l10n.LocaleSettings.currentLocale` in `initState` (and gates its
/// content on that sync completing), so features render the restored locale
/// from their first frame — there is no flash of the base locale.
abstract final class AppLocaleController() {
  /// The [LocaleStore] backing persistence.
  ///
  /// Assign before [restore] runs in `bootstrap.dart` to move the preference
  /// somewhere other than `SharedPreferences` (an encrypted store, a
  /// server-synced profile setting, an in-memory fake in tests).
  static LocaleStore store = const SharedPreferencesLocaleStore();

  /// Restores the default [SharedPreferencesLocaleStore].
  @visibleForTesting
  static void resetStore() => store = const SharedPreferencesLocaleStore();

  /// The locale a fresh install opens in, when the user has not chosen one.
  ///
  /// It is a build-time choice (the `defaultLocale` generator var), separate
  /// from slang's `base_locale`, which stays the reference translation file.
  static const PicoLocale defaultLocale = PicoLocale.id;

  /// Reads the persisted locale and applies it to the app-wide
  /// `LocaleSettings`.
  ///
  /// Returns the restored locale, or `null` when the user has never chosen one
  /// or when the persisted tag is no longer a locale this build ships. In
  /// that case [defaultLocale] is applied instead (not persisted, so a later
  /// change of the default still reaches users who never chose).
  ///
  /// Never throws. Failing to read a language preference must not be able to
  /// block app launch, so a storage error degrades to "no preference" — loudly
  /// in debug, silently in release.
  static Future<PicoLocale?> restore() async {
    try {
      final languageTag = await store.read();
      final locale = languageTag == null || languageTag.isEmpty
          ? null
          : localeForLanguageTag(languageTag);
      if (locale != null) {
        await LocaleSettings.setLocale(locale);
        return locale;
      }
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AppLocaleController] failed to restore locale: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    await LocaleSettings.setLocale(defaultLocale);
    return null;
  }

  /// Applies [locale] app-wide **and** persists it.
  ///
  /// The returned future completes once the translations are loaded and the
  /// choice has been written.
  ///
  /// Deliberately uses the asynchronous `LocaleSettings.setLocale` rather than
  /// `setLocaleSync`: slang generates lazily-loaded (deferred) translation
  /// libraries for this package, and `setLocaleSync` throws
  /// `Deferred library l_<locale> was not loaded` for any locale that has not
  /// already been pulled in.
  ///
  /// Unlike [restore], a write failure propagates — a silently dropped write is
  /// the exact defect this class exists to prevent. Call sites that cannot
  /// await (a `VoidCallback` such as `onTap`) should use `unawaited(...)`, which
  /// routes the error to the app's zone-level crash reporter.
  static Future<void> setLocale(PicoLocale locale) async {
    await LocaleSettings.setLocale(locale);
    await store.write(locale.languageTag);
  }

  /// Forgets the persisted preference. The next cold start uses
  /// [defaultLocale].
  static Future<void> clear() => store.clear();

  /// The locale whose `languageTag` equals [languageTag], or `null` when this
  /// build ships no such locale.
  static PicoLocale? localeForLanguageTag(String languageTag) {
    for (final locale in PicoLocale.values) {
      if (locale.languageTag == languageTag) return locale;
    }
    return null;
  }
}
