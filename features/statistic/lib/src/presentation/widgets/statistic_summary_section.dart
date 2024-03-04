import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

class StatisticSummarySection extends StatelessWidget {
  const StatisticSummarySection({super.key});

  String _regencyLogo(int id) => switch (id) {
        7201 =>
          'https://upload.wikimedia.org/wikipedia/commons/b/b1/Lambang_Kabupaten_Banggai_Kepulauan_%282015-sekarang%29.png',
        7202 =>
          'https://beranda.banggaikab.go.id/banggaikonten/uploads/2017/04/LOGO_KABUPATEN_BANGGAI_ORI.png',
        7203 =>
          'https://upload.wikimedia.org/wikipedia/commons/b/bc/Lambang_Kabupaten_Morowali_%282015-sekarang%29.png',
        7204 =>
          'https://upload.wikimedia.org/wikipedia/commons/b/b4/Lambang_Kabupaten_Poso.png',
        7205 =>
          'https://sulteng.bpk.go.id/wp-content/uploads/2019/09/Lambang_Kabupaten_Donggala-253x300.png',
        7206 =>
          'https://sulteng.bpk.go.id/wp-content/uploads/2011/11/toli2.jpg',
        7207 =>
          'https://e7.pngegg.com/pngimages/302/266/png-clipart-buol-regency-bongo-indonesian-language-pantai-pasir-putih-buol-buol-regency-thumbnail.png',
        7208 =>
          'https://upload.wikimedia.org/wikipedia/commons/2/2c/Lambang_Kabupaten_Parigi_Moutong.png',
        7209 =>
          'https://upload.wikimedia.org/wikipedia/commons/f/fd/Lambang_Kabupaten_Tojo_Una-Una.png',
        7210 =>
          'https://upload.wikimedia.org/wikipedia/commons/5/58/Lambang_Kabupaten_Sigi.png',
        7211 =>
          'https://upload.wikimedia.org/wikipedia/commons/e/e7/Lambang_Kabupaten_Banggai_Laut_%282015-sekarang%29.png',
        7212 =>
          'https://upload.wikimedia.org/wikipedia/commons/7/70/Lambang_Kabupaten_Morowali_Utara.png',
        7271 =>
          'https://upload.wikimedia.org/wikipedia/commons/5/54/Lambang_Kota_Palu.png',
        _ =>
          'https://d22gwcrfo2de51.cloudfront.net/wp-content/uploads/2020/09/LOGO_7200_SULAWESI-TENGAH_thumb.png',
      };

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
          PicoCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Text(
                    '${context.translations.statistics.caseLabelDaily(
                      type: context.translations.statistics.caseType.active,
                    )} by ${context.translations.general.regency}',
                    style: PicoTextStyle.label(),
                  ),
                ),
                BlocBuilder<AllRegenciesCubit, AllRegenciesState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: 300.milliseconds,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: switch (state) {
                      AllRegenciesLoading() => Center(
                          child: SpinKitFadingCircle(
                            size: 20.sp,
                            color: context.picoColors.icon.semantic.primary,
                          ),
                        ),
                      AllRegenciesFailed(failure: final failure) => Center(
                          child: Text(
                            failure.message,
                          ),
                        ),
                      AllRegenciesLoaded(data: final data) =>
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: data
                                .map(
                                  (regency) => PicoCircularBarItem(
                                    value: regency.newCase.underTreatment
                                        .toDouble(),
                                    maxValue: state.maxValue,
                                    scale: PCChartScale.linear,
                                    valueFormatter: (value) {
                                      final buffer = StringBuffer()
                                        ..write(
                                          NumberHelper.numberFormat(value),
                                        )
                                        ..write(' ')
                                        ..write(
                                          context.translations.statistics
                                              .caseSuffix(
                                            n: value.abs(),
                                          ),
                                        );
                                      return buffer.toString();
                                    },
                                    logo: _regencyLogo(regency.id),
                                    label: regency.id.toString(),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
                16.h.verticalSpace,
              ],
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
