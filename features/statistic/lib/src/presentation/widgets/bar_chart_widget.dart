import 'package:charts_painter/chart.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class BarChartWidget extends StatelessWidget {
  BarChartWidget({
    required this.title,
    required this.datasets,
    required this.datasetColors,
    required this.datasetVerticalLabels,
    List<String>? datasetColorDescriptions,
    this.backgroundDecorations,
    this.foregroundDecorations,
    super.key,
    this.duration,
    this.trailingHeader,
    this.borderRadius,
    this.numberOfStep = 10,
    this.stacked = true,
  })  : assert(
          datasets.length == datasetVerticalLabels.length,
          'Labels should match datasets length!',
        ),
        assert(
          datasets.first.length == datasetColors.length &&
              datasets.first.length == datasetColorDescriptions?.length &&
              datasetColors.length == datasetColorDescriptions?.length,
          'Dataset colors & color description length must match '
          'dataset`s data length!',
        ),
        assert(
          datasets.every((element) => element.length == datasets.first.length),
          'Every sub data sets must have the same length!',
        ),
        datasetColorDescriptions = datasetColorDescriptions ?? [];

  final bool stacked;
  final String title;
  final int numberOfStep;
  final Duration? duration;
  final Widget? trailingHeader;
  final List<Color> datasetColors;
  final BorderRadius? borderRadius;
  final List<List<num>> datasets;
  final List<String> datasetVerticalLabels;
  final List<String> datasetColorDescriptions;
  final List<DecorationPainter>? backgroundDecorations;
  final List<DecorationPainter>? foregroundDecorations;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.picoColors.background.card.main,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.picoColors.outline.neutral.main,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 16.h,
            top: 8.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: PicoTextStyle.label(),
                    ),
                  ),
                  if (trailingHeader != null) ...[
                    8.horizontalSpace,
                    trailingHeader!,
                  ],
                ],
              ),
              24.verticalSpace,
              AnimatedChart(
                duration: duration ?? 300.milliseconds,
                state: _chartStates(context)[stacked ? 0 : 1],
              ),
              if (datasetColorDescriptions.isNotEmpty) ...[
                16.verticalSpace,
                Text(
                  '${context.translations.general.description} :',
                ),
                8.verticalSpace,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: List.generate(
                    datasetColorDescriptions.length,
                    (index) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: datasetColors[index],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        4.horizontalSpace,
                        Text(
                          datasetColorDescriptions[index],
                          style: PicoTextStyle.body(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  List<ChartState<bool>> _chartStates(BuildContext context) => [
        ChartState<bool>(
          backgroundDecorations: [
            GridDecoration(
              endWithChartVertical: true,
              endWithChartHorizontal: true,
              showHorizontalValues: true,
              showVerticalGrid: false,
              showVerticalValues: true,
              dashArray: [2, 2, 2],
              horizontalLegendPosition: HorizontalLegendPosition.start,
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
                  _getMaxSum().toInt(),
                ),
                numberOfSteps: numberOfStep,
              ).toDouble(),
              horizontalAxisValueFromValue: (value) =>
                  NumberHelper.numberFormat(
                value,
                compact: true,
              ),
              verticalAxisValueFromIndex: (value) =>
                  datasetVerticalLabels[value],
              textStyle: PicoTextStyle.label(
                color: context.picoColors.text.neutral.subtle,
              ),
            ),
            if (backgroundDecorations != null) ...backgroundDecorations!,
          ],
          foregroundDecorations: foregroundDecorations ?? [],
          data: ChartData<bool>(
            [
              _getMaxSumAndSubtractions()
                  .map(
                    (e) => ChartItem<bool>(
                      e.toDouble(),
                      value: false,
                    ),
                  )
                  .toList(),
              ...datasets.map(
                (data) => data
                    .map(
                      (datum) => ChartItem<bool>(
                        datum.toDouble(),
                        value: false,
                      ),
                    )
                    .toList(),
              ),
            ],
            valueAxisMaxOver: 100,
            dataStrategy: const StackDataStrategy(),
          ),
          itemOptions: BarItemOptions(
            padding: EdgeInsets.symmetric(horizontal: 12.r),
            barItemBuilder: (data) {
              return BarItem(
                radius: borderRadius ??
                    BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                color: [
                  context.picoColors.background.neutral.strong,
                  ...datasetColors,
                ][data.listIndex],
              );
            },
          ),
        ),
        ChartState<bool>(
          backgroundDecorations: [
            GridDecoration(
              endWithChartVertical: true,
              endWithChartHorizontal: true,
              showHorizontalValues: true,
              showVerticalGrid: false,
              showVerticalValues: true,
              dashArray: [2, 2, 2],
              horizontalLegendPosition: HorizontalLegendPosition.start,
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
                  _getMaxSum().toInt(),
                ),
                numberOfSteps: numberOfStep,
              ).toDouble(),
              horizontalAxisValueFromValue: (value) =>
                  NumberHelper.numberFormat(
                value,
                compact: true,
              ),
              verticalAxisValueFromIndex: (value) =>
                  datasetVerticalLabels[value],
              textStyle: PicoTextStyle.label(
                color: context.picoColors.text.neutral.subtle,
              ),
            ),
            if (backgroundDecorations != null) ...backgroundDecorations!,
          ],
          foregroundDecorations: foregroundDecorations ?? [],
          data: ChartData<bool>(
            datasets
                .map(
                  (data) => data
                      .map(
                        (datum) => ChartItem<bool>(
                          datum.toDouble(),
                          value: false,
                        ),
                      )
                      .toList(),
                )
                .toList(),
            valueAxisMaxOver: 100,
            dataStrategy: const DefaultDataStrategy(
              stackMultipleValues: false,
            ),
          ),
          itemOptions: BarItemOptions(
            padding: EdgeInsets.symmetric(horizontal: 12.r),
            barItemBuilder: (data) {
              final color = (data.listIndex < datasetColors.length)
                  ? datasetColors[data.listIndex]
                  : Colors.transparent;
              return BarItem(
                radius: borderRadius ??
                    BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                color: color,
              );
            },
          ),
        ),
      ];

  List<num> _getMaxSumAndSubtractions() {
    final length = datasets.first.length;

    // Calculating the sum for each index
    final sums = List<num>.generate(length, (index) => 0);
    for (final list in datasets) {
      for (var i = 0; i < list.length; i++) {
        sums[i] += list[i];
      }
    }

    // Finding the maximum sum
    final maxSum = _getMaxSum();

    // Subtracting each sum from the maximum and returning the result
    final substractions = sums.map((sum) => maxSum - sum).toList();
    return substractions;
  }

  num _getMaxSum() {
    final length = datasets.first.length;

    // Calculating the sum for each index
    final sums = List<num>.generate(length, (index) => 0);
    for (final list in datasets) {
      for (var i = 0; i < list.length; i++) {
        sums[i] += list[i];
      }
    }

    // Finding the maximum sum
    final maxSum = sums.reduce((a, b) => a > b ? a : b);
    return maxSum;
  }
}
