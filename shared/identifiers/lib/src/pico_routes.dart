/// The single list of PICO route paths (contract C07).
///
/// Features register their own pages, and link to other features only through
/// these paths and builders. Push payloads (`data.route`) and deep links use
/// the same paths. Paths are lowercase Indonesian slugs and stable once
/// released: renaming one keeps a redirect for a major version.
abstract final class PicoRoutes {
  // Tabs.
  /// Beranda, tab 1.
  static const String beranda = '/beranda';

  /// Statistik, tab 2.
  static const String statistikRoot = '/statistik';

  /// Layanan hub, tab 3.
  static const String layanan = '/layanan';

  /// Info hub, tab 4.
  static const String info = '/info';

  // Statistik.
  /// Province detail path pattern.
  static const String provinsiPattern = '/statistik/provinsi/:id';

  /// Kabupaten summary list.
  static const String kabupatenList = '/statistik/kabupaten';

  /// Kabupaten detail path pattern.
  static const String kabupatenDetailPattern = '/statistik/kabupaten/:code';

  /// Rt explainer and chart.
  static const String rtRoot = '/statistik/rt';

  /// Tes.
  static const String tes = '/statistik/tes';

  /// Peta.
  static const String petaRoot = '/peta';

  // Layanan.
  /// Vaksin.
  static const String vaksin = '/layanan/vaksin';

  /// Hospital list.
  static const String rumahSakit = '/layanan/rumah-sakit';

  /// Hospital detail path pattern.
  static const String rumahSakitDetailPattern = '/layanan/rumah-sakit/:code';

  /// Task forces.
  static const String satgas = '/layanan/satgas';

  /// Donasi and Telemedicine.
  static const String isoman = '/layanan/isoman';

  // Info.
  /// Infographic gallery.
  static const String infografis = '/info/infografis';

  /// Infographic detail path pattern.
  static const String infografisDetailPattern = '/info/infografis/:id';

  /// Health tip path pattern.
  static const String tipsPattern = '/info/tips/:slug';

  /// About and Metodologi.
  static const String tentang = '/info/tentang';

  // Other.
  /// Settings.
  static const String pengaturan = '/pengaturan';

  /// Generated push settings page (after T27).
  static const String notificationSettings = '/notification-settings';

  /// `YYYY-MM-DD`, the only date format in a path.
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _withQuery(String path, Map<String, String?> query) {
    final q = <String>[
      for (final e in query.entries)
        if (e.value != null && e.value!.isNotEmpty)
          '${e.key}=${Uri.encodeQueryComponent(e.value!).replaceAll('%3A', ':')}',
    ];
    return q.isEmpty ? path : '$path?${q.join('&')}';
  }

  /// `/statistik` with optional `level` (`national|province|regency`), `id`,
  /// `metric` (`positive|recovered|deceased|active`), `from`, `to` and `daily`.
  static String statistik({
    String? level,
    String? id,
    String? metric,
    DateTime? from,
    DateTime? to,
    bool? daily,
  }) => _withQuery(statistikRoot, {
    'level': level,
    'id': id,
    'metric': metric,
    'from': from == null ? null : formatDate(from),
    'to': to == null ? null : formatDate(to),
    'daily': daily?.toString(),
  });

  /// `/statistik/provinsi/{id}`.
  static String provinsi(String id) => '/statistik/provinsi/$id';

  /// `/statistik/kabupaten/{code}`.
  static String kabupatenDetail(Object code) => '/statistik/kabupaten/$code';

  /// `/statistik/rt?area=national|province:72|regency:7271`.
  static String rt({String? area}) => _withQuery(rtRoot, {'area': area});

  /// `/peta?metric=&date=`.
  static String peta({String? metric, DateTime? date}) => _withQuery(petaRoot, {
    'metric': metric,
    'date': date == null ? null : formatDate(date),
  });

  /// `/layanan/rumah-sakit/{code}`.
  static String rumahSakitDetail(String code) => '/layanan/rumah-sakit/$code';

  /// `/info/infografis/{id}?page=`.
  static String infografisDetail(Object id, {int? page}) =>
      _withQuery('/info/infografis/$id', {'page': page?.toString()});

  /// `/info/tips/{slug}`.
  static String tips(String slug) => '/info/tips/$slug';

  /// Every route pattern of C07, as auto_route paths. A test resolves each
  /// against the built router.
  static const List<String> patterns = [
    beranda,
    statistikRoot,
    provinsiPattern,
    kabupatenList,
    kabupatenDetailPattern,
    rtRoot,
    tes,
    petaRoot,
    layanan,
    vaksin,
    rumahSakit,
    rumahSakitDetailPattern,
    satgas,
    isoman,
    info,
    infografis,
    infografisDetailPattern,
    tipsPattern,
    tentang,
    pengaturan,
    notificationSettings,
  ];
}
