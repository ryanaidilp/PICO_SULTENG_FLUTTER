import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/home.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter.tabBar(
      routes: const [
        LatestUpdateRoute(),
        InformationRoute(),
      ],
      builder: (context, child, tabController) => Scaffold(
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
          bottom: ButtonsTabBar(
            backgroundColor: context.picoColors.semantic.primary,
            unselectedBackgroundColor: Colors.transparent,
            radius: 10.r,
            buttonMargin: EdgeInsets.all(8.r),
            borderWidth: 1.sp,
            borderColor: context.picoColors.semantic.primary,
            unselectedBorderColor: context.picoColors.text.neutral.subtle,
            contentPadding: EdgeInsets.only(
              left: 8.w,
              right: 8.w,
              top: 8.h,
            ),
            labelStyle: PicoTextStyle.body(
              color: Colors.white,
            ),
            unselectedLabelStyle: PicoTextStyle.body(
              color: context.picoColors.text.neutral.subtle,
            ),
            controller: tabController,
            onTap: (index) => tabController.animateTo(index),
            tabs: [
              Tab(
                text: context.i10n.tab_label.sulteng_today,
              ),
              Tab(
                text: context.i10n.tab_label.covid_info,
              ),
            ],
          ),
        ),
        body: child,
      ),
    );
  }
}
