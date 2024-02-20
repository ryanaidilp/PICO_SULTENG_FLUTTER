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
        oneMonth => context.translations.statistics.timeframe.oneMonth,
        threeMonth => context.translations.statistics.timeframe.threeMonth,
        sixMonth => context.translations.statistics.timeframe.sixMonth,
        _ => context.translations.statistics.timeframe.all,
      };

  int get offset => switch (this) {
        oneMonth => 30,
        threeMonth => 90,
        sixMonth => 180,
        _ => 0,
      };
}
