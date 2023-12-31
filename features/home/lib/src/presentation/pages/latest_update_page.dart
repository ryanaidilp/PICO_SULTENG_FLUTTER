import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/src/domain/entities/banner.dart' as entity;
import 'package:home/src/presentation/blocs/blocs.dart';

import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

@RoutePage()
class LatestUpdatePage extends StatefulWidget {
  const LatestUpdatePage({super.key});

  @override
  State<LatestUpdatePage> createState() => _LatestUpdatePageState();
}

class _LatestUpdatePageState extends State<LatestUpdatePage> {
  late final RefreshController _refreshController;
  int _refreshCounter = 0;
  int _errorCounter = 3;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _onLoading();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onLoading() {
    _refreshCounter = 3;
    _errorCounter = 0;
    context.read<BannerBloc>().add(BannerEvent.load());
    context.read<LatestStatisticBloc>().add(LatestStatisticEvent.load());
    context.read<LatestCovidTestBloc>().add(LatestCovidTestEvent.load());
  }

  void _onRefresh() {
    _refreshCounter = 3;
    _errorCounter = 0;
    _refreshController.requestRefresh();
    context.read<BannerBloc>().add(BannerEvent.load());
    context.read<LatestStatisticBloc>().add(LatestStatisticEvent.load());
    context.read<LatestCovidTestBloc>().add(LatestCovidTestEvent.load());
  }

  void _onBlocRefreshCompleted() {
    _refreshCounter--;

    if (_refreshCounter == 0 && _errorCounter == 0) {
      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
    }
  }

