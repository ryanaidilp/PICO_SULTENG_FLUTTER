import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/statistic_model.dart';
import 'package:statistic/src/domain/entities/entities.dart';
import 'package:statistic/statistic.dart';

part 'all_statistic_filter_state.dart';

class AllStatisticFilterCubit extends HydratedCubit<AllStatisticFilterState> {
  AllStatisticFilterCubit() : super(AllStatisticFilterInitial());

  final String _storageKey = 'all_statistic_filter';

  void updateYear(int? year) => emit(
        AllStatisticFilterUpdated(
          year: year,
          lastItem: state.lastItem,
          hoveredItem: state.hoveredItem,
        ),
      );

  void updateLastItem(Statistic item) => emit(
        AllStatisticFilterUpdated(
          year: state.year,
          lastItem: item,
          hoveredItem: state.hoveredItem,
        ),
      );

  void updateHoveredItem(Statistic? item) => emit(
        AllStatisticFilterUpdated(
          year: state.year,
          lastItem: state.lastItem,
          hoveredItem: item,
        ),
      );

  @override
  AllStatisticFilterState? fromJson(Map<String, dynamic> json) {
    if (json.containsKey(_storageKey)) {
      final state = AllStatisticFilterState.fromJson(json[_storageKey] as JSON);

      return AllStatisticFilterUpdated(
        lastItem: state.lastItem,
        hoveredItem: state.hoveredItem,
      );
    }

    return null;
  }

  @override
  Map<String, dynamic>? toJson(AllStatisticFilterState state) {
    if (state is AllStatisticFilterUpdated) {
      return {_storageKey: state.toJson()};
    }

    return null;
  }
}
