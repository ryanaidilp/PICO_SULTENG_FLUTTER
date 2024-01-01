import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoCardTile extends StatelessWidget {
  const PicoCardTile({
    required this.label,
    this.onTap,
    super.key,
  });

  final String label;
  final GestureTapCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(10.r),
        color: context.picoColors.background.subtle,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton.keep(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PicoTextStyle.labelLg(),
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
