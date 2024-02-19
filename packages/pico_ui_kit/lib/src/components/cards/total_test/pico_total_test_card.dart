import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

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
            color: context.picoColors.background.card.main,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.picoColors.outline.neutral.main,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.keep(
                  child: Text(
                    context.i10n.test_done,
                    style: PicoTextStyle.bodySm(
                      color: context.picoColors.text.neutral.subtle,
                    ),
                  ),
                ),
                Skeleton.replace(
                  replacement: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      width: 80.w,
                      height: 32.h,
                      color: context.picoColors.semantic.info.shade100,
                    ),
                  ),
                  child: Text(
                    NumberHelper.numberFormat(total),
                    style: PicoTextStyle.headingLg(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
