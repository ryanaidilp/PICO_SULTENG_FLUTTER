import 'dart:math';

import 'package:core/core.dart';
import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:dependencies/dependencies.dart';
import 'package:i10n/i10n.dart';

class NumberHelper {
  NumberHelper._();
  static double calculatePercentage({
    required num value,
    required num total,
  }) =>
      value / total * 100;

  static String numberFormat(
    num number, {
    String? locale,
    bool compact = false,
    bool showExplicitSign = false,
    int decimals = 2,
    bool showSign = false,
  }) {
    final formatter = compact
        ? NumberFormat.compact(
            explicitSign: showExplicitSign,
            locale: locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
          )
        : NumberFormat.decimalPattern(
            locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
          );
    final preciseValue =
        number.toStringAsPrecision(number.toDouble().precision);
    final customDecimalValue = number.toStringAsFixed(decimals);
    final preciseDouble = double.parse(preciseValue);
    final customDecimalDouble = double.parse(customDecimalValue);
    final isStartWithZero = number.abs().toString().startsWith('0');

    final decimal = Decimal.parse(
      preciseDouble == customDecimalDouble || !isStartWithZero
          ? customDecimalValue
          : preciseValue,
    );

    return formatter.format(
      DecimalIntl(decimal),
    );
  }

  static String percentageFormat(
    num number, {
    String? locale,
    bool compact = false,
    bool showExplicitSign = false,
    int decimals = 2,
    bool showSign = false,
  }) {
    final formatter = compact
        ? NumberFormat.compact(
            explicitSign: showExplicitSign,
            locale: locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
          )
        : NumberFormat.decimalPattern(
            locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
          );

    final preciseValue = number.toStringAsFixed(number.toDouble().precision);
    final customDecimalValue = number.toStringAsFixed(decimals);
    final preciseDouble = double.parse(preciseValue);
    final customDecimalDouble = double.parse(customDecimalValue);
    final isStartWithZero = number.abs().toString().startsWith('0');

    final decimal = Decimal.parse(
      preciseDouble == customDecimalDouble || !isStartWithZero
          ? customDecimalValue
          : preciseValue,
    );

    return '${formatter.format(
      DecimalIntl(decimal),
    )}%';
  }

  static int calculateStep({
    required int maxValue,
    int minValue = 0,
    int numberOfSteps = 5,
  }) {
    if (numberOfSteps <= 0) {
      throw ArgumentError('Number of steps must be greater than 0');
    }

    // Calculate the step size
    final range = maxValue - minValue;
    return (range / numberOfSteps).ceil();
  }

  static int ceilToNearest(int number) {
    if (number < 100) {
      // If the number is less than 100, return it as is.
      return number;
    } else if (number < 1000) {
      // If the number is between 100 and 999, ceil to the nearest hundred.
      return ((number + 99) ~/ 100) * 100;
    } else {
      // If the number is 1000 or more, ceil to the nearest thousand.
      return ((number + 999) ~/ 1000) * 1000;
    }
  }

  static double logBase({
    required num value,
    required num base,
    AppLocale? locale,
  }) {
    final decimalValue = Decimal.parse(value.toString());
    final decimalBase = Decimal.parse(base.toString());

    final logDecimal = log(
          decimalValue.toDouble(),
        ) /
        log(
          decimalBase.toDouble(),
        );

    return Decimal.parse(
      logDecimal.toStringAsPrecision(logDecimal.precision),
    ).toDouble();
  }
}
