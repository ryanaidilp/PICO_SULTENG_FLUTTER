import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/widgets/all_national_statistic_chart_section.dart';
import 'package:statistic/src/presentation/widgets/statistic_data_list.dart';
import 'package:statistic/statistic.dart';

class NationalStatisticSummarySection extends StatelessWidget {
  const NationalStatisticSummarySection({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AllNationalStatisticChartSection(),
          PCSpacing.s16.h.verticalSpace,
          BlocBuilder<LatestNationalStatisticCubit,
              LatestNationalStatisticState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestNationalStatisticLoadedState(data: final data) =>
                  StatisticDataList(
                    key: const Key('statistic-loaded'),
                    statistic: data,
                    showSuspectCard: false,
                  ),
                LatestNationalStatisticFailedState() => PicoErrorPlaceholder(
                    label: context.i10n.error.statistic,
                    onRetry: () =>
                        context.read<LatestNationalStatisticCubit>().fetch(),
                  ),
                _ => StatisticDataList(
                    key: const Key('statistic-loading'),
                    showSuspectCard: false,
                  ).sekeletonize(),
              },
            ),
          ),
        ],
      );
}
