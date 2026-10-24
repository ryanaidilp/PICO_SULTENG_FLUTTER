import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// One data source of the page: nothing yet, data (maybe from the saved
/// copy), or a failure with no copy.
final class HomeSection<T> extends Equatable {
  /// Creates a section.
  const HomeSection({this.snapshot, this.failure, this.loading = true});

  /// Loading, nothing known yet.
  const HomeSection.loading() : this();

  /// The data with its freshness facts.
  final DataSnapshot<T>? snapshot;

  /// Set when the source failed and there is no saved copy.
  final PicoFailure? failure;

  /// True until the first event.
  final bool loading;

  /// The data, or null.
  T? get data => snapshot?.data;

  @override
  List<Object?> get props => [snapshot, failure, loading];
}

/// The latest non-null Rt of the national series and its date.
typedef LatestRt = ({DateTime date, Rt rt});

/// State of Beranda: national latest day, Sulawesi Tengah latest day and the
/// latest national Rt. Each section loads and fails on its own.
final class HomeState extends Equatable {
  /// Creates a state.
  const HomeState({
    this.national = const HomeSection<CaseDay>.loading(),
    this.sulteng = const HomeSection<CaseDay>.loading(),
    this.rt = const HomeSection<LatestRt?>.loading(),
  });

  /// `watchNationalLatest`: the headline. Without it the page is a state view.
  final HomeSection<CaseDay> national;

  /// Province 72 from `watchProvinceSummaries`.
  final HomeSection<CaseDay> sulteng;

  /// Latest non-null national Rt from `watchSeries(national)`.
  final HomeSection<LatestRt?> rt;

  /// Copy with some sections replaced.
  HomeState copyWith({
    HomeSection<CaseDay>? national,
    HomeSection<CaseDay>? sulteng,
    HomeSection<LatestRt?>? rt,
  }) => HomeState(
    national: national ?? this.national,
    sulteng: sulteng ?? this.sulteng,
    rt: rt ?? this.rt,
  );

  @override
  List<Object?> get props => [national, sulteng, rt];
}
