import 'dart:async';

import 'package:dependencies/state.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:peta/src/domain/regions.dart';
import 'package:peta/src/presentation/bloc/peta_event.dart';
import 'package:peta/src/presentation/bloc/peta_state.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Loads the outlines.
typedef RegionLoader = Future<List<Region>> Function();

/// The bundled outlines, parsed once in an isolate and kept for the session.
Future<List<Region>> loadBundledRegions() => _cache ??= rootBundle
    .loadString('packages/peta/assets/geojson/sulteng.json')
    .then(parseRegionsInIsolate);
Future<List<Region>>? _cache;

/// The map's data: outlines, the latest value of each kabupaten (a stream that
/// grows as the first load arrives) and, for a chosen day, the 13 series.
class PetaBloc extends Bloc<PetaEvent, PetaState> {
  PetaBloc(this._cases, {RegionLoader? regions})
    : _regions = regions ?? loadBundledRegions,
      super(const PetaState()) {
    on<PetaStarted>(_onStarted);
    on<PetaMetricChanged>((e, emit) => emit(state.copyWith(metric: e.metric)));
    on<PetaDateChosen>(_onDate);
    on<PetaViewChanged>((e, emit) => emit(state.copyWith(list: e.list)));
    on<PetaSelected>(
      (e, emit) => emit(
        e.code == null
            ? state.copyWith(clearSelected: true)
            : state.copyWith(selected: e.code),
      ),
    );
    on<PetaRefreshed>((e, emit) {
      _watch(force: true, done: e.done);
    });
    on<_Arrived>(_onArrived);
    on<_PastLoaded>(
      (e, emit) => emit(
        e.date == state.date
            ? state.copyWith(pastDays: e.days, dateLoading: false)
            : state,
      ),
    );
    on<_RegionsLoaded>((e, emit) => emit(state.copyWith(regions: e.regions)));
  }

  final CaseRepository _cases;
  final RegionLoader _regions;
  StreamSubscription<Object?>? _sub;

  Future<void> _onStarted(PetaStarted e, Emitter<PetaState> emit) async {
    unawaited(_regions().then((r) => add(_RegionsLoaded(r))));
    _watch(force: false);
  }

  void _watch({required bool force, Completer<void>? done}) {
    unawaited(_sub?.cancel());
    _sub = _cases
        .watchRegencySummaries(forceRefresh: force)
        .listen(
          (r) => add(_Arrived(r)),
          onDone: () {
            add(const _Arrived(null));
            if (done != null && !done.isCompleted) done.complete();
          },
        );
  }

  void _onArrived(_Arrived e, Emitter<PetaState> emit) {
    final r = e.result;
    if (r == null) return emit(state.copyWith(done: true));
    r.fold(
      (f) => emit(state.snapshot != null ? state : state.copyWith(failure: f)),
      (s) => emit(state.copyWith(snapshot: s, clearFailure: true)),
    );
  }

  Future<void> _onDate(PetaDateChosen e, Emitter<PetaState> emit) async {
    final date = e.date;
    if (date == null) {
      return emit(
        state.copyWith(clearDate: true, clearPast: true, dateLoading: false),
      );
    }
    emit(state.copyWith(date: date, clearPast: true, dateLoading: true));
    // The date may arrive (from the URL) before the outlines have parsed.
    final rs = state.regions ?? await _regions();
    final codes = [for (final r in rs) r.code];
    final days = <String, CaseDay?>{};
    await Future.wait([
      for (final c in codes)
        _cases
            .watchSeries(AreaRef.regency(c))
            .first
            .then((r) {
              // Keyed by date, never by the API's day index.
              days[c] = r.fold((_) => null, (s) {
                for (final d in s.data.days) {
                  if (d.date == date) return d;
                }
                return null;
              });
            })
            .catchError((Object _) => days[c] = null),
    ]);
    add(_PastLoaded(date, days));
  }

  @override
  Future<void> close() {
    unawaited(_sub?.cancel());
    return super.close();
  }
}

final class _Arrived extends PetaEvent {
  const _Arrived(this.result);

  final Either<PicoFailure, DataSnapshot<List<AreaSummary>>>? result;
}

final class _PastLoaded extends PetaEvent {
  const _PastLoaded(this.date, this.days);

  final DateTime date;
  final Map<String, CaseDay?> days;
}

final class _RegionsLoaded extends PetaEvent {
  const _RegionsLoaded(this.regions);

  final List<Region> regions;
}
