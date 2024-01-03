import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/widgets/statistic_data_list.dart';
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
                child: BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: switch (state) {
                      LatestStatisticLoadedState(data: final data) =>
                        PicoUpdatedAtPlaceholder(
                          key: const Key('updated-at-loaded'),
                          date: DateHelper.buildUpdatedAtText(
                            data.updatedAt.toLocal(),
                          ),
                          label: context.i10n.data_case_label,
                        ),
                      LatestStatisticFailedState() => PicoUpdatedAtPlaceholder(
                          key: const Key('updated-at-failed'),
                          date: '-',
                          label: context.i10n.data_case_label,
                        ),
                      _ => PicoUpdatedAtPlaceholder(
                          key: const Key('updated-at-loading'),
                          date: '12 December 2023 12.05 WITA',
                          label: context.i10n.data_case_label,
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
                  context.i10n.buttons.more,
                ),
              ),
            ],
          ),
          24.verticalSpace,
          BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
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
                    label: context.i10n.error.statistic,
                    onRetry: () => context.read<LatestStatisticBloc>().add(
                          LatestStatisticEvent.load(),
                        ),
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
                  ).sekeletonize(),
              },
            ),
          ),
        ],
      );
}
