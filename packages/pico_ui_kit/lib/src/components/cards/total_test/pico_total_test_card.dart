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
  Widget build(BuildContext context) => PicoCard(
        width: 1.sw,
        padding: EdgeInsets.all(PCSpacing.s8.r),
        borderRadius: PCRadius.sm.r,
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
                borderRadius: BorderRadius.circular(PCRadius.sm.r),
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
      );
}
