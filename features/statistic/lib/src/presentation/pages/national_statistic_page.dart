import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/presentation/widgets/national_statistic_summary_section.dart';
import 'package:statistic/statistic.dart';

@RoutePage()
class NationalStatisticPage extends StatefulWidget {
  const NationalStatisticPage({super.key});

  @override
  State<NationalStatisticPage> createState() => _NationalStatisticPageState();
}

class _NationalStatisticPageState extends State<NationalStatisticPage> {
  late final RefreshController _refreshController;
  int _refreshCount = 0;
  int _errorCount = 1;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onLoading() {
    _refreshCount = 1;
    _errorCount = 0;
    context.read<LatestNationalStatisticCubit>().fetch();
  }

  void _onRefresh() {
    _refreshCount = 1;
    _errorCount = 0;
    _refreshController.requestRefresh();
    context.read<LatestNationalStatisticCubit>().fetch();
  }

  void _onBlocRefreshCompleted() {
    _refreshCount--;

    if (_refreshCount == 0 && _errorCount == 0) {
      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
    }
  }

  void _onBlocError() {
    _errorCount++;

    if (_errorCount > 0 && _refreshCount == 0) {
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<LatestNationalStatisticCubit,
              LatestNationalStatisticState>(
            listener: (context, state) {
              if (state is LatestNationalStatisticLoadedState) {
                _onBlocRefreshCompleted();
              } else if (state is LatestNationalStatisticFailedState) {
                _onBlocError();
              }
            },
          ),
        ],
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar.large(
              expandedHeight: 128.h,
              scrolledUnderElevation: 10.h,
              surfaceTintColor: context.picoColors.background.neutral.main,
              shadowColor:
                  context.picoColors.text.neutral.main.withOpacity(0.1),
              title: BlocBuilder<LatestNationalStatisticCubit,
                  LatestNationalStatisticState>(
                builder: (context, state) => AnimatedSwitcher(
                  duration: 300.milliseconds,
                  child: switch (state) {
                    LatestNationalStatisticLoadedState(data: final data) =>
                      PicoUpdatedAtPlaceholder(
                        key: const Key('updated-at-loaded'),
                        date: DateHelper.buildUpdatedAtText(
                          data.updatedAt.toLocal(),
                        ),
                        label: context.i10n.national_case_label,
                      ),
                    LatestNationalStatisticFailedState() =>
                      PicoUpdatedAtPlaceholder(
                        key: const Key('updated-at-failed'),
                        date: '-',
                        label: context.i10n.national_case_label,
                      ),
                    _ => PicoUpdatedAtPlaceholder(
                        key: const Key('updated-at-loading'),
                        date: '12 December 2023 12.05 WITA',
                        label: context.i10n.national_case_label,
                      ).sekeletonize(),
                  },
                ),
              ),
            ),
          ],
          body: SmartRefresher(
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
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const NationalStatisticSummarySection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
