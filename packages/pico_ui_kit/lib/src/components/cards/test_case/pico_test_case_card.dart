import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_ui_kit/src/components/cards/test_case/enums/pico_test_status.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PicoTestCaseCard extends StatelessWidget {
  const PicoTestCaseCard._({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory PicoTestCaseCard.reactive({
    int count = 0,
    int percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.reactive,
      );

  factory PicoTestCaseCard.nonReactive({
    int count = 0,
    int percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.nonReactive,
      );

  factory PicoTestCaseCard.invalid({
    int count = 0,
    int percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.invalid,
      );

  factory PicoTestCaseCard.process({
    int count = 0,
    int percentage = 0,
  }) =>
      PicoTestCaseCard._(
        count: count,
        percentage: percentage,
        status: PicoTestStatus.onProcess,
      );

  final int count;
  final int percentage;
  final PicoTestStatus status;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: context.picoColors.background.subtle,
        ),
        padding: EdgeInsets.all(8.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            8.verticalSpace,
            Skeleton.keep(
              child: Text(
                status.label(context),
                style: PicoTextStyle.body(),
              ),
            ),
            24.verticalSpace,
            Text(
              NumberHelper.numberFormat(count),
              style: PicoTextStyle.headingLg(
                color: status.textColor(context),
              ),
            ),
            24.verticalSpace,
            Text(
              '(${NumberHelper.percentageFormat(percentage)})',
              style: PicoTextStyle.body(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            8.verticalSpace,
          ],
        ),
      );
}