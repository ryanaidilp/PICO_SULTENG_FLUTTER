import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/statistic.dart';

part 'all_national_statistic_filter_state.dart';

class AllNationalStatisticFilterCubit
    extends HydratedCubit<AllNationalStatisticFilterState> {
  AllNationalStatisticFilterCubit()
      : super(AllNationalStatisticFilterInitial());

  final String _storageKey = 'all_statistic_filter';

  void updateYear(int? year) => emit(
        AllNationalStatisticFilterUpdated(
          year: year,
          lastItem: state.lastItem,
          hoveredItem: state.hoveredItem,
        ),
      );

  void updateLastItem(Statistic item) => emit(
        AllNationalStatisticFilterUpdated(
          year: state.year,
          lastItem: item,
          hoveredItem: state.hoveredItem,
        ),
      );

  void updateHoveredItem(Statistic? item) => emit(
        AllNationalStatisticFilterUpdated(
          year: state.year,
          lastItem: state.lastItem,
          hoveredItem: item,
        ),
      );

  @override
  AllNationalStatisticFilterState? fromJson(Map<String, dynamic> json) {
    if (json.containsKey(_storageKey)) {
      final state =
          AllNationalStatisticFilterState.fromJson(json[_storageKey] as JSON);

      return AllNationalStatisticFilterUpdated(
        lastItem: state.lastItem,
        hoveredItem: state.hoveredItem,
      );
    }

    return null;
  }

  @override
  Map<String, dynamic>? toJson(AllNationalStatisticFilterState state) {
    if (state is AllNationalStatisticFilterUpdated) {
      return {_storageKey: state.toJson()};
    }

    return null;
  }
}
