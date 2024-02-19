part of 'line_chart_filter_cubit.dart';

@immutable
class LineChartFilterState extends Equatable {
  LineChartFilterState({
    Set<int>? availableYear,
    this.type = CaseType.underTreatment,
    this.timeFrame = DataTimeFrame.all,
    this.isUpdating = true,
    this.selectedYear,
    this.showCumulative = false,
  }) : availableYear = availableYear ?? <int>{};

  final int? selectedYear;
  final Set<int> availableYear;
  final CaseType type;
  final DataTimeFrame timeFrame;
  final bool isUpdating;
  final bool showCumulative;

  @override
  List<Object?> get props => [
        selectedYear,
        type,
        timeFrame,
        availableYear,
        isUpdating,
        showCumulative,
      ];

  LineChartFilterState copyWith({
    int? selectedYear,
    Set<int>? availableYear,
    CaseType? type,
    DataTimeFrame? timeFrame,
    bool? isUpdating,
    bool? showCumulative,
  }) =>
      LineChartFilterState(
        availableYear: availableYear ?? this.availableYear,
        isUpdating: isUpdating ?? this.isUpdating,
        type: type ?? this.type,
        selectedYear: selectedYear,
        timeFrame: timeFrame ?? this.timeFrame,
        showCumulative: showCumulative ?? this.showCumulative,
      );
}
