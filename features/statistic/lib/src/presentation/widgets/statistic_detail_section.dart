import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

class StatisticDetailSection extends StatelessWidget {
  const StatisticDetailSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AllStatisticChartSection(),
          PCSpacing.s16.h.verticalSpace,
          BlocBuilder<LatestStatisticCubit, LatestStatisticState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestStatisticLoadedState(data: final data) =>
                  StatisticDataList(
                    key: const Key('statistic-loaded'),
                    statistic: data,
                  ),
                LatestStatisticFailedState() => PicoErrorPlaceholder(
                    label: context.translations.feedback.error.statistic,
                    onRetry: () => context.read<LatestStatisticCubit>().fetch(),
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
          BlocBuilder<LatestCovidTestCubit, LatestCovidTestState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestCovidTestFailedState() => PicoErrorPlaceholder(
                    label: context.translations.feedback.error.test,
                    onRetry: () => context.read<LatestCovidTestCubit>().fetch(),
                  ),
                LatestCovidTestLoadedState(
                  total: final total,
                ) =>
                  PicoTotalTestCardTile(
                    key: const Key('total-test-loaded'),
                    total: total,
                    onTap: () => context.router.push(const TestDetailRoute()),
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
