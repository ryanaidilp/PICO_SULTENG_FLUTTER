import 'package:i10n/i10n.dart';

/// Set pluralization for [AppLocale.id].
void setPluralizationResolverForID() {
  // add this before you call the pluralization strings. Otherwise an exception will be thrown.
// you don't need to specify both
  LocaleSettings.setPluralResolver(
    locale: AppLocale.id,
    cardinalResolver: (n, {zero, one, two, few, many, other}) {
      if (n == 0) return zero ?? other!;
      if (n == 1) return one ?? other!;
      return other!;
    },
    ordinalResolver: (n, {zero, one, two, few, many, other}) {
      if (n % 10 == 1 && n % 100 != 11) return one ?? other!;
      if (n % 10 == 2 && n % 100 != 12) return two ?? other!;
      if (n % 10 == 3 && n % 100 != 13) return few ?? other!;
      return other!;
    },
    language: AppLocale.id.languageCode,
  );
}
