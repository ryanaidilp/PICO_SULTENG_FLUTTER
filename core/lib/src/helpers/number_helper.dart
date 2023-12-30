import 'package:dependencies/dependencies.dart';
import 'package:i10n/i10n.dart';

class NumberHelper {
  NumberHelper._();
  static double calculatePercentage({
    required int value,
    required int total,
  }) =>
      value / total * 100;

  static String numberFormat(int number, {String? locale}) {
    final formatter = NumberFormat.decimalPattern(
      locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
    );

    return formatter.format(number);
  }

  static String percentageFormat(int number, {String? locale}) {
    final formatter = NumberFormat.percentPattern(
      locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
    );

    return formatter.format(number);
  }
}
