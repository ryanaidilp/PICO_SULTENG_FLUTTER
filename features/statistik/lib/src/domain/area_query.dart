import 'package:dependencies/equality.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Which kind of area a query reads.
enum AreaLevel {
  /// Indonesia.
  national,

  /// One province.
  province,

  /// One kabupaten or kota.
  regency,
}

/// Province id of Sulawesi Tengah.
const String kSultengProvinceId = '72';

/// What the area page shows: the area, the case type, daily or cumulative and
/// the date range. It maps 1:1 to the query string of `/statistik` (C07).
///
/// [from] and [to] are null while the range is open: it then follows the data
/// (first to last day). Defaults are national, positive, daily, all dates, and
/// a default is never printed, so every query has one canonical URL.
final class AreaQuery extends Equatable {
  /// Creates a query.
  const AreaQuery({
    this.area = const AreaRef.national(),
    this.metric = CaseMetric.positive,
    this.daily = true,
    this.from,
    this.to,
  });

  /// Reads a query string map. Invalid or missing values fall back to the
  /// defaults and never throw (C07).
  factory AreaQuery.fromParams(Map<String, String?> q, {AreaRef? area}) {
    AreaRef parseArea() {
      final id = q['id'];
      return switch (q['level']) {
        'province' when id != null && RegExp(r'^\d{2}$').hasMatch(id) =>
          AreaRef.province(id),
        'regency' when id != null && RegExp(r'^\d{4}$').hasMatch(id) =>
          AreaRef.regency(id),
        _ => const AreaRef.national(),
      };
    }

    DateTime? date(String? s) {
      if (s == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return null;
      final p = s.split('-').map(int.parse).toList();
      final d = DateTime(p[0], p[1], p[2]);
      // Reject 2021-02-31 style dates that DateTime would roll over.
      return d.month == p[1] && d.day == p[2] ? d : null;
    }

    return AreaQuery(
      area: area ?? parseArea(),
      metric: CaseMetric.values.firstWhere(
        (m) => m.name == q['metric'],
        orElse: () => CaseMetric.positive,
      ),
      daily: q['daily'] != 'false',
      from: date(q['from']),
      to: date(q['to']),
    );
  }

  /// The area.
  final AreaRef area;

  /// The chosen case type.
  final CaseMetric metric;

  /// Daily values (true) or cumulative (false).
  final bool daily;

  /// First day, or null for the first day of the data.
  final DateTime? from;

  /// Last day, or null for the last day of the data.
  final DateTime? to;

  /// The level of [area].
  AreaLevel get level => switch (area) {
    NationalArea() => AreaLevel.national,
    ProvinceArea() => AreaLevel.province,
    RegencyArea() => AreaLevel.regency,
  };

  /// The area id (province id or regency code), null for national.
  String? get areaId => switch (area) {
    NationalArea() => null,
    ProvinceArea(:final id) => id,
    RegencyArea(:final code) => code,
  };

  /// The canonical path: `/statistik` plus the non-default parameters.
  String get path => PicoRoutes.statistik(
    level: level == AreaLevel.national ? null : level.name,
    id: areaId,
    metric: metric == CaseMetric.positive ? null : metric.name,
    from: from,
    to: to,
    daily: daily ? null : false,
  );

  /// A copy with some fields replaced. Pass `clearRange: true` to reopen it.
  AreaQuery copyWith({
    AreaRef? area,
    CaseMetric? metric,
    bool? daily,
    DateTime? from,
    DateTime? to,
    bool clearRange = false,
  }) => AreaQuery(
    area: area ?? this.area,
    metric: metric ?? this.metric,
    daily: daily ?? this.daily,
    from: clearRange ? null : from ?? this.from,
    to: clearRange ? null : to ?? this.to,
  );

  @override
  List<Object?> get props => [area, metric, daily, from, to];
}
