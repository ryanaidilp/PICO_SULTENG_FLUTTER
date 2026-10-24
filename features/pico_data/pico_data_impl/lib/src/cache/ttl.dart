/// The offline-first policy table (C05, ADR-0109). One place for every
/// lifetime: a screen reads the saved copy first, and the network is touched
/// only when the copy is older than the TTL of its resource class (or the user
/// pulls to refresh).
///
/// The data is a static archive: the national, province and kabupaten series
/// end on 2024-01-14, so history is not re-fetched on every open. Settings are
/// never remote and have no entry.
abstract final class PicoTtl {
  /// Full case series (`/national?all=true`, `/provinces/{id}/cases?all=true`,
  /// `/regencies/{code}/cases`) and the kabupaten summaries derived from them.
  /// The archive does not grow: refresh by pull-to-refresh, or after this long.
  static const Duration archiveSeries = Duration(days: 90);

  /// Latest-row resources: `/national/latest`, `/provinces` (latest per
  /// province). Small, so a weekly check is cheap.
  static const Duration latest = Duration(days: 7);

  /// Directories: hospitals, task forces, vaccination sites, regency names.
  static const Duration directory = Duration(days: 7);

  /// Content: banners, infographics, donations, telemedicine, partners.
  static const Duration content = Duration(days: 3);

  /// Archive statistics: test types and totals, gender, vaccination.
  static const Duration stats = Duration(days: 30);
}

/// Switch for conditional requests (`If-None-Match` with the stored `ETag`; a
/// 304 keeps the copy and only moves its checked-at date). The API ships
/// ETags with PR #91, merged but not deployed, so this stays off until the
/// deploy is confirmed (same discipline as `kRegencySummaryEndpoint`).
const bool kConditionalRequests = false;

/// Store key of the small national Rt value Beranda reads (never requested).
const String kLatestRtKey = 'derived:national_latest_rt';

/// Store key of the latest row of each of the 13 kabupaten (seed only, today).
const String kRegencySummariesKey = 'derived:regency_summaries';