  void _onBlocError() {
    _errorCounter++;

    if (_errorCounter > 0 && _refreshCounter == 0) {
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<BannerBloc, BannerState>(
            listener: (context, state) {
              if (state is BannerLoadedState) {
                _onBlocRefreshCompleted();
              } else if (state is BannerFailedState) {
                _onBlocError();
              }
            },
          ),
          BlocListener<LatestStatisticBloc, LatestStatisticState>(
            listener: (context, state) {
              if (state is LatestStatisticLoadedState ||
                  state is LatestStatisticEmptyState) {
                _onBlocRefreshCompleted();
              } else if (state is LatestStatisticFailedState) {
                _onBlocError();
              }
            },
          ),
          BlocListener<LatestCovidTestBloc, LatestCovidTestState>(
            listener: (context, state) {
              if (state is LatestCovidTestLoadedState ||
                  state is LatestCovidTestEmptyState) {
                _onBlocRefreshCompleted();
              } else if (state is LatestCovidTestFailedState) {
                _onBlocError();
              }
            },
          ),
        ],
        child: SmartRefresher(
          controller: _refreshController,
          onLoading: _onLoading,
          onRefresh: _onRefresh,
          header: WaterDropHeader(
            waterDropColor: context.picoColors.text.semantic.primary,
            failed: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PicoAsset.icon(
                  icon: PicoIcons.close,
                  size: 16.sp,
                  color: context.picoColors.icon.semantic.error,
                ),
                10.horizontalSpace,
                Text(
                  context.i10n.error.refresh,
                ),
              ],
            ),
            refresh: SpinKitFadingCircle(
              color: context.picoColors.icon.semantic.primary,
              size: 20.sp,
            ),
            completeDuration: 1.seconds,
            complete: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PicoAsset.icon(
                  icon: PicoIcons.check,
                  size: 16.sp,
                  color: context.picoColors.icon.semantic.success,
                ),
                10.horizontalSpace,
                Text(
                  context.i10n.success.refresh,
                ),
              ],
            ),
          ),
          child: ListView(
            children: [
              16.verticalSpace,
              BlocBuilder<BannerBloc, BannerState>(
                builder: (_, state) => AnimatedSwitcher(
                  duration: 300.milliseconds,
                  child: switch (state) {
                    BannerFailedState() => PicoErrorPlaceholder(
                        label: context.i10n.error.banner,
                        onRetry: () => context.read<BannerBloc>().add(
                              BannerEvent.load(),
                            ),
                      ),
                    BannerLoadedState(data: final data) =>
                      PicoBannerSlider<entity.Banner>(
                        data: data,
                        getImage: (item) => item.image,
                      ),
                    _ => const PicoBannerSliderSkeleton(),
                  },
                ),
              ),
              8.verticalSpace,
              Divider(
                color: context.picoColors.background.subtle,
                thickness: 8.h,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.i10n.data_case_label,
                          style: PicoTextStyle.headingXs(),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            context.i10n.buttons.more,
                          ),
                        ),
                      ],
                    ),
                    BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
                      builder: (context, state) => AnimatedSwitcher(
                        duration: 300.milliseconds,
                        child: switch (state) {
                          LatestStatisticLoadedState(data: final data) =>
                            PicoUpdatedAtPlaceholder(
                              key: const Key('updated-at-loaded'),
                              date: DateHelper.buildUpdatedAtText(
                                data.updatedAt.toLocal(),
                              ),
                            ),
                          LatestStatisticFailedState() =>
                            const PicoUpdatedAtPlaceholder(
                              key: Key('updated-at-failed'),
                              date: '-',
                            ),
                          _ => const PicoUpdatedAtPlaceholder(
                              key: Key('updated-at-loading'),
                              date: '12 December 2023 12.05 WITA',
                            ).sekeletonize(),
                        },
                      ),
                    ),
                    24.verticalSpace,
                    BlocBuilder<LatestStatisticBloc, LatestStatisticState>(
                      builder: (context, state) => AnimatedSwitcher(
                        duration: 300.milliseconds,
                        child: switch (state) {
                          LatestStatisticLoadedState(data: final data) =>
                            Column(
                              key: const Key('stats-loaded'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PicoTotalConfirmedCase(
                                  total: data.cumulative.positive,
                                  newCase: data.newCases.positive,
                                ),
                                24.verticalSpace,
                                StaggeredGrid.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.w,
                                  mainAxisSpacing: 8.h,
                                  children: [
                                    PicoCaseCard.treatment(
                                      total: data.cumulative.underTreatment,
                                      newCase: data.newCases.underTreatment,
                                    ),
                                    PicoCaseCard.cured(
                                      total: data.cumulative.recovered,
                                      newCase: data.newCases.recovered,
                                    ),
                                    PicoCaseCard.death(
                                      total: data.cumulative.deceased,
                                      newCase: data.newCases.deceased,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          LatestStatisticFailedState() => PicoErrorPlaceholder(
                              label: context.i10n.error.statistic,
                              onRetry: () =>
                                  context.read<LatestStatisticBloc>().add(
                                        LatestStatisticEvent.load(),
                                      ),
                            ),
                          LatestStatisticEmptyState() => Column(
                              key: const Key('stats-empty'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PicoTotalConfirmedCase(
                                  total: 0,
                                  newCase: 0,
                                ),
                                24.verticalSpace,
                                StaggeredGrid.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.w,
                                  mainAxisSpacing: 8.h,
                                  children: [
                                    PicoCaseCard.treatment(
                                      total: 0,
                                      newCase: 0,
                                    ),
                                    PicoCaseCard.cured(total: 0, newCase: 0),
                                    PicoCaseCard.death(total: 0, newCase: 0),
                                  ],
                                ),
                              ],
                            ),
                          _ => Column(
                              key: const Key('stats-loading'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PicoTotalConfirmedCase(
                                  total: 12500,
                                  newCase: 0,
                                ).sekeletonize(),
                                24.verticalSpace,
                                StaggeredGrid.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.w,
                                  mainAxisSpacing: 8.h,
                                  children: [
                                    PicoCaseCard.treatment(
                                      total: 24,
                                      newCase: 0,
                                    ).sekeletonize(),
                                    PicoCaseCard.cured(total: 24, newCase: 0)
                                        .sekeletonize(),
                                    PicoCaseCard.death(total: 24, newCase: 0)
                                        .sekeletonize(),
                                  ],
                                ),
                              ],
                            ),
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
                              onRetry: () =>
                                  context.read<LatestCovidTestBloc>().add(
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
                              total: 0,
                              onTap: () {},
                            ),
                          _ => const PicoTotalTestCardTile(
                              key: Key('total-test-loading'),
                              total: 12600,
                            ).sekeletonize(),
                        },
                      ),
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
