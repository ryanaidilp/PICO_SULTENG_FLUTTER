import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class PicoTotalTestCardTile extends StatelessWidget {
  const PicoTotalTestCardTile({
    this.total = 0,
    super.key,
    this.onTap,
  });

  final int total;
  final GestureTapCallback? onTap;
  @override
  Widget build(BuildContext context) => PicoCard(
        borderRadius: PCRadius.sm.r,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(PCRadius.sm.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(PCSpacing.s8.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.keep(
                        child: Text(
                          context.translations.statistics.cardLabel.test.total,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PicoTextStyle.bodySm(
                            color: context.picoColors.text.neutral.subtle,
                          ),
                        ),
                      ),
                      Skeleton.replace(
                        replacement: ClipRRect(
                          borderRadius: BorderRadius.circular(PCSpacing.s8.r),
                          child: Container(
                            width: 80.w,
                            height: 32.h,
                            color: context.picoColors.semantic.info.shade100,
                          ),
                        ),
                        child: Text(
                          NumberHelper.numberFormat(total),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: PicoTextStyle.headingLg(),
                        ),
                      ),
                    ],
                  ),
                ),
                PCSpacing.s8.horizontalSpace,
                Skeleton.keep(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16.sp,
                    color: context.picoColors.icon.neutral.subtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
