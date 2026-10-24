import 'package:dependencies/state.dart';
import 'package:home/src/presentation/bloc/home_event.dart';
import 'package:home/src/presentation/bloc/home_state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Province id of Sulawesi Tengah (C02).
const String kSultengId = '72';

/// Loads the three sources of Beranda from the case repository. Each source
/// is a stream by the C05 rule: the saved copy first, then the network.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Creates the bloc over the case repository. Without a content repository
  /// there are no banners.
  new(this._cases, [this._content]) : super(const HomeState()) {
    on<HomeStarted>((e, emit) => _load(emit, force: false));
    on<HomeRefreshed>((e, emit) async {
      await _load(emit, force: true);
      if (!(e.done?.isCompleted ?? true)) e.done!.complete();
    });
  }

  final CaseRepository _cases;
  final ContentRepository? _content;

  Future<void> _load(Emitter<HomeState> emit, {required bool force}) =>
      Future.wait([
        _national(emit, force),
        _sulteng(emit, force),
        _rt(emit, force),
        _banners(emit, force),
      ]);

  Future<void> _national(Emitter<HomeState> emit, bool force) => emit.forEach(
    _cases.watchNationalLatest(forceRefresh: force),
    onData: (r) => state.copyWith(national: _section(r, state.national)),
  );

  Future<void> _sulteng(Emitter<HomeState> emit, bool force) => emit.forEach(
    _cases.watchProvinceSummaries(forceRefresh: force),
    onData: (r) => state.copyWith(
      sulteng: _section(
        r.fold(Left.new, (snap) {
          final row = snap.data.where(
            (s) => s.area == const AreaRef.province(kSultengId),
          );
          if (row.isEmpty) {
            return const Left(
              PicoFailure(
                PicoFailureKind.notFound,
                message: 'Province 72 missing',
              ),
            );
          }
          return Right(
            DataSnapshot(
              data: row.first.latest,
              fetchedAt: snap.fetchedAt,
              source: snap.source,
              isStale: snap.isStale,
              refreshFailure: snap.refreshFailure,
            ),
          );
        }),
        state.sulteng,
      ),
    ),
  );

  /// Beranda never loads a full series: the Rt reading is a small local value
  /// (C05 offline-first).
  Future<void> _rt(Emitter<HomeState> emit, bool force) => emit.forEach(
    _cases.watchNationalLatestRt(forceRefresh: force),
    onData: (r) => state.copyWith(rt: _section<LatestRt?>(r, state.rt)),
  );

  Future<void> _banners(Emitter<HomeState> emit, bool force) {
    final content = _content;
    if (content == null) {
      emit(state.copyWith(banners: const HomeSection(loading: false)));
      return Future.value();
    }
    return emit.forEach(
      content.watchBanners(forceRefresh: force),
      onData: (r) => state.copyWith(banners: _section(r, state.banners)),
    );
  }

  /// A failure keeps the previous data if there is any (it cannot happen by
  /// the stream rule, but a refresh error must not blank a shown page).
  HomeSection<T> _section<T>(
    Either<PicoFailure, DataSnapshot<T>> r,
    HomeSection<T> previous,
  ) => r.fold(
    (f) => previous.snapshot != null
        ? previous
        : HomeSection<T>(failure: f, loading: false),
    (s) => HomeSection<T>(snapshot: s, loading: false),
  );
}
