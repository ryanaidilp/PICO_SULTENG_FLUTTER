import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/widgets/bar_chart_odp_and_pdp.dart';
import 'package:statistic/statistic.dart';

@RoutePage()
class StatisticPage extends StatelessWidget {
  const StatisticPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 128.h,
            scrolledUnderElevation: 10.h,
            surfaceTintColor: context.picoColors.background.neutral.main,
            shadowColor: context.picoColors.text.neutral.main.withOpacity(0.1),
            title: BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
              builder: (context, state) => AnimatedSwitcher(
                duration: 300.milliseconds,
                child: switch (state) {
                  LatestStatisticLoadedState(data: final data) =>
                    PicoUpdatedAtPlaceholder(
                      date: DateHelper.buildUpdatedAtText(
                        data.updatedAt.toLocal(),
                      ),
                      label: context.i10n.data_case_label,
                    ),
                  LatestStatisticFailedState() => PicoUpdatedAtPlaceholder(
                      date: '-',
                      label: context.i10n.data_case_label,
                    ),
                  _ => PicoUpdatedAtPlaceholder(
                      date: '12 December 2023 12.05 WITA',
                      label: context.i10n.data_case_label,
                    ).sekeletonize(),
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const StatisticDetailSection(),
                ),
                Divider(
                  color: context.picoColors.background.neutral.subtle,
                  thickness: 8.h,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.i10n.chart.title,
                            style: PicoTextStyle.labelLg(),
                          ),
                          8.horizontalSpace,
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              context.i10n.buttons.more,
                            ),
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      const BarChartODPAndPDP(),
                      24.verticalSpace,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
