import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Hospitals with the regency names they are grouped by.
typedef HospitalsData = ({List<Hospital> hospitals, List<Regency> regencies});

/// State of the hospitals pages: nothing yet, data with freshness facts, or a
/// failure with no saved copy.
final class HospitalsState extends Equatable {
  /// Creates a state.
  const new({this.snapshot, this.failure, this.loading = true});

  /// The data.
  final DataSnapshot<HospitalsData>? snapshot;

  /// Failure with no saved copy.
  final PicoFailure? failure;

  /// True until the first event.
  final bool loading;

  /// The data, or null.
  HospitalsData? get data => snapshot?.data;

  @override
  List<Object?> get props => [snapshot, failure, loading];
}
