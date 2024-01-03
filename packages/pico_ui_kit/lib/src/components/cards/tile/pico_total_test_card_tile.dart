import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoTotalTestCardTile extends StatelessWidget {
  const PicoTotalTestCardTile({
    this.total = 0,
    super.key,
    this.onTap,
  });

  final int total;
  final GestureTapCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
          side: BorderSide(
            color: context.picoColors.outline.neutral.main,
          ),
        ),
        color: context.picoColors.background.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(8.r),
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
                          context.i10n.test_label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: PicoTextStyle.headingLg(),
                        ),
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
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
