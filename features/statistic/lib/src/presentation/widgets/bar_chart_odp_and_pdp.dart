import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/widgets/bar_chart_widget.dart';
import 'package:statistic/statistic.dart';

class BarChartODPAndPDP extends StatefulWidget {
  const BarChartODPAndPDP({super.key});

  @override
  State<BarChartODPAndPDP> createState() => _BarChartODPAndPDPState();
}

class _BarChartODPAndPDPState extends State<BarChartODPAndPDP> {
  late ValueNotifier<bool> _stackedNotifier;

  @override
  void initState() {
    super.initState();
    _stackedNotifier = ValueNotifier(true);
  }

  @override
  void dispose() {
    _stackedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LatestStatisticCubit, LatestStatisticState>(
        builder: (context, state) => switch (state) {
          LatestStatisticLoadedState(
            data: final data,
          ) =>
            ValueListenableBuilder(
              valueListenable: _stackedNotifier,
              builder: (context, value, child) => BarChartWidget(
                title: context.translations.statistics.chart.odpPdp.title,
                duration: 700.milliseconds,
                stacked: value,
                trailingHeader: Row(
                  children: [
                    ActionChip(
                      label: Icon(
                        Icons.bar_chart_rounded,
                        size: 16.sp,
                        color: !value
                            ? Colors.white
                            : context.picoColors.icon.neutral.disabled,
                      ),
                      side: !value
                          ? BorderSide.none
                          : BorderSide(
                              color: context.picoColors.outline.neutral.subtle,
                            ),
                      backgroundColor: !value
                          ? context.picoColors.semantic.primary
                          : Colors.transparent,
                      padding: EdgeInsets.zero,
                      onPressed: () => _stackedNotifier.value = false,
                    ),
                    ActionChip(
                      label: Icon(
                        Icons.stacked_bar_chart_rounded,
                        size: 16.sp,
                        color: value
                            ? Colors.white
                            : context.picoColors.icon.neutral.disabled,
                      ),
                      side: value
                          ? BorderSide.none
                          : BorderSide(
                              color: context.picoColors.outline.neutral.subtle,
                            ),
                      backgroundColor: value
                          ? context.picoColors.semantic.primary
                          : Colors.transparent,
                      padding: EdgeInsets.zero,
                      onPressed: () => _stackedNotifier.value = true,
                    ),
                  ],
                ),
                datasets: [
                  [
                    data.cumulative.underObservation.toDouble(),
                    data.cumulative.underSupervision.toDouble(),
                  ],
                  [
                    data.cumulative.finishedObservation.toDouble(),
                    data.cumulative.finishedSupervision.toDouble(),
                  ],
                ],
                datasetColors: [
                  context.picoColors.icon.semantic.warning,
                  context.picoColors.icon.semantic.success,
                ],
                datasetColorDescriptions: [
                  context
                      .translations.statistics.chart.odpPdp.description.active,
                  context.translations.statistics.chart.odpPdp.description
                      .finished,
                ],
                datasetVerticalLabels: [
                  context.translations.statistics.chart.odpPdp.labels.odp,
                  context.translations.statistics.chart.odpPdp.labels.pdp,
                ],
              ),
            ),
          _ => 16.verticalSpace,
        },
      );
}
