import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/usecases/get_all_statistic.dart';
import 'package:statistic/statistic.dart';

part 'all_statistics_event.dart';
part 'all_statistics_state.dart';
part 'all_statistics_bloc.freezed.dart';

class AllStatisticsBloc
    extends HydratedBloc<AllStatisticsEvent, AllStatisticsState> {
  AllStatisticsBloc() : super(AllStatisticsState.initial()) {
    on<AllStatisticsEvent>(
      (event, emit) async {
        if (event is _AllStatisticsFetched) {
          emit(AllStatisticsState.loading());
          final result = await _usecase.call(NoParams());
          result.fold(
            (l) => emit(AllStatisticsState.failed(failure: l)),
            (r) => emit(AllStatisticsState.loaded(data: r)),
          );
        }
      },
    );
  }

  final _usecase = getIt<GetAllStatistic>();

  static const String _storageKey = 'history';

  @override
  AllStatisticsState? fromJson(Map<String, dynamic> json) {
    if (json.containsKey(_storageKey)) {
      final jsonData = json[_storageKey] as List;
      final data =
          jsonData.map((e) => StatisticModel.fromJson(e as JSON)).toList();
      return AllStatisticsState.loaded(
        data: data.map((e) => e.toEntity()).toList(),
      );
    }

    return null;
  }

  @override
  Map<String, dynamic>? toJson(AllStatisticsState state) {
    if (state is AllStatisticsLoaded) {
      return {
        _storageKey: state.data
            .map(
              (e) => StatisticModel.fromEntity(e).toJson(),
            )
            .toList(),
      };
    }

    return null;
  }
}
