import 'package:dependencies/equality.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// One data source of the page: nothing yet, data (maybe from the saved
/// copy), or a failure with no copy.
final class HomeSection<T> extends Equatable {
  /// Creates a section.
  const new({this.snapshot, this.failure, this.loading = true});

  /// Loading, nothing known yet.
  const new loading() : this();

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

/// State of Beranda: Sulawesi Tengah latest day first, its kabupaten, then the
/// national latest day and Rt. Each section loads and fails on its own.
final class HomeState extends Equatable {
  /// Creates a state.
  const new({
    this.national = const HomeSection<CaseDay>.loading(),
    this.sulteng = const HomeSection<CaseDay>.loading(),
    this.rt = const HomeSection<LatestRt?>.loading(),
    this.regencies = const HomeSection<List<AreaSummary>>.loading(),
    this.banners = const HomeSection<List<Banner>>.loading(),
  });

  /// `watchNationalLatest`: the smaller national section. It never blocks.
  final HomeSection<CaseDay> national;

  /// Province 72 from `watchProvinceSummaries`: the headline. Without it the
  /// page is a state view.
  final HomeSection<CaseDay> sulteng;

  /// Latest non-null national Rt from `watchSeries(national)`.
  final HomeSection<LatestRt?> rt;

  /// The 13 kabupaten and kota of Sulawesi Tengah from
  /// `watchRegencySummaries`. It never blocks the page: no data, no list.
  final HomeSection<List<AreaSummary>> regencies;

  /// Active banners. Never blocks the page: no data means no section.
  final HomeSection<List<Banner>> banners;

  /// Copy with some sections replaced.
  HomeState copyWith({
    HomeSection<CaseDay>? national,
    HomeSection<CaseDay>? sulteng,
    HomeSection<LatestRt?>? rt,
    HomeSection<List<AreaSummary>>? regencies,
    HomeSection<List<Banner>>? banners,
  }) => HomeState(
    national: national ?? this.national,
    sulteng: sulteng ?? this.sulteng,
    rt: rt ?? this.rt,
    regencies: regencies ?? this.regencies,
    banners: banners ?? this.banners,
  );

  @override
  List<Object?> get props => [national, sulteng, rt, regencies, banners];
}
