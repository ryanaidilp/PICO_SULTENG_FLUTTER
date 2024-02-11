import 'package:core/src/helpers/number_helper.dart';

class StringHelper {
  StringHelper._();

  static String formatNewCase(int cases) {
    final prefix = cases >= 0 ? '+' : '';
    final buffer = StringBuffer();
    final formattedNumber = NumberHelper.numberFormat(cases);
    buffer.writeAll(['(', prefix, formattedNumber, ')']);
    return buffer.toString();
  }
}
