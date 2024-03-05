import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/src/domain/enums/enums.dart';

class LineChartValueHeader extends StatelessWidget {
  const LineChartValueHeader({
    required this.newCase,
    required this.totalCase,
    required this.caseType,
    required this.updatedAt,
    super.key,
  });

  factory LineChartValueHeader.skeleton() => LineChartValueHeader(
        newCase: 120,
        totalCase: 72520,
        updatedAt: DateTime.now(),
        caseType: CaseType.underTreatment,
      );

  final int newCase;
  final int totalCase;
  final DateTime updatedAt;
  final CaseType caseType;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateHelper.dateWithDayFormat(
              updatedAt,
              format: 'dd MMM yyyy, HH:mm',
              includeTimeZone: true,
            ),
            style: PicoTextStyle.bodySm(
              color: context.picoColors.text.neutral.subtle,
            ),
          ),
          Skeleton.replace(
            replacement: RichText(
              text: TextSpan(
                text: NumberHelper.numberFormat(totalCase),
                style: PicoTextStyle.heading2xl(
                  color: context.picoColors.text.neutral.main,
                ),
              ),
            ),
            child: Row(
              children: [
                AnimatedDigitWidget(
                  value: totalCase,
                  duration: 500.milliseconds,
                  enableSeparator: true,
                  separateSymbol: context.thousandSeparator,
                  loop: false,
                  curve: Curves.ease,
                  textStyle: PicoTextStyle.heading2xl(
                    color: context.picoColors.text.neutral.main,
                  ),
                ),
                Text(
                  ' ${context.translations.statistics.caseSuffix(
                    n: totalCase,
                  )}',
                  style: PicoTextStyle.labelLg(),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Skeleton.shade(
                child: Builder(
                  builder: (_) {
                    Widget child = const SizedBox.shrink();

                    if (newCase != 0) {
                      final rotationFactor = newCase.isNegative ? 1.95 : 1.48;
                      child = AnimatedRotation(
                        turns: pi / rotationFactor,
                        duration: 300.milliseconds,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 16.sp,
                          color: _determineValueColor(
                            context,
                            newCase,
                            caseType,
                          ),
                        ),
                      );
                    }

                    return AnimatedSwitcher(
                      duration: 300.milliseconds,
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: 300.milliseconds,
                style: PicoTextStyle.bodySm(
                  fontWeight: FontWeight.w600,
                  color: _determineValueColor(
                    context,
                    newCase,
                    caseType,
                  ),
                ),
                child: Text(
                  _formatNewCase(
                    newCase,
                    totalCase,
                    suffix: context.translations.statistics.caseSuffix(
                      n: newCase.abs(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Color _determineValueColor(
    BuildContext context,
    int value,
    CaseType type,
  ) {
    final errorColor = context.picoColors.text.semantic.error;
    final successColor = context.picoColors.text.semantic.success;

    if (value > 0) {
      return type == CaseType.recovered ? successColor : errorColor;
    }

    if (value < 0) {
      return type == CaseType.recovered ? errorColor : successColor;
    }

    return context.picoColors.text.neutral.subtle;
  }

  String _formatNewCase(
    int newCase,
    int cumulativeCase, {
    required String suffix,
  }) {
    final buffer = StringBuffer();

    final initialValue = cumulativeCase - newCase;

    var percentIncrement = newCase / initialValue * 100;

    if (percentIncrement.isNaN) {
      percentIncrement = 0;
    }

    if (percentIncrement.isInfinite) {
      percentIncrement = 100;
    }

    if (percentIncrement > 0) {
      buffer.write('+');
    }

    buffer
      ..write(NumberHelper.percentageFormat(percentIncrement))
      ..write(' (');

    if (newCase > 0) {
      buffer.write('+');
    }

    buffer
      ..write(NumberHelper.numberFormat(newCase))
      ..write(' ')
      ..write(suffix)
      ..write(')');

    return buffer.toString();
  }
}
