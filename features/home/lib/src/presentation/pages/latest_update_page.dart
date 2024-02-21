import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/home.dart';
import 'package:home/src/domain/domain.dart' as domain;

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
    context.read<LatestStatisticCubit>().fetch();
    context.read<LatestCovidTestCubit>().fetch();
  }

  void _onRefresh() {
    _refreshCounter = 3;
    _errorCounter = 0;
    _refreshController.requestRefresh();
    context.read<BannerBloc>().add(BannerEvent.load());
    context.read<LatestStatisticCubit>().fetch();
    context.read<LatestCovidTestCubit>().fetch();
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
          BlocListener<LatestStatisticCubit, LatestStatisticState>(
            listener: (context, state) {
              if (state is LatestStatisticLoadedState ||
                  state is LatestStatisticEmptyState) {
                _onBlocRefreshCompleted();
              } else if (state is LatestStatisticFailedState) {
                _onBlocError();
              }
            },
          ),
          BlocListener<LatestCovidTestCubit, LatestCovidTestState>(
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
                  context.translations.feedback.error.refresh,
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
                  context.translations.feedback.success.refresh,
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
                        label: context.translations.feedback.error.banner,
                        onRetry: () => context.read<BannerBloc>().add(
                              BannerEvent.load(),
                            ),
                      ),
                    BannerLoadedState(data: final data) =>
                      PicoBannerSlider<domain.Banner>(
                        data: data,
                        getImage: (item) => item.image,
                      ),
                    _ => const PicoBannerSliderSkeleton(),
                  },
                ),
              ),
              8.verticalSpace,
              Divider(
                color: context.picoColors.background.neutral.subtle,
                thickness: 8.h,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StatisticSummarySection(),
                    24.verticalSpace,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
