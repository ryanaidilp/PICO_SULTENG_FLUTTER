import 'dart:math' as math;
import 'dart:ui';

import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// One series of a line chart. Null values are gaps, never 0.
class ChartSeries {
  /// Creates a series for a data role.
  const new({required this.state, required this.points, this.label});

  /// Role: colour, line form, mark and label.
  final PicoState state;

  /// Text label that replaces the role label (for example "Dosis 1"). The
  /// role still sets colour, line form and mark.
  final String? label;

  /// Points in any order. Dates are reduced to calendar dates by the chart.
  final List<(DateTime, num?)> points;
}

/// Maps dates and values to plot pixels.
class ChartScale {
  /// Creates a scale over [plot].
  const new({
    required this.plot,
    required this.start,
    required this.end,
    required this.yMin,
    required this.yMax,
  });

  /// Plot rectangle in pixels.
  final Rect plot;

  /// First date, inclusive.
  final DateTime start;

  /// Last date, inclusive.
  final DateTime end;

  /// Lowest value on the axis.
  final double yMin;

  /// Highest value on the axis.
  final double yMax;

  double get _spanDays => math.max(1, end.difference(start).inDays).toDouble();

  /// X pixel of [d].
  double x(DateTime d) =>
      plot.left + plot.width * (d.difference(start).inDays / _spanDays);

  /// Y pixel of [v].
  double y(num v) =>
      plot.bottom -
      plot.height * ((v - yMin) / (yMax - yMin == 0 ? 1 : yMax - yMin));

  /// The date nearest to pixel [dx], clamped to the range.
  DateTime dateAt(double dx) {
    final f = ((dx - plot.left) / plot.width).clamp(0.0, 1.0);
    return start.add(Duration(days: (f * _spanDays).round()));
  }
}

/// Splits a series into runs of consecutive non-null points inside the range
/// and decimates each run to at most four points per pixel column (first, min,
/// max, last), which keeps every peak. A null value ends the run, so a gap is
/// never bridged by a line.
List<List<Offset>> buildRuns(List<(DateTime, num?)> points, ChartScale scale) {
  final sorted = [...points]..sort((a, b) => a.$1.compareTo(b.$1));
  final runs = <List<Offset>>[];
  var current = <Offset>[];
  void flush() {
    if (current.isNotEmpty) runs.add(_decimate(current));
    current = <Offset>[];
  }

  for (final (d, v) in sorted) {
    if (d.isBefore(scale.start) || d.isAfter(scale.end)) continue;
    if (v == null) {
      flush();
      continue;
    }
    current.add(Offset(scale.x(d), scale.y(v)));
  }
  flush();
  return runs;
}

List<Offset> _decimate(List<Offset> pts) {
  if (pts.length <= 4) return pts;
  final out = <Offset>[];
  var i = 0;
  while (i < pts.length) {
    final col = pts[i].dx.floor();
    var j = i;
    var min = i;
    var max = i;
    while (j + 1 < pts.length && pts[j + 1].dx.floor() == col) {
      j++;
      if (pts[j].dy < pts[min].dy) min = j;
      if (pts[j].dy > pts[max].dy) max = j;
    }
    final keep = <int>{i, min, max, j}.toList()..sort();
    for (final k in keep) {
      out.add(pts[k]);
    }
    i = j + 1;
  }
  return out;
}

/// A "nice" axis: about [count] ticks on 1, 2, 2.5, 5 steps. Returns the
/// ticks, whose first and last are the axis ends.
List<double> niceTicks(double min, double maxIn, {int count = 4}) {
  final max = maxIn <= min ? min + 1 : maxIn;
  final raw = (max - min) / count;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  var step = mag;
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    step = m * mag;
    if (step >= raw) break;
  }
  final first = (min / step).floor() * step;
  final last = (max / step).ceil() * step;
  final ticks = <double>[];
  for (var v = first; v <= last + step / 2; v += step) {
    ticks.add(double.parse(v.toStringAsFixed(6)));
  }
  return ticks;
}

/// X tick dates: year starts for spans over two years, otherwise month starts
/// thinned to at most [maxTicks].
List<DateTime> xTicks(DateTime start, DateTime end, {int maxTicks = 6}) {
  final days = end.difference(start).inDays;
  final yearly = days > 730;
  final all = <DateTime>[];
  if (yearly) {
    for (
      var y = start.year + (start.month == 1 && start.day == 1 ? 0 : 1);
      y <= end.year;
      y++
    ) {
      all.add(DateTime(y));
    }
  } else {
    var d = DateTime(start.year, start.month + (start.day == 1 ? 0 : 1));
    while (!d.isAfter(end)) {
      all.add(d);
      d = DateTime(d.year, d.month + 1);
    }
  }
  if (all.length <= maxTicks) return all;
  final every = (all.length / maxTicks).ceil();
  return [for (var i = 0; i < all.length; i += every) all[i]];
}

/// Applies a dash pattern (on, off, on, off...) to [source].
Path dashPath(Path source, List<double> pattern) {
  final out = Path();
  for (final metric in source.computeMetrics()) {
    var d = 0.0;
    var i = 0;
    while (d < metric.length) {
      final len = pattern[i % pattern.length];
      if (i.isEven) {
        out.addPath(
          metric.extractPath(
            d,
            math.min(d + math.max(len, 0.01), metric.length),
          ),
          Offset.zero,
        );
      }
      d += len;
      i++;
    }
  }
  return out;
}
