import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/chart_base.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/chart_geometry.dart';

/// Line chart of 1 to 4 case series over a date range (ADR-0107).
///
/// Each series keeps its role form: solid (positive), dotted (recovered),
/// doubled (deceased), dashed (active). Marks show at the scrub point only.
/// The chart is one semantic node with a summary, can be moved with arrow keys
/// or the accessibility increase and decrease actions, and has a "Lihat
/// sebagai tabel" alternative. The draw-on (240 ms) is off with reduced motion.
class PicoLineChart extends StatelessWidget {
  /// Creates the chart. [semanticsSummary] overrides the generated summary
  /// (series names, date range and the peak).
  const new({
    required this.series,
    required this.range,
    this.yLabel,
    this.semanticsSummary,
    this.onScrub,
    this.height = 220,
    this.valueHeader = false,
    this.showChange = false,
    super.key,
  });

  /// Series, at most four.
  final List<ChartSeries> series;

  /// Visible range, inclusive.
  final DateTimeRange range;

  /// Axis caption.
  final String? yLabel;

  /// Screen reader summary override.
  final String? semanticsSummary;

  /// Called with the selected date while scrubbing.
  final ValueChanged<DateTime>? onScrub;

  /// Plot height.
  final double height;

  /// Shows the old value header above a one-series chart: the date, the value
  /// counting up in 500 ms, following the scrub.
  final bool valueHeader;

  /// With [valueHeader]: also the change from the day before (cumulative data
  /// only, where it is the new cases).
  final bool showChange;

  @override
  Widget build(BuildContext context) => PicoChartBase(
    series: series,
    range: range,
    yLabel: yLabel,
    semanticsSummary: semanticsSummary,
    onScrub: onScrub,
    height: height,
    valueHeader: valueHeader,
    showChange: showChange,
    formatValue: (t, v) => t.number(v.round()),
  );
}
