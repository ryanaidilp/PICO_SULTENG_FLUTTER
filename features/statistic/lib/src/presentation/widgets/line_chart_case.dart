// ignore_for_file: avoid_positional_boolean_parameters

import 'package:core/core.dart';
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

class LineChartCase extends StatelessWidget {
  const LineChartCase({
    required this.caseLabel,
    required this.onToggleMode,
    required this.availableYear,
    required this.onYearChanged,
    required this.onCaseTypeChanged,
    required this.lastItem,
    required this.dataMapper,
    required this.data,
    required this.onHoverCallback,
    required this.hoverLabelResolver,
    required this.valueFormatter,
    required this.onTimeFrameChanged,
    required this.chartController,
    required this.dataLabels,
    this.selectedYear,
    this.hoveredItem,
    this.isUpdating = true,
    this.isInitialLoading = true,
    this.isCumulativeMode = false,
    this.selectedCaseType = CaseType.underTreatment,
    this.selectedTimeFrame = DataTimeFrame.all,
    super.key,
  });

  final int? selectedYear;
  final String caseLabel;
  final bool isCumulativeMode;
  final bool isUpdating;
  final bool isInitialLoading;
  final List<int> availableYear;
  final CaseType selectedCaseType;
  final void Function(bool value) onToggleMode;
  final void Function(int? year) onYearChanged;
  final void Function(int index, bool hoverState) onHoverCallback;
  final void Function(CaseType value) onCaseTypeChanged;
  final Statistic? hoveredItem;
  final Statistic lastItem;
  final List<Statistic> data;
  final List<Statistic> Function(List<Statistic> data) dataMapper;
  final List<DateTime> dataLabels;
  final String Function(int? index) hoverLabelResolver;
  final String Function(double value) valueFormatter;
  final DataTimeFrame selectedTimeFrame;
  final void Function(DataTimeFrame timeFrame) onTimeFrameChanged;
  final PCLineChartController chartController;

  @override
  Widget build(BuildContext context) => PicoCard(
        height: 500.h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translations.chart.line_chart.title(
                          name: caseLabel.toLowerCase(),
                        ),
                        textAlign: TextAlign.start,
                        style: PicoTextStyle.headingXs(),
                      ),
                      PCSpacing.s4.h.verticalSpace,
                      PicoSwitch(
                        value: isCumulativeMode,
                        onToggle: onToggleMode,
                        labelPosition: PicoSwitchLabelPosition.trailing,
                        label: context.translations.chart.line_chart
                            .filter_label.cumulative,
                      ),
                    ],
                  ),
                ),
                PCSpacing.s16.horizontalSpace,
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CaseTypeDropdown(
                        data: CaseType.values,
                        onChanged: onCaseTypeChanged,
                        value: selectedCaseType,
                      ),
                      PCSpacing.s8.horizontalSpace,
                      DataYearDropdown(
                        value: selectedYear,
                        data: availableYear,
                        onChanged: onYearChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            PCSpacing.s24.verticalSpace,
            Builder(
              builder: (context) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (_) {
                        Widget child =
                            LineChartValueHeader.skeleton().sekeletonize();
                        if (isUpdating) {
                          child =
                              LineChartValueHeader.skeleton().sekeletonize();
                        } else {
                          if (hoveredItem == null) {
                            child = LineChartValueHeader(
                              newCase: selectedCaseType.getNewCases(lastItem),
                              totalCase: selectedCaseType.getCumulative(
                                lastItem,
                              ),
                              updatedAt: lastItem.updatedAt.toLocal(),
                              caseType: selectedCaseType,
                            );
                          } else {
                            child = LineChartValueHeader(
                              newCase: selectedCaseType.getNewCases(
                                hoveredItem!,
                              ),
                              totalCase: selectedCaseType.getCumulative(
                                hoveredItem!,
                              ),
                              updatedAt: hoveredItem!.updatedAt.toLocal(),
                              caseType: selectedCaseType,
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
                        color: selectedCaseType.color(context).withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.all(PCSpacing.s16),
                      child: selectedCaseType.icon(context),
                    ),
                  ],
                );
              },
            ),
            PCSpacing.s24.verticalSpace,
            Expanded(
              child: Builder(
                builder: (context) {
                  Widget child = Center(
                    child: SpinKitFadingCircle(
                      color: context.picoColors.icon.semantic.primary,
                      size: 20.sp,
                    ),
                  );

                  if (isInitialLoading) {
                    child = Center(
                      child: SpinKitFadingCircle(
                        color: context.picoColors.icon.semantic.primary,
                        size: 20.sp,
                      ),
                    );
                  } else {
                    child = PCLineChart(
                      controller: chartController,
                      data: PCLineChartData(
                        data: selectedCaseType.filterData(
                          dataMapper(data),
                          showCumulative: isCumulativeMode,
                        ),
                      ),
                      lineColor:
                          selectedCaseType.color(context).withOpacity(0.8),
                      dotColor: selectedCaseType.color(context),
                      onHoverCallback: (index, {required hoverState}) =>
                          onHoverCallback(
                        index,
                        hoverState,
                      ),
                      hoverLabelResolver: hoverLabelResolver,
                      valueFormatter: valueFormatter,
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
            TimeFrameSelector(
              value: selectedTimeFrame,
              onSelected: onTimeFrameChanged,
            ),
          ],
        ),
      );
}
