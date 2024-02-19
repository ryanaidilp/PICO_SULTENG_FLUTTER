import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/domain/enums/enums.dart';
import 'package:statistic/src/presentation/widgets/line_chart_case.dart';
import 'package:statistic/statistic.dart';

class AllNationalStatisticChartSection extends StatefulWidget {
  const AllNationalStatisticChartSection({super.key});

  @override
  State<AllNationalStatisticChartSection> createState() =>
      _AllNationalStatisticChartState();
}

class _AllNationalStatisticChartState
    extends State<AllNationalStatisticChartSection> {
  late final PCLineChartController _chartController;
  bool _isInitialLoading = true;
  late final ValueNotifier<List<DateTime>> _labelsNotifier;

  @override
  void initState() {
    super.initState();
    _chartController = PCLineChartController();
    _labelsNotifier = ValueNotifier([]);
    final dataState = context.read<AllNationalStatisticsCubit>().state;
    _isInitialLoading = dataState is AllNationalStatisticsLoading;
    if (!_isInitialLoading) {
      context.read<LineChartNationalStatisticFilter>().updateStatus(
            status: false,
          );
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _labelsNotifier.dispose();
    super.dispose();
  }

  List<Statistic> _getFilteredData(List<Statistic> data) {
    final filterState = context.read<LineChartNationalStatisticFilter>().state;
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
          BlocListener<LineChartNationalStatisticFilter,
              LineChartNationalStatisticState>(
            listener: (context, state) {
              final dataState =
                  context.read<AllNationalStatisticsCubit>().state;

              if (state.isUpdating) {
                _chartController.updateState(PCChartState.loading);
              }

              if (!_isInitialLoading &&
                  !state.isUpdating &&
                  dataState is AllNationalStatisticsLoaded) {
                final filteredData = _getFilteredData(dataState.data);
                _labelsNotifier.value =
                    filteredData.map((e) => e.updatedAt).toList();

                context
                    .read<AllNationalStatisticFilterCubit>()
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
          BlocListener<AllNationalStatisticsCubit, AllNationalStatisticsState>(
            listener: (context, state) async {
              if (state is AllNationalStatisticsLoaded) {
                if (_isInitialLoading) {
                  context.read<LineChartNationalStatisticFilter>().updateStatus(
                        status: false,
                      );
                  await context
                      .read<LineChartNationalStatisticFilter>()
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
            final dataState = context.watch<AllNationalStatisticsCubit>().state;
            final allStatisticFilterState =
                context.watch<AllNationalStatisticFilterCubit>().state;
            final filterState =
                context.watch<LineChartNationalStatisticFilter>().state;

            var data = <Statistic>[];
            if (_isInitialLoading &&
                dataState is AllNationalStatisticsLoading) {
              _chartController.updateState(PCChartState.loading);
            } else if (dataState is AllNationalStatisticsLoaded) {
              data = _getFilteredData(dataState.data);
              context
                  .read<AllNationalStatisticFilterCubit>()
                  .updateLastItem(data.last);
              _labelsNotifier.value = data.map((e) => e.updatedAt).toList();
            } else if (dataState is AllNationalStatisticsFailed) {
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
                  .read<LineChartNationalStatisticFilter>()
                  .updateSelectedYear(year),
              data: data,
              onToggleMode: (value) => context
                  .read<LineChartNationalStatisticFilter>()
                  .toggleShowCumulative(value),
              onCaseTypeChanged: (value) => context
                  .read<LineChartNationalStatisticFilter>()
                  .updateType(value),
              onTimeFrameChanged: (timeFrame) => context
                  .read<LineChartNationalStatisticFilter>()
                  .updateTimeFrame(timeFrame),
              dataMapper: _getFilteredData,
              onHoverCallback: (index, hoverState) {
                if (!hoverState) {
                  context
                      .read<AllNationalStatisticFilterCubit>()
                      .updateHoveredItem(null);
                } else {
                  context
                      .read<AllNationalStatisticFilterCubit>()
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
