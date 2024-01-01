import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/cards/suspect/enums/pico_suspect_type.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoSuspectCard extends StatelessWidget {
  const PicoSuspectCard._({
    required this.type,
    required this.total,
    required this.newCase,
    required this.newFinishedCase,
    required this.activeCase,
    required this.finishedCase,
    this.onTap,
  });

  factory PicoSuspectCard.underSupervision({
    required int total,
    required int newCase,
    required int newFinishedCase,
    required int activeCase,
    required int finishedCase,
    GestureTapCallback? onTap,
  }) =>
      PicoSuspectCard._(
        type: PicoSuspectType.underSupervision,
        total: total,
        newCase: newCase,
        newFinishedCase: newFinishedCase,
        activeCase: activeCase,
        finishedCase: finishedCase,
        onTap: onTap,
      );

  factory PicoSuspectCard.underObservation({
    required int total,
    required int newCase,
    required int newFinishedCase,
    required int activeCase,
    required int finishedCase,
    GestureTapCallback? onTap,
  }) =>
      PicoSuspectCard._(
        type: PicoSuspectType.underObservation,
        total: total,
        newCase: newCase,
        newFinishedCase: newFinishedCase,
        activeCase: activeCase,
        finishedCase: finishedCase,
        onTap: onTap,
      );

  final int total;
  final int newCase;
  final int activeCase;
  final int finishedCase;
  final int newFinishedCase;
  final PicoSuspectType type;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.picoColors.background.subtle,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.all(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton.keep(
              child: Row(
                children: [
                  Text(
                    type.label(context),
                    style: PicoTextStyle.body(),
                  ),
                  8.horizontalSpace,
                  InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: PicoAsset.icon(
                      icon: PicoIcons.questionCircle,
                      size: 14.sp,
                      color: context.picoColors.icon.neutral.subtle,
                    ),
                  ),
                ],
              ),
            ),
            24.verticalSpace,
            Row(
              children: [
                Text(
                  NumberHelper.numberFormat(total),
                  style: PicoTextStyle.headingXl(),
                ),
                4.horizontalSpace,
                Text(
                  StringHelper.formatNewCase(newCase),
                  style: PicoTextStyle.bodySm(
                    fontWeight: FontWeight.w700,
                    color: context.picoColors.text.neutral.subtle,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Divider(
              color: context.picoColors.background.strong,
            ),
            8.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Skeleton.keep(
                        child: Text(
                          context.i10n.card_case_label.active,
                          style: PicoTextStyle.labelSm(
                            color: context.picoColors.text.neutral.subtle,
                          ),
                        ),
                      ),
                      24.verticalSpace,
                      Row(
                        children: [
                          Text(
                            NumberHelper.numberFormat(activeCase),
                            style: PicoTextStyle.headingXl(),
                          ),
                          4.horizontalSpace,
                          Text(
                            StringHelper.formatNewCase(
                              newCase - newFinishedCase,
                            ),
                            style: PicoTextStyle.bodySm(
                              fontWeight: FontWeight.w700,
                              color: context.picoColors.text.neutral.subtle,
                            ),
                          ),
                        ],
                      ),
                      16.verticalSpace,
                    ],
                  ),
                ),
                0.2.sw.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Skeleton.keep(
                        child: Text(
                          context.i10n.card_case_label.finish,
                          style: PicoTextStyle.labelSm(
                            color: context.picoColors.text.neutral.subtle,
                          ),
                        ),
                      ),
                      24.verticalSpace,
                      Row(
                        children: [
                          Text(
                            NumberHelper.numberFormat(finishedCase),
                            style: PicoTextStyle.headingXl(),
                          ),
                          4.horizontalSpace,
                          Text(
                            StringHelper.formatNewCase(newFinishedCase),
                            style: PicoTextStyle.bodySm(
                              fontWeight: FontWeight.w700,
                              color: context.picoColors.text.neutral.subtle,
                            ),
                          ),
                        ],
                      ),
                      16.verticalSpace,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
