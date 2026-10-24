import 'package:dependencies/equality.dart';
import 'package:informasi/src/domain/tip.dart';

/// The bundled articles by locale then slug; null until loaded.
final class InformasiState extends Equatable {
  const new({this.tips});

  final Map<String, Map<String, Tip>>? tips;

  /// Articles of [locale] in list order, falling back to Indonesian.
  List<Tip> list(String locale) {
    final byLocale = tips?[locale] ?? tips?['id'] ?? const {};
    return [for (final s in kTipSlugs) ?byLocale[s] ?? tips?['id']?[s]];
  }

  /// One article, or null.
  Tip? tip(String locale, String slug) =>
      tips?[locale]?[slug] ?? tips?['id']?[slug];

  @override
  List<Object?> get props => [tips];
}
