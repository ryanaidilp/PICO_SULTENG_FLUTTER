import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/widgets/statistic_data_list.dart';
import 'package:statistic/statistic.dart';

class StatisticDetailSection extends StatelessWidget {
  const StatisticDetailSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestStatisticLoadedState(data: final data) =>
                  StatisticDataList(
                    key: const Key('statistic-loaded'),
                    statistic: data,
                  ),
                LatestStatisticFailedState() => PicoErrorPlaceholder(
                    label: context.i10n.error.statistic,
                    onRetry: () => context.read<LatestStatisticBloc>().add(
                          LatestStatisticEvent.load(),
                        ),
                  ),
                LatestStatisticEmptyState() => StatisticDataList(
                    key: const Key('statistic-empty'),
                  ),
                _ => StatisticDataList(
                    key: const Key('statistic-loading'),
                  ).sekeletonize(),
              },
            ),
          ),
          16.verticalSpace,
          BlocBuilder<LatestCovidTestBloc, LatestCovidTestState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestCovidTestFailedState() => PicoErrorPlaceholder(
                    label: context.i10n.error.test,
                    onRetry: () => context.read<LatestCovidTestBloc>().add(
                          LatestCovidTestEvent.load(),
                        ),
                  ),
                LatestCovidTestLoadedState(
                  total: final total,
                ) =>
                  PicoTotalTestCardTile(
                    key: const Key('total-test-loaded'),
                    total: total,
                    onTap: () {},
                  ),
                LatestCovidTestEmptyState() => PicoTotalTestCardTile(
                    key: const Key('total-test-empty'),
                    onTap: () {},
                  ),
                _ => const PicoTotalTestCardTile(
                    key: Key('total-test-loading'),
                    total: 12600,
                  ).sekeletonize(),
              },
            ),
          ),
        ],
      );
}
