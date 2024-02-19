import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/domain/enums/enums.dart';
import 'package:statistic/src/presentation/widgets/case_type_dropdown.dart';
import 'package:statistic/src/presentation/widgets/data_year_dropdown.dart';
import 'package:statistic/src/presentation/widgets/line_chart_value_header.dart';
import 'package:statistic/src/presentation/widgets/time_frame_selector.dart';
import 'package:statistic/statistic.dart';

class LineChartCase extends StatefulWidget {
  const LineChartCase({super.key});

  @override
  State<LineChartCase> createState() => _LineChartCaseState();
}

class _LineChartCaseState extends State<LineChartCase> {
  late final PCLineChartController _chartController;

  bool _isInitialLoad = true;
  late final ValueNotifier<List<DateTime>> _labelsNotifier;

  @override
  void initState() {
    super.initState();
    _labelsNotifier = ValueNotifier([]);
    _chartController = PCLineChartController();
  }

  @override
  void dispose() {
    _labelsNotifier.dispose();
    _chartController.dispose();

    super.dispose();
  }

  List<Statistic> _getFilteredData(List<Statistic> data) {
    final filterState = context.read<LineChartFilterCubit>().state;
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

    var offset = filteredData.length - filterState.timeFrame.offset;

    if (offset < 0) {
      offset = filteredData.length + offset;
    }

    return switch (filterState.timeFrame) {
      DataTimeFrame.all => filteredData,
      _ => filteredData.sublist(
          offset,
        ),
    };
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<LineChartFilterCubit, LineChartFilterState>(
        listener: (context, state) {
          final dataState = context.read<AllStatisticsCubit>().state;

          if (state.isUpdating) {
            _chartController.updateState(PCChartState.loading);
          }

          if (!_isInitialLoad &&
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
        child: Container(
          decoration: BoxDecoration(
            color: context.picoColors.background.card.main,
            borderRadius: BorderRadius.circular(PCRadius.md),
            border: Border.all(
              color: context.picoColors.outline.neutral.main,
            ),
          ),
          padding: EdgeInsets.all(
            PCSpacing.s16.r,
          ),
          height: 500.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BlocBuilder<LineChartFilterCubit, LineChartFilterState>(
                    builder: (context, state) => Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.translations.chart.line_chart.title(
                              name: state.type.label(context).toLowerCase(),
                            ),
                            textAlign: TextAlign.start,
                            style: PicoTextStyle.headingXs(),
                          ),
                          PCSpacing.s4.h.verticalSpace,
                          PicoSwitch(
                            value: state.showCumulative,
                            onToggle: (value) => context
                                .read<LineChartFilterCubit>()
                                .toggleShowCumulative(value),
                            labelPosition: PicoSwitchLabelPosition.trailing,
                            label: context.translations.chart.line_chart
                                .filter_label.cumulative,
                          ),
                        ],
                      ),
                    ),
                  ),
                  PCSpacing.s16.horizontalSpace,
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BlocBuilder<LineChartFilterCubit, LineChartFilterState>(
                          builder: (context, state) {
                            return CaseTypeDropdown(
                              data: CaseType.values,
                              onChanged: (value) => context
                                  .read<LineChartFilterCubit>()
                                  .updateType(value),
                              value: state.type,
                            );
                          },
                        ),
                        PCSpacing.s8.horizontalSpace,
                        BlocBuilder<LineChartFilterCubit, LineChartFilterState>(
                          builder: (context, state) {
                            final dataState =
                                context.watch<AllStatisticsCubit>().state;
                            var data = <Statistic>[];

                            if (dataState is AllStatisticsLoaded) {
                              data = dataState.data;
                            }

                            return DataYearDropdown(
                              value: state.selectedYear,
                              data: data
                                  .map((e) => e.updatedAt.year)
                                  .toSet()
                                  .toList(),
                              onChanged: (value) => context
                                  .read<LineChartFilterCubit>()
                                  .updateSelectedYear(value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              PCSpacing.s24.verticalSpace,
              Builder(
                builder: (context) {
                  final statisticFilterState =
                      context.watch<AllStatisticFilterCubit>().state;
                  final lineChartFilterState =
                      context.watch<LineChartFilterCubit>().state;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (_) {
                          Widget child =
                              LineChartValueHeader.skeleton().sekeletonize();
                          if (lineChartFilterState.isUpdating) {
                            child =
                                LineChartValueHeader.skeleton().sekeletonize();
                          } else {
                            if (statisticFilterState.hoveredItem == null) {
                              child = LineChartValueHeader(
                                newCase: lineChartFilterState.type
                                    .getNewCases(statisticFilterState.lastItem),
                                totalCase:
                                    lineChartFilterState.type.getCumulative(
                                  statisticFilterState.lastItem,
                                ),
                                updatedAt: statisticFilterState
                                    .lastItem.updatedAt
                                    .toLocal(),
                                caseType: lineChartFilterState.type,
                              );
                            } else {
                              child = LineChartValueHeader(
                                newCase: lineChartFilterState.type.getNewCases(
                                  statisticFilterState.hoveredItem!,
                                ),
                                totalCase:
                                    lineChartFilterState.type.getCumulative(
                                  statisticFilterState.hoveredItem!,
                                ),
                                updatedAt: statisticFilterState
                                    .hoveredItem!.updatedAt
                                    .toLocal(),
                                caseType: lineChartFilterState.type,
                              );
                            }
                          }

                          return AnimatedSwitcher(
                            duration: 300.milliseconds,
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: child,
                          );
                        },
                      ),
                      PCSpacing.s16.horizontalSpace,
                      AnimatedContainer(
                        duration: 300.milliseconds,
                        width: 64.w,
                        height: 64.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lineChartFilterState.type
                              .color(context)
                              .withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(PCSpacing.s16),
                        child: lineChartFilterState.type.icon(context),
                      ),
                    ],
                  );
                },
              ),
              PCSpacing.s24.verticalSpace,
              Expanded(
                child: Builder(
                  builder: (context) {
                    final dataState = context.watch<AllStatisticsCubit>().state;
                    final lineChartFilterState =
                        context.watch<LineChartFilterCubit>().state;

                    Widget child = Center(
                      child: SpinKitFadingCircle(
                        color: context.picoColors.icon.semantic.primary,
                        size: 20.sp,
                      ),
                    );
                    if (_isInitialLoad && dataState is AllStatisticsLoading) {
                      _chartController.updateState(PCChartState.loading);
                      child = Center(
                        child: SpinKitFadingCircle(
                          color: context.picoColors.icon.semantic.primary,
                          size: 20.sp,
                        ),
                      );
                    } else if (dataState is AllStatisticsFailed) {
                      _chartController.updateState(PCChartState.failed);
                    } else if (dataState is AllStatisticsLoaded) {
                      if (_isInitialLoad) {
                        context.read<LineChartFilterCubit>().updateStatus(
                              status: false,
                            );
                      }
                      _isInitialLoad = false;

                      final data = _getFilteredData(dataState.data);
                      _labelsNotifier.value =
                          data.map((e) => e.updatedAt).toList();
                      final filteredData = lineChartFilterState.type.filterData(
                        data,
                        showCumulative: lineChartFilterState.showCumulative,
                      );

                      child = PCLineChart(
                        controller: _chartController,
                        data: PCLineChartData(
                          data: filteredData,
                        ),
                        lineColor: lineChartFilterState.type
                            .color(context)
                            .withOpacity(0.8),
                        dotColor: lineChartFilterState.type.color(context),
                        onHoverCallback: (index, {required hoverState}) {
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
                        hoverLabelResolver: (index) {
                          return DateHelper.dateWithDayFormat(
                            _labelsNotifier.value[index ?? 0].toLocal(),
                            format: 'dd MMM yyyy, HH:mm',
                            includeTimeZone: true,
                          );
                        },
                        valueFormatter: NumberHelper.numberFormat,
                      );
                    }

                    return AnimatedSwitcher(
                      duration: 300.milliseconds,
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ),
              PCSpacing.s24.verticalSpace,
              BlocBuilder<LineChartFilterCubit, LineChartFilterState>(
                builder: (context, state) => TimeFrameSelector(
                  value: state.timeFrame,
                  onSelected: (value) => context
                      .read<LineChartFilterCubit>()
                      .updateTimeFrame(value),
                ),
              ),
            ],
          ),
        ),
      );
}
