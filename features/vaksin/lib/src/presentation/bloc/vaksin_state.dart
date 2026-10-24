import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';

/// One data source: nothing yet, data with freshness facts, or a failure.
final class VaksinSection<T> extends Equatable {
  /// Creates a section.
  const new({this.snapshot, this.failure, this.loading = true});

  /// Not loaded yet.
  const new loading() : this();

  /// The data.
  final DataSnapshot<T>? snapshot;

  /// Failure with no saved copy.
  final PicoFailure? failure;

  /// True until the first event.
  final bool loading;

  /// The data, or null.
  T? get data => snapshot?.data;

  @override
  List<Object?> get props => [snapshot, failure, loading];
}

/// Vaccination locations with the regency names they are grouped by.
typedef LocationsData = ({
  List<VaccineLocation> locations,
  List<Regency> regencies,
});

/// State of the Vaksin page.
final class VaksinState extends Equatable {
  /// Creates a state.
  const new({
    this.scope = VaccinationScope.sulteng,
    this.segment = VaksinSegment.coverage,
    this.series = const VaksinSection<VaccinationSeries>.loading(),
    this.locations = const VaksinSection<LocationsData>.loading(),
  });

  /// Coverage scope.
  final VaccinationScope scope;

  /// Open segment.
  final VaksinSegment segment;

  /// Coverage series of [scope].
  final VaksinSection<VaccinationSeries> series;

  /// Locations and regency names.
  final VaksinSection<LocationsData> locations;

  /// Copy with replaced fields.
  VaksinState copyWith({
    VaccinationScope? scope,
    VaksinSegment? segment,
    VaksinSection<VaccinationSeries>? series,
    VaksinSection<LocationsData>? locations,
  }) => VaksinState(
    scope: scope ?? this.scope,
    segment: segment ?? this.segment,
    series: series ?? this.series,
    locations: locations ?? this.locations,
  );

  @override
  List<Object?> get props => [scope, segment, series, locations];
}
