import 'package:flutter/services.dart';
import 'package:informasi/src/domain/tip.dart';

/// Where the articles come from.
abstract interface class TipSource {
  Future<String> read(String slug, String locale);
}

/// The bundled assets: `assets/tips/<slug>.<locale>.md`.
class const AssetTipSource() implements TipSource {
  @override
  Future<String> read(String slug, String locale) =>
      rootBundle.loadString('packages/informasi/assets/tips/$slug.$locale.md');
}

/// Loads every article in every locale. A file that fails to load or parse is
/// skipped, so one bad article never hides the others.
Future<Map<String, Map<String, Tip>>> loadTips(TipSource source) async {
  final out = <String, Map<String, Tip>>{for (final l in kTipLocales) l: {}};
  for (final l in kTipLocales) {
    for (final slug in kTipSlugs) {
      try {
        out[l]![slug] = parseTip(slug, await source.read(slug, l));
      } on Object {
        // Skipped on purpose; the asset completeness test catches it in CI.
      }
    }
  }
  return out;
}
