import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

enum CaseType {
  positive,
  recovered,
  deceased,
  underTreatment;

  factory CaseType.fromValue(String value) => CaseType.values.firstWhere(
        (element) => element.name == value,
        orElse: () => CaseType.underTreatment,
      );

  String label(BuildContext context) => switch (this) {
        positive => context.translations.chart.line_chart.filter_label.positive,
        recovered =>
          context.translations.chart.line_chart.filter_label.recovered,
        deceased => context.translations.chart.line_chart.filter_label.deceased,
        underTreatment =>
          context.translations.chart.line_chart.filter_label.active,
      };

  Color color(BuildContext context) => switch (this) {
        positive => context.picoColors.icon.semantic.info,
        recovered => context.picoColors.icon.semantic.success,
        deceased => context.picoColors.icon.semantic.error,
        underTreatment => context.picoColors.icon.semantic.warning,
      };

  List<double> filterData(
    List<Statistic> data, {
    required bool showCumulative,
  }) =>
      switch (this) {
        positive => data
            .map(
              (e) => showCumulative
                  ? e.cumulative.positive.toDouble()
                  : e.newCases.positive.toDouble(),
            )
            .toList(),
        recovered => data
            .map(
              (e) => showCumulative
                  ? e.cumulative.recovered.toDouble()
                  : e.newCases.recovered.toDouble(),
            )
            .toList(),
        deceased => data
            .map(
              (e) => showCumulative
                  ? e.cumulative.deceased.toDouble()
                  : e.newCases.deceased.toDouble(),
            )
            .toList(),
        underTreatment => data
            .map(
              (e) => showCumulative
                  ? e.cumulative.underTreatment.toDouble()
                  : e.newCases.underTreatment.toDouble(),
            )
            .toList(),
      };

  int getCumulative(Statistic statistic) => switch (this) {
        positive => statistic.cumulative.positive,
        recovered => statistic.cumulative.recovered,
        deceased => statistic.cumulative.deceased,
        underTreatment => statistic.cumulative.underTreatment,
      };

  int getNewCases(Statistic statistic) => switch (this) {
        positive => statistic.newCases.positive,
        recovered => statistic.newCases.recovered,
        deceased => statistic.newCases.deceased,
        underTreatment => statistic.newCases.underTreatment,
      };

  Widget icon(BuildContext context) => switch (this) {
        underTreatment => PicoAsset.icon(
            icon: PicoIcons.hospitalBedOutline,
            color: context.picoColors.icon.semantic.warning,
          ),
        deceased => PicoAsset.icon(
            icon: PicoIcons.cemetery,
            color: context.picoColors.icon.semantic.error,
          ),
        recovered => PicoAsset.icon(
            icon: PicoIcons.selfIsolation,
            color: context.picoColors.icon.semantic.success,
          ),
        positive => PicoAsset.icon(
            icon: PicoIcons.virus,
            color: context.picoColors.icon.semantic.info,
          ),
      };
}
