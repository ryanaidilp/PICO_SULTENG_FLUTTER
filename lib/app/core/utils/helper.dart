import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String numberFormat(int number) {
  final formatter = NumberFormat.decimalPattern('id_ID');
  return formatter.format(number);
}

String percentageFormat(double number) {
  final formatter = NumberFormat.percentPattern('id_ID');
  return formatter.format(number);
}

String formatNewCase(int cases) {
  final prefix = cases >= 0 ? '+' : '';
  final StringBuffer buffer = StringBuffer();
  buffer.write('(');
  buffer.write(prefix);
  buffer.write(numberFormat(cases));
  buffer.write(' )');
  return buffer.toString();
}

double calculatePercentage(int value, int total) {
  return (value / total) * 100;
}

String buildUpdatedAtText(DateTime date, {String format = 'd MMM yyyy HH:mm'}) {
  final formattedDate = DateFormat(format).format(date);
  final timezone = date.timeZoneName;
  final buffer = StringBuffer()..writeAll([formattedDate, timezone], " ");
  return buffer.toString();
}

Future<void> showGetBottomSheet(Widget widgetToShow) async {
  Get.bottomSheet(
    widgetToShow,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
    ),
    ignoreSafeArea: false,
  );
}
