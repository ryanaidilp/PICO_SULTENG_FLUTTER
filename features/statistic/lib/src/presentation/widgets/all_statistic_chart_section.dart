import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/domain/enums/enums.dart';
import 'package:statistic/src/presentation/widgets/line_chart_case.dart';
import 'package:statistic/statistic.dart';

class AllStatisticChartSection extends StatefulWidget {
  const AllStatisticChartSection({super.key});

  @override
  State<AllStatisticChartSection> createState() =>
      _AllStatisticChartSectionState();
}

class _AllStatisticChartSectionState extends State<AllStatisticChartSection> {
  late final PCLineChartController _chartController;
  bool _isInitialLoading = true;
  late final ValueNotifier<List<DateTime>> _labelsNotifier;

  @override
  void initState() {
    super.initState();
    _chartController = PCLineChartController();
    _labelsNotifier = ValueNotifier([]);
  }

  @override
  void dispose() {
    _chartController.dispose();
    _labelsNotifier.dispose();
    super.dispose();
  }

  List<Statistic> _getFilteredData(List<Statistic> data) {
    final filterState = context.read<LineChartLocalStatisticFilter>().state;
    var filteredData = <Statistic>[];

    if (filterState.selectedYear != null) {
      filteredData = data
          .where(
            (element) =>
                filterState.selectedYear == element.updatedAt.toLocal().year,
          )
          .toList()
        ..sort(
          (a, b) => a.day.compareTo(b.day),
        );
    } else {
      filteredData = data;
    }

    final offset = filteredData.length - filterState.timeFrame.offset;

    return switch (filterState.timeFrame) {
      DataTimeFrame.all => filteredData,
      _ => offset.isNegative
          ? filteredData
          : filteredData.sublist(
              offset,
            ),
    };
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<LineChartLocalStatisticFilter,
              LineChartLocalStatisticState>(
            listener: (context, state) {
              final dataState = context.read<AllStatisticsCubit>().state;

              if (state.isUpdating) {
                _chartController.updateState(PCChartState.loading);
              }

              if (!_isInitialLoading &&
                  !state.isUpdating &&
                  dataState is AllStatisticsLoaded) {
                final filteredData = _getFilteredData(dataState.data);
                _labelsNotifier.value =
                    filteredData.map((e) => e.updatedAt).toList();

                context
                    .read<AllStatisticFilterCubit>()
                    .updateLastItem(filteredData.last);

                _chartController
                  ..changeData(
                    state.type.filterData(
                      filteredData,
                      showCumulative: state.showCumulative,
                    ),
                  )
                  ..updateState(PCChartState.success);
              }
            },
          ),
          BlocListener<AllStatisticsCubit, AllStatisticsState>(
            listener: (context, state) async {
              if (state is AllStatisticsLoaded) {
                if (_isInitialLoading) {
                  context.read<LineChartLocalStatisticFilter>().updateStatus(
                        status: false,
                      );
                  await context
                      .read<LineChartLocalStatisticFilter>()
                      .updateAvailableYear(
                        state.data.map((e) => e.updatedAt.year).toSet(),
                      );
                }
                _isInitialLoading = false;
              }
            },
            child: Container(),
          ),
        ],
        child: ValueListenableBuilder(
          valueListenable: _labelsNotifier,
          builder: (_, labels, __) {
            final dataState = context.watch<AllStatisticsCubit>().state;
            final allStatisticFilterState =
                context.watch<AllStatisticFilterCubit>().state;
            final filterState =
                context.watch<LineChartLocalStatisticFilter>().state;

            var data = <Statistic>[];
            if (_isInitialLoading && dataState is AllStatisticsLoading) {
              _chartController.updateState(PCChartState.loading);
            } else if (dataState is AllStatisticsLoaded) {
              data = _getFilteredData(dataState.data);
              context.read<AllStatisticFilterCubit>().updateLastItem(data.last);
              _labelsNotifier.value = data.map((e) => e.updatedAt).toList();
            } else if (dataState is AllStatisticsFailed) {
              _chartController.updateState(PCChartState.failed);
            }

            return LineChartCase(
              isInitialLoading: _isInitialLoading,
              chartController: _chartController,
              selectedYear: filterState.selectedYear,
              caseLabel: filterState.type.label(context),
              isCumulativeMode: filterState.showCumulative,
              hoveredItem: allStatisticFilterState.hoveredItem,
              lastItem: allStatisticFilterState.lastItem,
              availableYear: filterState.availableYear.toList(),
              isUpdating: filterState.isUpdating,
              selectedCaseType: filterState.type,
              selectedTimeFrame: filterState.timeFrame,
              valueFormatter: NumberHelper.numberFormat,
              onYearChanged: (year) => context
                  .read<LineChartLocalStatisticFilter>()
                  .updateSelectedYear(year),
              data: data,
              onToggleMode: (value) => context
                  .read<LineChartLocalStatisticFilter>()
                  .toggleShowCumulative(value),
              onCaseTypeChanged: (value) => context
                  .read<LineChartLocalStatisticFilter>()
                  .updateType(value),
              onTimeFrameChanged: (timeFrame) => context
                  .read<LineChartLocalStatisticFilter>()
                  .updateTimeFrame(timeFrame),
              dataMapper: _getFilteredData,
              onHoverCallback: (index, hoverState) {
                if (!hoverState) {
                  context
                      .read<AllStatisticFilterCubit>()
                      .updateHoveredItem(null);
                } else {
                  context
                      .read<AllStatisticFilterCubit>()
                      .updateHoveredItem(data[index]);
                }
              },
              hoverLabelResolver: (index) => DateHelper.dateWithDayFormat(
                labels[index ?? 0].toLocal(),
                format: 'dd MMM yyyy, HH:mm',
                includeTimeZone: true,
              ),
              dataLabels: labels,
            );
          },
        ),
      );
}
