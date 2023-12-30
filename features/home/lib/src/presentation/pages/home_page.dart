import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/src/domain/entities/banner.dart' as entity;
import 'package:home/src/presentation/blocs/banner/banner_bloc.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PicoAsset.images(
          image: PicoImages.pico,
          width: 24.w,
          height: 24.h,
          fit: BoxFit.fill,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            8.verticalSpace,
            Text(
              context.i10n.app_name,
              style: PicoTextStyle.headingLg(),
            ),
            20.verticalSpace,
            Text(
              context.i10n.app_desc,
              style: PicoTextStyle.bodyXs(),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: PicoAsset.icon(
              icon: PicoIcons.menu,
              size: 14.sp,
              color: context.picoColors.icon.neutral.strong,
            ),
          ),
        ],
      ),
      body: ListView(
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
                Row(
                  children: [
                    Text(
                      context.i10n.updated_at,
                      style: PicoTextStyle.bodySm(
                        color: context.picoColors.text.neutral.subtle,
                      ),
                    ),
                    4.horizontalSpace,
                    Text(
                      DateHelper.buildUpdatedAtText(
                        DateTime.now(),
                      ),
                      style: PicoTextStyle.bodySm(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                24.verticalSpace,
                const PicoTotalConfirmedCase(
                  total: 60799,
                  newCase: 29,
                ),
                24.verticalSpace,
                StaggeredGrid.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                  children: [
                    PicoCaseCard.treatment(total: 25, newCase: 1),
                    PicoCaseCard.cured(total: 59032, newCase: 1),
                    PicoCaseCard.death(total: 1722, newCase: 0),
                  ],
                ),
                16.verticalSpace,
                PicoTotalTestCardTile(
                  total: 12600,
                  onTap: () {},
                ),
                24.verticalSpace,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
