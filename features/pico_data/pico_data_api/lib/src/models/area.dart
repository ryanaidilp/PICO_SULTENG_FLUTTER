import 'package:dependencies_core/equality.dart';

/// Which area a case series belongs to. Province ids are strings (`"72"`),
/// regency codes are the API's numeric codes kept as strings (`"7271"`).
sealed class AreaRef extends Equatable {
  const new();

  /// The whole of Indonesia.
  const factory national() = NationalArea;

  /// A province by id.
  const factory province(String id) = ProvinceArea;

  /// A kabupaten or kota by code.
  const factory regency(String code) = RegencyArea;
}

/// National area.
final class NationalArea extends AreaRef {
  /// Creates the national area.
  const new();

  @override
  List<Object?> get props => const [];
}

/// A province.
final class ProvinceArea extends AreaRef {
  /// Creates a province area.
  const new(this.id);

  /// Province id, for example `"72"`.
  final String id;

  @override
  List<Object?> get props => [id];
}

/// A kabupaten or kota.
final class RegencyArea extends AreaRef {
  /// Creates a regency area.
  const new(this.code);

  /// Regency code, for example `"7271"`.
  final String code;

  @override
  List<Object?> get props => [code];
}

/// First and last date of the archive (C05). The end moves with the latest row.
final DateTime kDataStart = DateTime(2020, 3, 2);

/// Last date of the archive at the time of writing.
final DateTime kDataEnd = DateTime(2024, 1, 14);

/// Drops the time part: a local calendar date at 00:00 (C01).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Inclusive range of calendar dates.
final class DateRange extends Equatable {
  /// Creates a range. Both ends are reduced to calendar dates.
  new(DateTime start, DateTime end)
    : start = dateOnly(start),
      end = dateOnly(end);

  /// The whole archive.
  factory archive() => DateRange(kDataStart, kDataEnd);

  /// First day, inclusive.
  final DateTime start;

  /// Last day, inclusive.
  final DateTime end;

  /// Whether [d] falls inside the range, by calendar date.
  bool contains(DateTime d) {
    final day = dateOnly(d);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  List<Object?> get props => [start, end];
}
