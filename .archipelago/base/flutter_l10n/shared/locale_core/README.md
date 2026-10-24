# locale_core

Internationalization (i18n) and localization (l10n) package for Pico using [slang](https://pub.dev/packages/slang).

Provides type-safe translations, pluralization rules, and localization utilities
to support multiple languages in the application.

## Directory Structure

Translations are organized in the `json` directory, using namespaces to separate
translations by context or feature. Each namespace corresponds to a folder
containing locale-specific files.

```plaintext
json/
├── general/
│   ├── general.i18n.json       # Base English
│   └── general_id.i18n.json    # Indonesian
└── feedback/
    ├── dialog.i18n.json
    ├── dialog_id.i18n.json
    ├── error.i18n.json
    ├── error_id.i18n.json
    ├── success.i18n.json
    └── success_id.i18n.json
```

## Adding a New Locale

Create a new `.i18n.json` file in the appropriate namespace directory using the
naming convention `<namespace>_<locale>.i18n.json`.

## Generating Translations

After adding or updating translation files, generate the Dart code:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Usage

Access translations in a type-safe manner:

```dart
// In a widget
context.l10n.feedback.error.generic
context.l10n.feedback.dialog.confirm
context.l10n.general.appName

// Change locale — ALWAYS go through AppLocaleController, never
// LocaleSettings.setLocale directly (see "Locale persistence contract").
await AppLocaleController.setLocale(PicoLocale.id);

// Use device locale
LocaleSettings.useDeviceLocale();
```

## Locale persistence contract

slang's `LocaleSettings` is **in-memory only** — it mutates a plain in-process
singleton with no disk-backed storage, so a locale set through it is gone the
moment the process dies. `locale_core` owns both halves of making that choice
durable, and no other package should re-implement either half.

| Concern | Owner | Entry point |
| --- | --- | --- |
| Writing the choice to disk | `locale_core` | `AppLocaleController.setLocale(PicoLocale)` |
| Restoring it before the first frame | `locale_core` | `AppLocaleController.restore()` |
| Where the value is stored | `locale_core` | `LocaleStore` (default: `SharedPreferencesLocaleStore`) |
| Applying it to a *feature-scoped* slang instance | that feature | the feature's shell page `_syncLocale()` |

### Rules for feature packages with their own language control

Any feature that lets the user change the language (Home's Settings toggle, a
switcher on an auth screen, a debug menu) must:

1. Call its **own** `LocaleSettings.setLocale(<Feature>Locale.x)` so its own
   `TranslationProvider` subtree rebuilds immediately, and
2. Route the app-wide change through
   `app_l10n.AppLocaleController.setLocale(...)` — **not**
   `app_l10n.LocaleSettings.setLocale(...)`.

Calling `app_l10n.LocaleSettings.setLocale` directly still works in the running
process, which is exactly why the omission is easy to miss: the UI updates, but
nothing is written, and the next cold start silently reverts to the base locale.

`features/home/home_impl/lib/src/presentation/settings/settings_page.dart` is
the reference implementation.

### Cold start

`apps/pico/lib/bootstrap.dart` awaits
`AppLocaleController.restore()` **before `runApp()`**, so the app-wide locale is
already correct when the first widget builds. Every feature shell seeds its own
scoped slang instance from `app_l10n.LocaleSettings.currentLocale` in
`initState` and gates its content on that sync completing, so features render
the restored locale from their first frame — there is no flash of the base
locale.

`restore()` never throws: a storage failure degrades to "no saved preference"
(loud in debug, silent in release) rather than blocking app launch. When nothing
has ever been persisted it returns `null` and leaves the base locale in place;
an app that would rather follow the device language in that case can call
`LocaleSettings.useDeviceLocale()` when `restore()` returns `null`.

### Choosing a different backing store

`SharedPreferencesLocaleStore` is the default because `locale_core` is generated
for every project while `storage_sdk` is optional and is resolved through
`GetIt` — which is not yet wired when the locale must be restored. To store the
preference somewhere else, assign a `LocaleStore` before `restore()` runs:

```dart
AppLocaleController.store = MyEncryptedLocaleStore();
await AppLocaleController.restore();
```

## Setup

Wrap your `MaterialApp` with `TranslationProvider`:

```dart
TranslationProvider(
  child: MaterialApp(
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    // ...
  ),
)
```

For more details, see the [slang documentation](https://pub.dev/packages/slang).
