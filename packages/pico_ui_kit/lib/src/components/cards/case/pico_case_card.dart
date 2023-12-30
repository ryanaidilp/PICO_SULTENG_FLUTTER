import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/cards/case/enums/pico_case_type.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoCaseCard extends StatelessWidget {
  const PicoCaseCard._({
    required PicoCaseType type,
    required this.total,
    required this.newCase,
  }) : _type = type;

  factory PicoCaseCard.treatment({
    required int total,
    required int newCase,
  }) =>
      PicoCaseCard._(
        type: PicoCaseType.treatment,
        total: total,
        newCase: newCase,
      );
  factory PicoCaseCard.cured({
    required int total,
    required int newCase,
  }) =>
      PicoCaseCard._(
        type: PicoCaseType.cured,
        total: total,
        newCase: newCase,
      );

  factory PicoCaseCard.death({
    required int total,
    required int newCase,
  }) =>
      PicoCaseCard._(
        type: PicoCaseType.death,
        newCase: newCase,
        total: total,
      );

  final PicoCaseType _type;

  final int total;
  final int newCase;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.picoColors.background.subtle,
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.all(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton.keep(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _type.data(context).bgColor,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        _type.data(context).iconData,
                        color: _type.data(context).iconColor,
                        size: 12.sp,
                      ),
                    ),
                  ),
                  4.horizontalSpace,
                  Expanded(
                    child: Text(
                      _type.data(context).label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PicoTextStyle.bodySm(
                        fontWeight: FontWeight.w600,
                        color: context.picoColors.text.main,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            Text(
              NumberHelper.numberFormat(total),
              style: PicoTextStyle.labelLg(
                color: context.picoColors.text.main,
              ),
            ),
            20.verticalSpace,
            Text(
              StringHelper.formatNewCase(newCase),
              style: PicoTextStyle.bodyXs(
                fontWeight: FontWeight.w700,
                color: context.picoColors.text.subtle,
              ),
            ),
            8.verticalSpace,
          ],
        ),
      );
}
