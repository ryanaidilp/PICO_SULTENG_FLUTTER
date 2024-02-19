// ignore_for_file: avoid_positional_boolean_parameters

import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/enums/enums.dart';

part 'line_chart_filter_state.dart';

class LineChartFilterCubit extends Cubit<LineChartFilterState> {
  LineChartFilterCubit() : super(LineChartFilterState());

  void updateStatus({required bool status}) => emit(
        state.copyWith(
          isUpdating: status,
          selectedYear: state.selectedYear,
        ),
      );

  Future<void> updateType(CaseType type) async {
    if (state.type == type) return;
    emit(
      state.copyWith(
        isUpdating: true,
        type: type,
        selectedYear: state.selectedYear,
      ),
    );
    await Future.delayed(
      1.seconds,
      () => emit(
        state.copyWith(
          isUpdating: false,
          selectedYear: state.selectedYear,
        ),
      ),
    );
  }

  Future<void> updateTimeFrame(DataTimeFrame timeFrame) async {
    if (state.timeFrame == timeFrame) return;
    emit(
      state.copyWith(
        isUpdating: true,
        timeFrame: timeFrame,
        selectedYear: state.selectedYear,
      ),
    );
    await Future.delayed(
      1.seconds,
      () {
        emit(
          state.copyWith(
            isUpdating: false,
            timeFrame: timeFrame,
            selectedYear: state.selectedYear,
          ),
        );
      },
    );
  }

  Future<void> toggleShowCumulative(bool value) async {
    if (state.showCumulative == value) return;
    emit(
      state.copyWith(
        isUpdating: true,
        showCumulative: value,
        selectedYear: state.selectedYear,
      ),
    );
    await Future.delayed(
      1.seconds,
      () {
        emit(
          state.copyWith(
            isUpdating: false,
            selectedYear: state.selectedYear,
          ),
        );
      },
    );
  }

  Future<void> updateSelectedYear(int? year) async {
    if (state.selectedYear == year) return;
    emit(
      state.copyWith(
        isUpdating: true,
        selectedYear: year,
      ),
    );
    await Future.delayed(
      1.seconds,
      () {
        emit(
          state.copyWith(
            isUpdating: false,
            selectedYear: year,
          ),
        );
      },
    );
  }

  Future<void> updateAvailableYear(Set<int> years) async {
    if (state.availableYear == years) return;
    emit(
      state.copyWith(
        isUpdating: true,
      ),
    );
    await Future.delayed(
      1.seconds,
      () {
        emit(
          state.copyWith(
            isUpdating: false,
            availableYear: years,
          ),
        );
      },
    );
  }
}
