import 'dart:ui';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/cards/suspect/enums/pico_suspect_type.dart';

class PicoSuspectCard extends StatelessWidget {
  const PicoSuspectCard._({
    required this.type,
    required this.total,
    required this.newCase,
    required this.newFinishedCase,
    required this.activeCase,
    required this.finishedCase,
  });

  factory PicoSuspectCard.underSupervision({
    required int total,
    required int newCase,
    required int newFinishedCase,
    required int activeCase,
    required int finishedCase,
  }) =>
      PicoSuspectCard._(
        type: PicoSuspectType.underSupervision,
        total: total,
        newCase: newCase,
        newFinishedCase: newFinishedCase,
        activeCase: activeCase,
        finishedCase: finishedCase,
      );

  factory PicoSuspectCard.underObservation({
    required int total,
    required int newCase,
    required int newFinishedCase,
    required int activeCase,
    required int finishedCase,
  }) =>
      PicoSuspectCard._(
        type: PicoSuspectType.underObservation,
        total: total,
        newCase: newCase,
        newFinishedCase: newFinishedCase,
        activeCase: activeCase,
        finishedCase: finishedCase,
      );

  final int total;
  final int newCase;
  final int activeCase;
  final int finishedCase;
  final int newFinishedCase;
  final PicoSuspectType type;

  @override
  Widget build(BuildContext context) => PicoCard(
        padding: EdgeInsets.all(PCSpacing.s8.r),
        borderRadius: PCRadius.sm.r,
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
                  PCSpacing.s8.w.horizontalSpace,
                  InkWell(
                    customBorder: const CircleBorder(),
                    child: Tooltip(
                      decoration: BoxDecoration(
                        color: context.picoColors.background.neutral.white,
                        borderRadius: BorderRadius.circular(PCRadius.sm.r),
                        border: Border.all(
                          color: context.picoColors.outline.neutral.strong,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.picoColors.background.neutral.inverse
                                .withOpacity(0.1),
                            spreadRadius: 4.r,
                            blurRadius: 6.r,
                            offset: const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.symmetric(horizontal: PCSpacing.s16.w),
                      padding: EdgeInsets.all(PCSpacing.s8.r),
                      showDuration: 10.seconds,
                      richMessage: WidgetSpan(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 2,
                            sigmaY: 2,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.title(context),
                                style: PicoTextStyle.labelLg(),
                              ),
                              PCSpacing.s8.verticalSpace,
                              Text(type.description(context)),
                            ],
                          ),
                        ),
                      ),
                      triggerMode: TooltipTriggerMode.tap,
                      child: PicoAsset.icon(
                        icon: PicoIcons.questionCircle,
                        size: 14.sp,
                        color: context.picoColors.icon.neutral.subtle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PCSpacing.s4.h.verticalSpace,
            Row(
              children: [
                Skeleton.replace(
                  replacement: ClipRRect(
                    borderRadius: BorderRadius.circular(PCSpacing.s8.r),
                    child: Container(
                      width: 50.w,
                      height: 36.h,
                      color: context.picoColors.semantic.info.shade100,
                    ),
                  ),
                  child: Text(
                    NumberHelper.numberFormat(total),
                    style: PicoTextStyle.headingXl(),
                  ),
                ),
                PCSpacing.s4.w.horizontalSpace,
                Skeleton.replace(
                  replacement: ClipRRect(
                    borderRadius: BorderRadius.circular(PCSpacing.s8.r),
                    child: Container(
                      width: 24.w,
                      height: 12.h,
                      color: context.picoColors.semantic.info.shade100,
                    ),
                  ),
                  child: Text(
                    StringHelper.formatNewCase(newCase),
                    style: PicoTextStyle.bodySm(
                      fontWeight: FontWeight.w700,
                      color: context.picoColors.text.neutral.subtle,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              color: context.picoColors.background.neutral.strong,
            ),
            PCSpacing.s8.h.verticalSpace,
            StaggeredGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: PCSpacing.s16.w,
              children: [
                Column(
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
                    Row(
                      children: [
                        Skeleton.replace(
                          replacement: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: 50.w,
                              height: 36.h,
                              color: context.picoColors.semantic.info.shade100,
                            ),
                          ),
                          child: Text(
                            NumberHelper.numberFormat(activeCase),
                            style: PicoTextStyle.headingXl(),
                          ),
                        ),
                        PCSpacing.s4.w.horizontalSpace,
                        Skeleton.replace(
                          replacement: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: 24.w,
                              height: 12.h,
                              color: context.picoColors.semantic.info.shade100,
                            ),
                          ),
                          child: Text(
                            StringHelper.formatNewCase(
                              newCase - newFinishedCase,
                            ),
                            style: PicoTextStyle.bodySm(
                              fontWeight: FontWeight.w700,
                              color: context.picoColors.text.neutral.subtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    PCSpacing.s4.h.verticalSpace,
                  ],
                ),
                Column(
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
                    Row(
                      children: [
                        Skeleton.replace(
                          replacement: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: 50.w,
                              height: 36.h,
                              color: context.picoColors.semantic.info.shade100,
                            ),
                          ),
                          child: Text(
                            NumberHelper.numberFormat(finishedCase),
                            style: PicoTextStyle.headingXl(),
                          ),
                        ),
                        PCSpacing.s4.w.horizontalSpace,
                        Skeleton.replace(
                          replacement: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: 24.w,
                              height: 12.h,
                              color: context.picoColors.semantic.info.shade100,
                            ),
                          ),
                          child: Text(
                            StringHelper.formatNewCase(newFinishedCase),
                            style: PicoTextStyle.bodySm(
                              fontWeight: FontWeight.w700,
                              color: context.picoColors.text.neutral.subtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    PCSpacing.s4.h.verticalSpace,
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}
