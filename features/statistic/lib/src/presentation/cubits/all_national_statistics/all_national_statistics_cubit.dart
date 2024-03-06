import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/usecases/get_all_national_statistic.dart';
import 'package:statistic/statistic.dart';

part 'all_national_statistics_state.dart';
part 'all_national_statistics_cubit.freezed.dart';

class AllNationalStatisticsCubit
    extends HydratedCubit<AllNationalStatisticsState> {
  AllNationalStatisticsCubit() : super(AllNationalStatisticsInitial());

  Future<void> fetch() async {
    emit(AllNationalStatisticsLoading());
    final result = await _usecase.call(NoParams());
    result.fold(
      (l) => emit(AllNationalStatisticsFailed(failure: l)),
      (r) {
        if (r.isEmpty) {
          emit(AllNationalStatisticsEmpty());
        } else {
          emit(AllNationalStatisticsLoaded(data: r));
        }
      },
    );
  }

  final _usecase = getIt<GetAllNationalStatistic>();

  static const String _storageKey = 'national_history';

  @override
  AllNationalStatisticsState? fromJson(Map<String, dynamic> json) {
    if (json.containsKey(_storageKey)) {
      final jsonData = json[_storageKey] as List;
      final data =
          jsonData.map((e) => StatisticModel.fromJson(e as JSON)).toList();
      return AllNationalStatisticsState.loaded(
        data: data.map((e) => e.toEntity()).toList(),
      );
    }

    return null;
  }

  @override
  Map<String, dynamic>? toJson(AllNationalStatisticsState state) {
    if (state is AllNationalStatisticsLoaded) {
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
