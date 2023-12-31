import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoTotalTestCard extends StatelessWidget {
  const PicoTotalTestCard({
    required this.total,
    super.key,
  });

  final int total;

  @override
  Widget build(BuildContext context) => Container(
        width: 1.sw,
        decoration: BoxDecoration(
          color: context.picoColors.background.subtle,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.all(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            8.verticalSpace,
            Skeleton.keep(
              child: Text(
                context.i10n.test_done,
                style: PicoTextStyle.bodySm(
                  color: context.picoColors.text.neutral.subtle,
                ),
              ),
            ),
            24.verticalSpace,
            Text(
              NumberHelper.numberFormat(total),
              style: PicoTextStyle.headingLg(),
            ),
            10.verticalSpace,
          ],
        ),
      );
}
