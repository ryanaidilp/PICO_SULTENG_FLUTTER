import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart' show PicoLineChart, PicoRtChart;
import 'package:pico_ui_kit/src/components/atoms/atoms.dart'
    show PicoLineChart, PicoRtChart;
import 'package:pico_ui_kit/src/components/atoms/charts/chart_geometry.dart';
import 'package:pico_ui_kit/src/components/atoms/charts/charts.dart'
    show PicoLineChart, PicoRtChart;
import 'package:pico_ui_kit/src/components/atoms/charts/pico_line_chart.dart'
    show PicoLineChart;
import 'package:pico_ui_kit/src/components/atoms/charts/pico_rt_chart.dart'
    show PicoRtChart;
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_mark_legend.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/pico_marks.dart';
import 'package:pico_ui_kit/src/components/atoms/data_viz/weave_shader_cache.dart';
import 'package:pico_ui_kit/src/components/components.dart'
    show PicoLineChart, PicoRtChart;
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Lower and upper bounds drawn as a hatched band (Rt interval).
class ChartBand {
  /// Creates a band. Both lists use the same dates.
  const new({required this.lower, required this.upper});

  /// Lower bound per date.
  final List<(DateTime, num?)> lower;

  /// Upper bound per date.
  final List<(DateTime, num?)> upper;
}

/// Shared chart body for [PicoLineChart] and [PicoRtChart]: axes, series with
/// line forms, optional band and threshold, scrub readout, semantics summary
/// and the table alternative. Not part of the public API.
class PicoChartBase extends StatefulWidget {
  /// Creates the chart.
  const new({
    required this.series,
    required this.range,
    required this.formatValue,
    this.band,
    this.threshold,
    this.thresholdLabel,
    this.yLabel,
    this.semanticsSummary,
    this.onScrub,
    this.height = 220,
    this.yFloorZero = true,
    super.key,
  });

  /// Series to draw (1 to 4).
  final List<ChartSeries> series;

  /// Visible date range, inclusive.
  final DateTimeRange range;

  /// Formats a value for readout, table and summary.
  final String Function(PicoKitText t, double v) formatValue;

  /// Optional hatched band (Rt interval).
  final ChartBand? band;

  /// Optional horizontal reference line (Rt = 1).
  final double? threshold;

  /// Label of the threshold.
  final String? thresholdLabel;

  /// Axis caption above the y axis.
  final String? yLabel;

  /// Replaces the generated screen reader summary.
  final String? semanticsSummary;

  /// Called with the selected date while scrubbing.
  final ValueChanged<DateTime>? onScrub;

  /// Plot height.
  final double height;

  /// Keep zero on the axis (false lets a negative minimum extend it).
  final bool yFloorZero;

  @override
  State<PicoChartBase> createState() => _PicoChartBaseState();
}

