import 'package:flutter_test/flutter_test.dart';
import 'package:locale_core/locale_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [LocaleStore] that keeps the tag in a field, so a test can assert on the
/// exact value that was handed to storage.
class _InMemoryLocaleStore() implements LocaleStore {
  String? value;
  int writeCount = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String languageTag) async {
    writeCount++;
    value = languageTag;
  }

  @override
  Future<void> clear() async => value = null;
}

/// A [LocaleStore] whose reads and writes always fail, to prove a broken store
/// cannot take the app down at boot.
class const _ThrowingLocaleStore() implements LocaleStore {
  @override
  Future<String?> read() async => throw StateError('storage unavailable');

  @override
  Future<void> write(String languageTag) async =>
      throw StateError('storage unavailable');

  @override
  Future<void> clear() async => throw StateError('storage unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppLocaleController.resetStore();
    // slang's GlobalLocaleState is a plain in-process singleton, so putting it
    // back on the base locale is exactly what a fresh process looks like.
    await LocaleSettings.setLocale(PicoLocale.en);
  });

  tearDown(AppLocaleController.resetStore);

  group('AppLocaleController', () {
    test('setLocale applies the locale and writes its language tag', () async {
      final store = _InMemoryLocaleStore();
      AppLocaleController.store = store;

      await AppLocaleController.setLocale(PicoLocale.id);

      expect(LocaleSettings.currentLocale, PicoLocale.id);
      expect(store.value, PicoLocale.id.languageTag);
      expect(store.writeCount, 1);
    });

    test(
      'restore applies the persisted locale after a simulated cold start',
      () async {
        final store = _InMemoryLocaleStore();
        AppLocaleController.store = store;

        // Session 1: the user picks Indonesian.
        await AppLocaleController.setLocale(PicoLocale.id);

        // Cold start: the process dies, so slang's in-memory locale is back at
        // the base locale. Only what reached the store survives.
        await LocaleSettings.setLocale(PicoLocale.en);
        expect(LocaleSettings.currentLocale, PicoLocale.en);

        // Session 2: bootstrap.dart restores before the first frame.
        final restored = await AppLocaleController.restore();

        expect(restored, PicoLocale.id);
        expect(LocaleSettings.currentLocale, PicoLocale.id);
      },
    );

    test(
      'restore applies the default locale when nothing was persisted',
      () async {
        AppLocaleController.store = _InMemoryLocaleStore();

        expect(await AppLocaleController.restore(), isNull);
        expect(LocaleSettings.currentLocale, AppLocaleController.defaultLocale);
      },
    );

    test('restore ignores a tag this build no longer ships', () async {
      AppLocaleController.store = _InMemoryLocaleStore()..value = 'zz';

      expect(await AppLocaleController.restore(), isNull);
      expect(LocaleSettings.currentLocale, AppLocaleController.defaultLocale);
    });

    test('restore never throws when the store fails', () async {
      AppLocaleController.store = const _ThrowingLocaleStore();

      expect(await AppLocaleController.restore(), isNull);
      expect(LocaleSettings.currentLocale, AppLocaleController.defaultLocale);
    });

    test('setLocale surfaces a write failure to the caller', () async {
      AppLocaleController.store = const _ThrowingLocaleStore();

      await expectLater(
        AppLocaleController.setLocale(PicoLocale.id),
        throwsStateError,
      );
      // The in-memory half still applied — the UI is not left lying about the
      // current language just because the write failed.
      expect(LocaleSettings.currentLocale, PicoLocale.id);
    });

    test('clear forgets the persisted choice', () async {
      final store = _InMemoryLocaleStore();
      AppLocaleController.store = store;

      await AppLocaleController.setLocale(PicoLocale.id);
      await AppLocaleController.clear();

      expect(store.value, isNull);
      expect(await AppLocaleController.restore(), isNull);
    });

    test('localeForLanguageTag maps known tags and rejects unknown ones', () {
      expect(AppLocaleController.localeForLanguageTag('id'), PicoLocale.id);
      expect(AppLocaleController.localeForLanguageTag('en'), PicoLocale.en);
      expect(AppLocaleController.localeForLanguageTag('zz'), isNull);
    });
  });

  group('SharedPreferencesLocaleStore', () {
    test('round-trips the language tag through real preferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      AppLocaleController.resetStore();

      await AppLocaleController.setLocale(PicoLocale.id);

      // Prove the value actually landed in preferences under the documented
      // key, not just in some in-process cache.
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(SharedPreferencesLocaleStore.storageKey),
        PicoLocale.id.languageTag,
      );

      // Cold start.
      await LocaleSettings.setLocale(PicoLocale.en);

      expect(await AppLocaleController.restore(), PicoLocale.id);
      expect(LocaleSettings.currentLocale, PicoLocale.id);
    });
  });
}
