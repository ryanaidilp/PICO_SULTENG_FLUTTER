import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';

enum DataTimeFrame {
  oneMonth,
  threeMonth,
  sixMonth,
  all;

  factory DataTimeFrame.fromValue(String value) => values.firstWhere(
        (element) => element.name == value,
        orElse: () => DataTimeFrame.all,
      );

  String label(BuildContext context) => switch (this) {
        oneMonth => context
            .translations.chart.line_chart.filter_label.timeframe.one_month,
        threeMonth => context
            .translations.chart.line_chart.filter_label.timeframe.three_month,
        sixMonth => context
            .translations.chart.line_chart.filter_label.timeframe.six_month,
        _ => context.translations.chart.line_chart.filter_label.all,
      };

  int get offset => switch (this) {
        oneMonth => 30,
        threeMonth => 90,
        sixMonth => 180,
        _ => 0,
      };
}
