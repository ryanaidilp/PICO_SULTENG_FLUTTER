import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/chart_base.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/chart_geometry.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Rt over time: the estimate in `rt` ink, a hatched band between the lower
/// and upper bound, a dashed threshold at 1.0 labelled "Rt = 1", gaps where Rt
/// is null (never a line through them) and an open ring at the scrub point.
class PicoRtChart extends StatelessWidget {
  /// Creates the chart. A null `Rt` is "not computed".
  const new({
    required this.points,
    required this.range,
    this.semanticsSummary,
    this.onScrub,
    this.height = 220,
    super.key,
  });

  /// One entry per date. Null Rt leaves a gap.
  final List<(DateTime, Rt?)> points;

  /// Visible range, inclusive.
  final DateTimeRange range;

  /// Screen reader summary override.
  final String? semanticsSummary;

  /// Called with the selected date while scrubbing.
  final ValueChanged<DateTime>? onScrub;

  /// Plot height.
  final double height;

  @override
  Widget build(BuildContext context) => PicoChartBase(
    range: range,
    height: height,
    semanticsSummary: semanticsSummary,
    onScrub: onScrub,
    series: [
      ChartSeries(
        state: PicoState.rt,
        points: [for (final p in points) (p.$1, p.$2?.value)],
      ),
    ],
    band: ChartBand(
      lower: [for (final p in points) (p.$1, p.$2?.lower)],
      upper: [for (final p in points) (p.$1, p.$2?.upper)],
    ),
    threshold: 1,
    thresholdLabel: 'Rt = 1',
    formatValue: (t, v) => t.decimal(v),
  );
}