class _PicoChartBaseState extends State<PicoChartBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  DateTime? _scrub;
  bool _table = false;
  final FocusNode _focus = FocusNode();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = Theme.of(context).brightness;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    WeaveShaderCache.instance.load(PicoState.rt, b, dpr).then((_) {
      if (mounted) setState(() {});
    });
    if (!_started) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _draw.value = 1;
      } else {
        _draw.forward();
      }
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _focus.dispose();
    super.dispose();
  }

  DateTime get _start => dateOnly(widget.range.start);
  DateTime get _end => dateOnly(widget.range.end);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _setScrub(DateTime d) {
    final c = d.isBefore(_start) ? _start : (d.isAfter(_end) ? _end : d);
    if (_scrub == c) return;
    setState(() => _scrub = c);
    widget.onScrub?.call(c);
  }

  void _step(int days) => _setScrub((_scrub ?? _end).add(Duration(days: days)));

  Iterable<(DateTime, num?)> _inRange(ChartSeries s) => s.points
      .map((p) => (dateOnly(p.$1), p.$2))
      .where((p) => !p.$1.isBefore(_start) && !p.$1.isAfter(_end));

  ({double min, double max}) _yBounds() {
    var lo = widget.yFloorZero ? 0.0 : double.infinity;
    var hi = double.negativeInfinity;
    void take(num? v) {
      if (v == null) return;
      lo = math.min(lo, v.toDouble());
      hi = math.max(hi, v.toDouble());
    }

    for (final s in widget.series) {
      for (final p in _inRange(s)) {
        take(p.$2);
      }
    }
    final band = widget.band;
    if (band != null) {
      for (final p in band.upper) {
        if (!p.$1.isBefore(_start) && !p.$1.isAfter(_end)) take(p.$2);
      }
    }
    if (widget.threshold != null) take(widget.threshold);
    if (hi == double.negativeInfinity) return (min: 0, max: 1);
    if (!lo.isFinite) lo = 0;
    return (min: lo, max: hi);
  }

  (DateTime, double)? _peak() {
    (DateTime, double)? best;
    for (final s in widget.series) {
      for (final p in _inRange(s)) {
        final v = p.$2?.toDouble();
        if (v != null && (best == null || v > best.$2)) best = (p.$1, v);
      }
    }
    return best;
  }

  String _summary(PicoKitText t) {
    final custom = widget.semanticsSummary;
    if (custom != null) return custom;
    final names = widget.series.map((s) => t.stateLabel(s.state)).join(', ');
    final peak = _peak();
    final parts = [names, t.range(_start, _end)];
    if (peak != null)
      parts.add(t.peak(widget.formatValue(t, peak.$2), peak.$1));
    return parts.join(', ');
  }

  double? _valueOn(ChartSeries s, DateTime d) {
    for (final p in s.points) {
      if (dateOnly(p.$1) == d) return p.$2?.toDouble();
    }
    return null;
  }

  Widget _readout(PicoKitText t) {
    final d = _scrub;
    final text = context.typography.label.caption.copyWith(
      color: context.colors.foreground.main,
    );
    if (d == null) return SizedBox(height: text.fontSize! * 1.6);
    final states = context.picoStates;
    return Semantics(
      liveRegion: true,
      child: Wrap(
        spacing: 12,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(t.date(d), style: text.copyWith(fontWeight: FontWeight.w600)),
          for (final s in widget.series)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PicoMarkView(
                  mark: s.state.mark,
                  color: states.of(s.state),
                  size: 11,
                ),
                const SizedBox(width: 4),
                Text(
                  '${t.stateLabel(s.state)} ${_valueOn(s, d) == null ? t.noData : widget.formatValue(t, _valueOn(s, d)!)}',
                  style: text,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableView(PicoKitText t) {
    final dates = <DateTime>{
      for (final s in widget.series)
        for (final p in _inRange(s)) p.$1,
    }.toList()..sort();
    final style = context.typography.body.small.copyWith(
      color: context.colors.foreground.main,
    );
    return SizedBox(
      height: 300,
      child: Semantics(
        label: _summary(t),
        child: ListView.builder(
          itemCount: dates.length,
          itemExtent: 40,
          itemBuilder: (context, i) {
            final d = dates[dates.length - 1 - i];
            final cells = [
              for (final s in widget.series)
                '${t.stateLabel(s.state)} ${_valueOn(s, d) == null ? t.noData : widget.formatValue(t, _valueOn(s, d)!)}',
            ];
            return Semantics(
              container: true,
              label: '${t.date(d)}, ${cells.join(', ')}',
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${t.date(d)}   ${cells.join('   ')}',
                    style: style,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final large = scale >= 1.5;
    final readout = _readout(t);
    final legend = PicoMarkLegend(
      states: [for (final s in widget.series) s.state],
    );
    final toggle = Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () => setState(() => _table = !_table),
        child: Text(_table ? t.viewAsChart : t.viewAsTable),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_table && !large) readout,
        if (_table) _tableView(t) else _plot(t),
        if (!_table && large) readout,
        const SizedBox(height: 8),
        legend,
        toggle,
      ],
    );
  }

  Widget _plot(PicoKitText t) {
    final b = Theme.of(context).brightness;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final captionStyle = context.typography.label.caption.copyWith(
      color: context.colors.foreground.subtle,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final scale = scaler.scale(14) / 14;
    final bounds = _yBounds();
    final ticks = niceTicks(bounds.min, bounds.max);
    final yMin = ticks.first;
    final yMax = ticks.last;
    final labelW = ticks
        .map(
          (v) => (TextPainter(
            text: TextSpan(text: t.compact(v), style: captionStyle),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout()).width,
        )
        .fold<double>(0, math.max);
    final labelH = (TextPainter(
      text: TextSpan(text: 'Jan', style: captionStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout()).height;
    final topPad = widget.yLabel == null ? 8.0 : labelH + 10;
    return Semantics(
      container: true,
      label: _summary(t),
      value: _scrub == null ? null : t.date(_scrub!),
      increasedValue: _scrub == null
          ? null
          : t.date(_scrub!.add(const Duration(days: 1))),
      decreasedValue: _scrub == null
          ? null
          : t.date(_scrub!.subtract(const Duration(days: 1))),
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: ExcludeSemantics(
        child: Focus(
          focusNode: _focus,
          onKeyEvent: (node, e) {
            if (e is KeyUpEvent) return KeyEventResult.ignored;
            if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _step(HardwareKeyboard.instance.isShiftPressed ? -7 : -1);
              return KeyEventResult.handled;
            }
            if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
              _step(HardwareKeyboard.instance.isShiftPressed ? 7 : 1);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, widget.height + labelH + topPad);
              final plot = Rect.fromLTRB(
                labelW + 8,
                topPad,
                size.width - 8,
                size.height - labelH - 8,
              );
              final cs = ChartScale(
                plot: plot,
                start: _start,
                end: _end,
                yMin: yMin,
                yMax: yMax,
              );
              final colors = context.picoStates;
              final painter = ChartPainter(
                scale: cs,
                ticks: ticks,
                xTicks: xTicks(
                  _start,
                  _end,
                  maxTicks: math.max(2, (plot.width / (60 * scale)).floor()),
                ),
                series: [
                  for (final s in widget.series)
                    ChartLayer(
                      state: s.state,
                      color: colors.of(s.state),
                      runs: buildRuns([for (final p in _inRange(s)) p], cs),
                    ),
                ],
                band: widget.band == null ? null : bandRuns(widget.band!, cs),
                bandShader: WeaveShaderCache.instance.shaderIfReady(
                  PicoState.rt,
                  b,
                  dpr,
                ),
                bandColor: colors.rt,
                threshold: widget.threshold == null
                    ? null
                    : cs.y(widget.threshold!),
                thresholdLabel: widget.thresholdLabel,
                scrub: _scrub,
                scrubValues: _scrub == null
                    ? const []
                    : [for (final s in widget.series) _valueOn(s, _scrub!)],
                gridColor: context.colors.outline.subtle,
                axisColor: context.colors.outline.main,
                textStyle: captionStyle,
                textScaler: scaler,
                yLabel: widget.yLabel,
                formatTick: t.compact,
                monthLabel: (d) => t.axisDate(
                  d,
                  yearOnly: _end.difference(_start).inDays > 730,
                ),
                progress: _draw,
                inkColor: context.colors.foreground.main,
              );
              return GestureDetector(
                key: const ValueKey('pico-chart-plot'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  _focus.requestFocus();
                  _setScrub(cs.dateAt(d.localPosition.dx));
                },
                onHorizontalDragUpdate: (d) =>
                    _setScrub(cs.dateAt(d.localPosition.dx)),
                child: CustomPaint(size: size, painter: painter),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One drawn series.
class ChartLayer {
  /// Creates a layer.
  const new({required this.state, required this.color, required this.runs});

  /// Role.
  final PicoState state;

  /// Line colour.
  final Color color;

  /// Decimated runs.
  final List<List<Offset>> runs;
}

/// Band polygons: one closed polygon per run where both bounds exist.
List<Path> bandRuns(ChartBand band, ChartScale s) {
  final lo = {
    for (final p in band.lower) DateTime(p.$1.year, p.$1.month, p.$1.day): p.$2,
  };
  final paths = <Path>[];
  final dates = [
    for (final p in band.upper) DateTime(p.$1.year, p.$1.month, p.$1.day),
  ]..sort();
  final up = {
    for (final p in band.upper) DateTime(p.$1.year, p.$1.month, p.$1.day): p.$2,
  };
  var run = <(DateTime, num, num)>[];
  void flush() {
    if (run.length >= 2) {
      final path = Path()..moveTo(s.x(run.first.$1), s.y(run.first.$3));
      for (final r in run.skip(1)) {
        path.lineTo(s.x(r.$1), s.y(r.$3));
      }
      for (final r in run.reversed) {
        path.lineTo(s.x(r.$1), s.y(r.$2));
      }
      paths.add(path..close());
    }
    run = [];
  }

  for (final d in dates) {
    if (d.isBefore(s.start) || d.isAfter(s.end)) continue;
    final u = up[d];
    final l = lo[d];
    if (u == null || l == null) {
      flush();
    } else {
      run.add((d, l, u));
    }
  }
  flush();
  return paths;
}

/// Paints the chart. Public for the paint-cost test.
class ChartPainter extends CustomPainter {
  /// Creates a painter.
  new({
    required this.scale,
    required this.ticks,
    required this.xTicks,
    required this.series,
    required this.band,
    required this.bandShader,
    required this.bandColor,
    required this.threshold,
    required this.thresholdLabel,
    required this.scrub,
    required this.scrubValues,
    required this.gridColor,
    required this.axisColor,
    required this.textStyle,
    required this.textScaler,
    required this.yLabel,
    required this.formatTick,
    required this.monthLabel,
    required this.progress,
    required this.inkColor,
  }) : super(repaint: progress);

  /// Pixel mapping.
  final ChartScale scale;

  /// Y tick values.
  final List<double> ticks;

  /// X tick dates.
  final List<DateTime> xTicks;

  /// Layers.
  final List<ChartLayer> series;

  /// Band polygons.
  final List<Path>? band;

  /// Weave shader for the band, if rasterised.
  final ui.Shader? bandShader;

  /// Fallback colour for the band.
  final Color bandColor;

  /// Y pixel of the threshold.
  final double? threshold;

  /// Threshold label.
  final String? thresholdLabel;

  /// Scrub date.
  final DateTime? scrub;

  /// Value of each series at the scrub date.
  final List<double?> scrubValues;

  /// Grid colour.
  final Color gridColor;

  /// Axis colour.
  final Color axisColor;

  /// Label style.
  final TextStyle textStyle;

  /// Text scaler.
  final TextScaler textScaler;

  /// Axis caption.
  final String? yLabel;

  /// Y tick formatter.
  final String Function(num) formatTick;

  /// X tick formatter.
  final String Function(DateTime) monthLabel;

  /// Draw-on progress 0..1.
  final Animation<double> progress;

  /// Ink colour for the scrub rule.
  final Color inkColor;

  void _text(
    Canvas c,
    String s,
    Offset at, {
    bool right = false,
    bool centre = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final dx = right
        ? at.dx - tp.width
        : (centre ? at.dx - tp.width / 2 : at.dx);
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = scale.plot;
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final v in ticks) {
      final y = scale.y(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, formatTick(v), Offset(plot.left - 6, y), right: true);
    }
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
    for (final d in xTicks) {
      final x = scale.x(d);
      canvas.drawLine(
        Offset(x, plot.bottom),
        Offset(x, plot.bottom + 4),
        Paint()..color = axisColor,
      );
      _text(
        canvas,
        monthLabel(d),
        Offset(x, plot.bottom + 4 + textStyle.fontSize! * .9),
        centre: true,
      );
    }
    if (yLabel != null)
      _text(
        canvas,
        yLabel!,
        Offset(plot.left - 6, plot.top - textStyle.fontSize! * 1.1),
      );

    final th = threshold;
    if (th != null) {
      final p = Path()
        ..moveTo(plot.left, th)
        ..lineTo(plot.right, th);
      canvas.drawPath(
        dashPath(p, const [6, 4]),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = axisColor,
      );
      if (thresholdLabel != null)
        _text(
          canvas,
          thresholdLabel!,
          Offset(plot.right - 2, th - textStyle.fontSize! * .8),
          right: true,
        );
    }

    canvas
      ..save()
      ..clipRect(
        Rect.fromLTRB(
          plot.left - 2,
          plot.top - 4,
          plot.left + plot.width * progress.value + 2,
          plot.bottom + 4,
        ),
      );
    final bands = band;
    if (bands != null) {
      final fill = Paint()..style = PaintingStyle.fill;
      if (bandShader != null) {
        fill.shader = bandShader;
      } else {
        fill.color = bandColor.withValues(alpha: .25);
      }
      for (final p in bands) {
        canvas.drawPath(p, fill);
      }
    }
    for (final layer in series) {
      _drawLayer(canvas, layer);
    }
    canvas.restore();

    final sd = scrub;
    if (sd != null) {
      final x = scale.x(sd);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = inkColor.withValues(alpha: .55)
          ..strokeWidth = 1,
      );
      for (var i = 0; i < series.length; i++) {
        final v = i < scrubValues.length ? scrubValues[i] : null;
        if (v == null) continue;
        canvas
          ..save()
          ..translate(x - 6, scale.y(v) - 6);
        PicoMarkPainter(
          mark: series[i].state.mark,
          color: series[i].color,
        ).paint(canvas, const Size(12, 12));
        canvas.restore();
      }
    }
  }

  void _drawLayer(Canvas canvas, ChartLayer layer) {
    final st = layer.state;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = st.line == PicoLineForm.dotted
          ? StrokeCap.round
          : StrokeCap.butt
      ..color = layer.color
      ..strokeWidth = st.line == PicoLineForm.doubled
          ? 1.6
          : (st.line == PicoLineForm.dotted ? 3 : 2.5);
    for (final run in layer.runs) {
      if (run.length == 1) {
        canvas.drawCircle(run.first, 2, Paint()..color = layer.color);
        continue;
      }
      Path path(double dy) {
        final p = Path()..moveTo(run.first.dx, run.first.dy + dy);
        for (final o in run.skip(1)) {
          p.lineTo(o.dx, o.dy + dy);
        }
        return p;
      }

      switch (st.line) {
        case PicoLineForm.solid:
          canvas.drawPath(path(0), stroke);
        case PicoLineForm.doubled:
          canvas
            ..drawPath(path(-1.8), stroke)
            ..drawPath(path(1.8), stroke);
        case PicoLineForm.dotted || PicoLineForm.dashed:
          canvas.drawPath(dashPath(path(0), st.dash!), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(ChartPainter old) =>
      old.scale != scale ||
      old.scrub != scrub ||
      old.series != series ||
      old.band != band ||
      old.bandShader != bandShader ||
      old.threshold != threshold;
}
