import 'dart:math';

import 'package:charts_painter/chart.dart';
import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/blocs/latest_statistic/latest_statistic_bloc.dart';

class BarChartODPAndPDP extends StatelessWidget {
  const BarChartODPAndPDP({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
        builder: (context, state) => switch (state) {
          LatestStatisticLoadedState(
            data: final data,
          ) =>
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.picoColors.background.subtle,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.picoColors.outline.neutral.main,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.verticalSpace,
                    AnimatedChart(
                      duration: 300.milliseconds,
                      state: ChartState<void>(
                        backgroundDecorations: [
                          GridDecoration(
                            endWithChartVertical: true,
                            endWithChartHorizontal: true,
                            showHorizontalValues: true,
                            showVerticalGrid: false,
                            showVerticalValues: true,
                            horizontalAxisUnit:
                                context.i10n.chart.odp_pdp.title,
                            dashArray: [2, 2, 2],
                            horizontalLegendPosition:
                                HorizontalLegendPosition.start,
                            gridColor: context.picoColors.text.neutral.subtle,
                            gridWidth: 2,
                            horizontalValuesPadding: EdgeInsets.only(
                              bottom: -6.h,
                              right: 8.w,
                            ),
                            verticalValuesPadding: EdgeInsets.only(
                              top: 24.h,
                            ),
                            horizontalAxisStep: NumberHelper.calculateStep(
                              maxValue: NumberHelper.ceilToNearest(
                                max(
                                  data.cumulative.totalObserved,
                                  data.cumulative.totalSupervised,
                                ),
                              ),
                              numberOfSteps: 10,
                            ).toDouble(),
                            horizontalAxisValueFromValue: (value) =>
                                NumberHelper.numberFormat(
                              value,
                              compact: true,
                            ),
                            verticalAxisValueFromIndex: (value) => [
                              context.i10n.chart.odp_pdp.labels.odp,
                              context.i10n.chart.odp_pdp.labels.pdp,
                            ][value],
                            textStyle: PicoTextStyle.label(
                              color: context.picoColors.text.neutral.subtle,
                            ),
                          ),
                        ],
                        data: ChartData(
                          valueAxisMaxOver: 100,
                          dataStrategy: const StackDataStrategy(),
                          [
                            [
                              ChartItem<bool>(
                                max(
                                      data.cumulative.totalObserved,
                                      data.cumulative.totalSupervised,
                                    ).toDouble() -
                                    data.cumulative.totalObserved,
                                value: false,
                              ),
                              ChartItem<bool>(
                                max(
                                      data.cumulative.totalObserved,
                                      data.cumulative.totalSupervised,
                                    ).toDouble() -
                                    data.cumulative.totalSupervised,
                                value: false,
                              ),
                            ],
                            [
                              ChartItem<bool>(
                                data.cumulative.underObservation.toDouble(),
                                value: false,
                              ),
                              ChartItem<bool>(
                                data.cumulative.underSupervision.toDouble(),
                                value: false,
                              ),
                            ],
                            [
                              ChartItem<bool>(
                                data.cumulative.finishedObservation.toDouble(),
                                value: false,
                              ),
                              ChartItem<bool>(
                                data.cumulative.finishedSupervision.toDouble(),
                                value: false,
                              ),
                            ],
                          ],
                        ),
                        itemOptions: BarItemOptions(
                          padding: EdgeInsets.symmetric(horizontal: 12.r),
                          barItemBuilder: (data) {
                            final borderRadius =
                                data.listIndex == 0 || data.item.max != 0
                                    ? BorderRadius.vertical(
                                        top: Radius.circular(12.r),
                                      )
                                    : null;
                            return BarItem(
                              radius: borderRadius,
                              color: [
                                context.picoColors.background.strong,
                                context.picoColors.icon.semantic.warning,
                                context.picoColors.icon.semantic.success,
                              ][data.listIndex],
                            );
                          },
                        ),
                      ),
                    ),
                    16.verticalSpace,
                    Text(
                      '${context.i10n.description} :',
                    ),
                    8.verticalSpace,
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16.w,
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: context.picoColors.text.semantic.warning,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                            4.horizontalSpace,
                            Text(
                              context.i10n.chart.odp_pdp.description.active,
                              style: PicoTextStyle.body(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16.w,
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: context.picoColors.text.semantic.success,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                            4.horizontalSpace,
                            Text(
                              context.i10n.chart.odp_pdp.description.finished,
                              style: PicoTextStyle.body(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          _ => 16.verticalSpace,
        },
      );
}
