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
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.i10n.app_name,
            ),
            Text(
              context.i10n.app_desc,
              style: TextStyle(
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: PicoAsset.icon(
              icon: PicoIcons.menu,
              size: 14.sp,
              color: context.picoColors.text.strong,
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          16.verticalSpace,
          BlocBuilder<BannerBloc, BannerState>(
            builder: (_, state) => AnimatedSwitcher(
              duration: 300.milliseconds,
              child: switch (state) {
                BannerFailedState(failure: final failure) =>
                  PicoErrorPlaceholder(
                    label: failure.message,
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
        ],
      ),
    );
  }
}
