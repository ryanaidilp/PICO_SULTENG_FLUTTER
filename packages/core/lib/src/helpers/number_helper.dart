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
  }) {
    final formatter = compact
        ? NumberFormat.compact(
            explicitSign: showExplicitSign,
            locale: locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
          )
        : NumberFormat.decimalPattern(
            locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
          );

    return formatter.format(number);
  }

  static String percentageFormat(
    num number, {
    String? locale,
  }) {
    final formatter = NumberFormat.percentPattern(
      locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
    );

    return formatter.format(number);
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
}
