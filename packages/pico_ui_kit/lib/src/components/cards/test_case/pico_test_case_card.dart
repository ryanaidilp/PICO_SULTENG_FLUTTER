import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/cards/test_case/enums/pico_test_status.dart';

class PicoTestCaseCard extends StatelessWidget {
  const PicoTestCaseCard._({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory PicoTestCaseCard.reactive({
    int count = 0,
    double percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.reactive,
      );

  factory PicoTestCaseCard.nonReactive({
    int count = 0,
    double percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.nonReactive,
      );

  factory PicoTestCaseCard.invalid({
    int count = 0,
    double percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.invalid,
      );

  factory PicoTestCaseCard.process({
    int count = 0,
    double percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.onProcess,
      );

  final int count;
  final double percentage;
  final PicoTestStatus status;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: context.picoColors.background.card.main,
          border: Border.all(
            color: context.picoColors.outline.neutral.main,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Skeleton.keep(
                child: Text(
                  status.label(context),
                  style: PicoTextStyle.body(),
                ),
              ),
              4.verticalSpace,
              Skeleton.replace(
                replacement: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 60.w,
                    height: 30.h,
                    color: context.picoColors.semantic.info.shade100,
                  ),
                ),
                child: Text(
                  NumberHelper.numberFormat(count),
                  style: PicoTextStyle.headingLg(
                    color: status.textColor(context),
                  ),
                ),
              ),
              4.verticalSpace,
              Text(
                '(${NumberHelper.percentageFormat(percentage)})',
                style: PicoTextStyle.body(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}
