import 'package:locale_core/locale_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The default [LocaleStore] — one string key in `SharedPreferences`.
///
/// ## Why `SharedPreferences` and not `storage_sdk`
///
/// `locale_core` is a core package generated for *every* project, before and
/// independently of any storage SDK. `storage_sdk` is optional (a project may
/// never select it) and, when present, is resolved through `GetIt` — a
/// dependency `locale_core` deliberately does not take, because the locale
/// must be restorable *before* `initializeInjector()` has run. Depending on
/// it would invert the dependency direction and break the default
/// configuration.
///
/// `shared_preferences` is already in every generated project's dependency
/// graph (`shared/consent_impl` stores the consent record with it), so this
/// costs no new package — only a direct declaration of one that was already
/// resolved.
///
/// Encryption is deliberately not used: the value is a two-letter language tag
/// the user picked from a visible menu, and Keychain/EncryptedSharedPreferences
/// reads are markedly slower on the cold-start path this sits on.
class const SharedPreferencesLocaleStore() implements LocaleStore {
  /// Preferences key holding the persisted language tag.
  ///
  /// Versioned (`.v1`) so a future format change can migrate rather than
  /// silently misread an old value.
  static const String storageKey = 'archipelago.locale.language_tag.v1';

  @override
  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(storageKey);
  }

  @override
  Future<void> write(String languageTag) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, languageTag);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storageKey);
  }
}
