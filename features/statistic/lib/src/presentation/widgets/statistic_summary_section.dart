import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

class StatisticSummarySection extends StatelessWidget {
  const StatisticSummarySection({super.key});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: BlocBuilder<LatestStatisticCubit, LatestStatisticState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: switch (state) {
                      LatestStatisticLoadedState(data: final data) =>
                        PicoUpdatedAtPlaceholder(
                          key: const Key('updated-at-loaded'),
                          date: DateHelper.buildUpdatedAtText(
                            data.updatedAt.toLocal(),
                          ),
                          label: context.translations.statistics.caseLabel(
                            level: context.translations.general.centralSulawesi,
                          ),
                        ),
                      LatestStatisticFailedState() => PicoUpdatedAtPlaceholder(
                          key: const Key('updated-at-failed'),
                          date: '-',
                          label: context.translations.statistics.caseLabel(
                            level: context.translations.general.centralSulawesi,
                          ),
                        ),
                      _ => PicoUpdatedAtPlaceholder(
                          key: const Key('updated-at-loading'),
                          date: '12 December 2023 12.05 WITA',
                          label: context.translations.statistics.caseLabel(
                            level: context.translations.general.centralSulawesi,
                          ),
                        ).sekeletonize(),
                    },
                  ),
                ),
              ),
              8.horizontalSpace,
              TextButton(
                onPressed: () => context.router.push(
                  const StatisticRoute(),
                ),
                child: Text(
                  context.translations.general.button.more,
                ),
              ),
            ],
          ),
          24.verticalSpace,
          BlocBuilder<LatestStatisticCubit, LatestStatisticState>(
            builder: (context, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                LatestStatisticLoadedState(data: final data) =>
                  StatisticDataList(
                    key: const Key('statistic-loaded'),
                    statistic: data,
                    showSuspectCard: false,
                  ),
                LatestStatisticFailedState() => PicoErrorPlaceholder(
                    label: context.translations.feedback.error.statistic,
                    onRetry: () => context.read<LatestStatisticCubit>().fetch(),
                  ),
                LatestStatisticEmptyState() => StatisticDataList(
                    key: const Key('statistic-empty'),
                    showSuspectCard: false,
                  ),
                _ => StatisticDataList(
                    key: const Key('statistic-loading'),
                    showSuspectCard: false,
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
                  ).sekeletonize(),
              },
            ),
          ),
        ],
      );
}
