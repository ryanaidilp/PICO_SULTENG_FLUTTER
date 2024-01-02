import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoTotalTestCard extends StatelessWidget {
  const PicoTotalTestCard({
    this.total = 0,
    super.key,
  });

  final int total;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 1.sw,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.picoColors.background.subtle,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Padding(
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
          ),
        ),
      );
}
