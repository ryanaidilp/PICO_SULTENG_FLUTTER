import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/blocs/blocs.dart';
import 'package:statistic/src/presentation/widgets/statistic_data_list.dart';

class NationalStatisticSummarySection extends StatelessWidget {
  const NationalStatisticSummarySection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LatestNationalStatisticBloc, LatestNationalStatisticState>(
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
                onRetry: () => context.read<LatestNationalStatisticBloc>().add(
                      LatestNationalStatisticEvent.load(),
                    ),
              ),
            _ => StatisticDataList(
                key: const Key('statistic-loading'),
                showSuspectCard: false,
              ).sekeletonize(),
          },
        ),
      );
}
