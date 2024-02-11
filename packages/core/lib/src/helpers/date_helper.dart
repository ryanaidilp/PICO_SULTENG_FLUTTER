import 'package:dependencies/dependencies.dart';
import 'package:i10n/i10n.dart';

class DateHelper {
  DateHelper._();

  static String buildUpdatedAtText(
    DateTime date, {
    String format = 'd MMM yyyy HH:mm',
    String? locale,
  }) {
    final formattedDate = DateFormat(
      format,
      locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
    ).format(date);
    final timezone = date.timeZoneName;
    final buffer = StringBuffer()..writeAll([formattedDate, timezone], ' ');
    return buffer.toString();
  }

  static String dateWithDayFormat(
    DateTime date, {
    String format = 'EEEE, dd MMMM yyyy',
    bool includeTimeZone = false,
    String? locale,
  }) {
    final formattedDate = DateFormat(
      format,
      locale ?? AppLocaleUtils.findDeviceLocale().languageCode,
    ).format(date);
    final timezone = date.timeZoneName;
    final buffer = StringBuffer()..writeAll([formattedDate, timezone], ' ');
    return includeTimeZone ? buffer.toString() : formattedDate;
  }
}
