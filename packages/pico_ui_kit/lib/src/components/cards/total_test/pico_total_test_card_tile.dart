import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoTotalTestCardTile extends StatelessWidget {
  const PicoTotalTestCardTile({
    required this.total,
    super.key,
    this.onTap,
  });

  final int total;
  final GestureTapCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(10.r),
        color: context.picoColors.background.subtle,
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
                      4.verticalSpace,
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
                      24.verticalSpace,
                      Text(
                        NumberHelper.numberFormat(total),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: PicoTextStyle.headingLg(),
                      ),
                      16.verticalSpace,
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
