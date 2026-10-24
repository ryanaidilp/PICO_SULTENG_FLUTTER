import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter/material.dart';
import 'package:peta/src/domain/map_values.dart';
import 'package:peta/src/domain/regions.dart';
import 'package:peta/src/l10n/translations.g.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// The role of a metric (colour, mark).
PicoState stateOfMetric(PetaMetric m) => switch (m) {
  PetaMetric.positive => PicoState.positive,
  PetaMetric.recovered => PicoState.recovered,
  PetaMetric.deceased => PicoState.deceased,
  PetaMetric.active => PicoState.active,
  PetaMetric.rt => PicoState.rt,
};

String metricLabel(BuildContext context, PetaMetric m) {
  final k = PicoKitText.of(context);
  return m == PetaMetric.rt
      ? context.t.metricRt
      : k.stateLabel(stateOfMetric(m));
}

/// A value for display: a grouped integer, a 2 decimal Rt, or "Rt tidak dihitung".
String valueText(BuildContext context, MapValue v, PetaMetric m) {
  final k = PicoKitText.of(context);
  final x = v.value;
  if (x == null) return context.t.noRt;
  return m == PetaMetric.rt ? k.decimal(x.toDouble()) : k.number(x.round());
}

class _RegionPainter extends CustomPainter {
  _RegionPainter({
    required this.regions,
    required this.projection,
    required this.fill,
    required this.stroke,
    required this.selectedFill,
    required this.selectedStroke,
    required this.selected,
  });

  final List<Region> regions;
  final MapProjection projection;
  final Color fill;
  final Color stroke;
  final Color selectedFill;
  final Color selectedStroke;
  final String? selected;

  Path _path(Region r, Size size) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final poly in r.polygons) {
      for (final ring in poly) {
        for (var i = 0; i < ring.length; i++) {
          final o = projection.project(ring[i][0], ring[i][1], size);
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        path.close();
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Region? sel;
    for (final r in regions) {
      if (r.code == selected) {
        sel = r;
        continue;
      }
      final p = _path(r, size);
      canvas
        ..drawPath(p, Paint()..color = fill)
        ..drawPath(
          p,
          Paint()
            ..color = stroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeJoin = StrokeJoin.round,
        );
    }
    if (sel != null) {
      final p = _path(sel, size);
      canvas
        ..drawPath(p, Paint()..color = selectedFill)
        ..drawPath(
          p,
          Paint()
            ..color = selectedStroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round,
        );
    }
  }

  @override
  bool shouldRepaint(_RegionPainter old) =>
      old.selected != selected ||
      old.regions != regions ||
      old.fill != fill ||
      old.stroke != stroke;
}

/// The map: outlines, a mark per kabupaten sized by its step, and labels where
/// there is room. Marks are the interactive and semantic elements, each at
/// least 44 dp, in list order. A tap on an outline selects too.
class PetaMap extends StatelessWidget {
  const PetaMap({
    required this.regions,
    required this.values,
    required this.metric,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<Region> regions;
  final List<MapValue> values;
  final PetaMetric metric;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final pr = MapProjection(regions);
    final steps = markSteps(values);
    final byCode = {for (final v in values) v.code: v};
    final order = listOrder(values);
    final state = stateOfMetric(metric);
    final color = context.picoStates.of(state);
    final text = context.typography;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final size = Size(w, w / pr.aspect);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              Positioned.fill(
                // Outline taps are for sighted touch only. Each mark and each
                // list row is the accessible way to pick a kabupaten, so this
                // surface adds no unlabelled tap action to the semantics tree.
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapUp: (d) {
                    for (final r in regions) {
                      if (regionContains(r, pr, size, d.localPosition)) {
                        onSelect(r.code);
                        return;
                      }
                    }
                  },
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _RegionPainter(
                        regions: regions,
                        projection: pr,
                        fill: context.chartSurface.tint,
                        stroke: context.colors.outline.strong,
                        selectedFill: color.withValues(alpha: .28),
                        selectedStroke: context.colors.foreground.main,
                        selected: selected,
                      ),
                    ),
                  ),
                ),
              ),
              for (final r in regions)
                if (byCode[r.code] case final MapValue v)
                  _Mark(
                    region: r,
                    value: v,
                    step: steps[r.code],
                    order: order.indexWhere((o) => o.code == r.code),
                    metric: metric,
                    color: color,
                    point: pr.project(r.labelPoint[0], r.labelPoint[1], size),
                    label: pr.boundsOf(r, size).width >= 84,
                    labelStyle: text.label.caption.copyWith(
                      color: context.colors.foreground.main,
                    ),
                    selected: selected == r.code,
                    onTap: () => onSelect(r.code),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.region,
    required this.value,
    required this.step,
    required this.order,
    required this.metric,
    required this.color,
    required this.point,
    required this.label,
    required this.labelStyle,
    required this.selected,
    required this.onTap,
  });

  final Region region;
  final MapValue value;
  final int? step;
  final int order;
  final PetaMetric metric;
  final Color color;
  final Offset point;
  final bool label;
  final TextStyle labelStyle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final mark = stateOfMetric(metric).mark;
    final markSize = step == null ? 11.0 : PicoBrandPalette.markRamp[step!];
    final m = metricLabel(context, metric).toLowerCase();
    final v = valueText(context, value, metric);
    final semantic = value.value == null
        ? t.rowLabelNone(name: value.name, metric: m, date: k.date(value.date))
        : t.rowLabel(
            name: value.name,
            metric: m,
            value: v,
            date: k.date(value.date),
          );
    const target = 48.0;
    return Positioned(
      left: point.dx - target / 2,
      top: point.dy - target / 2,
      width: target,
      height: target,
      child: Semantics(
        button: true,
        label: semantic,
        selected: selected,
        sortKey: OrdinalSortKey(order.toDouble()),
        excludeSemantics: true,
        onTap: onTap,
        child: InkResponse(
          onTap: onTap,
          radius: target / 2,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // No value: a hollow, thin ring, never a size from zero.
              if (value.value == null)
                PicoMarkView(
                  mark: PicoMark.ring,
                  color: context.colors.foreground.subtle,
                  size: markSize,
                )
              else
                PicoMarkView(mark: mark, color: color, size: markSize),
              if (label)
                Positioned(
                  top: target / 2 + markSize / 2 - 4,
                  child: SizedBox(
                    width: 84,
                    child: Text(
                      value.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle.copyWith(fontSize: 10, height: 1.1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The six mark sizes and the range of values each stands for.
class PetaLegend extends StatelessWidget {
  const PetaLegend({required this.values, required this.metric, super.key});

  final List<MapValue> values;
  final PetaMetric metric;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final steps = markSteps(values);
    final ranges = stepRanges(values, steps);
    final state = stateOfMetric(metric);
    final color = context.picoStates.of(state);
    String fmt(num n) =>
        metric == PetaMetric.rt ? k.decimal(n.toDouble()) : k.number(n.round());
    final style = context.typography.body.small.copyWith(
      color: context.colors.foreground.main,
    );
    final hasNull = values.any((v) => v.value == null);
    return Semantics(
      container: true,
      label: t.legendTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.legendTitle,
            style: context.typography.label.caption.copyWith(
              color: context.colors.foreground.main,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 6; i++)
                if (ranges[i] case final r?)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: PicoMarkView(
                            mark: state.mark,
                            color: color,
                            size: PicoBrandPalette.markRamp[i],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        r.min == r.max
                            ? t.legendSingle(value: fmt(r.min))
                            : t.legendRange(min: fmt(r.min), max: fmt(r.max)),
                        style: style,
                      ),
                    ],
                  ),
              if (hasNull)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: PicoMarkView(
                          mark: PicoMark.ring,
                          color: context.colors.foreground.subtle,
                          size: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(t.legendNone, style: style),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.legendNote,
            style: context.typography.body.small.copyWith(
              color: context.colors.foreground.subtle,
            ),
          ),
        ],
      ),
    );
  }
}

/// The list alternative: the same data, in the same order as the semantics.
class PetaList extends StatelessWidget {
  const PetaList({
    required this.values,
    required this.metric,
    required this.onSelect,
    super.key,
  });

  final List<MapValue> values;
  final PetaMetric metric;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final m = metricLabel(context, metric).toLowerCase();
    return Column(
      children: [
        for (final v in listOrder(values))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Semantics(
              button: true,
              label: v.value == null
                  ? t.rowLabelNone(
                      name: v.name,
                      metric: m,
                      date: k.date(v.date),
                    )
                  : t.rowLabel(
                      name: v.name,
                      metric: m,
                      value: valueText(context, v, metric),
                      date: k.date(v.date),
                    ),
              excludeSemantics: true,
              onTap: () => onSelect(v.code),
              child: InkWell(
                onTap: () => onSelect(v.code),
                borderRadius: BorderRadius.circular(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.background.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.colors.outline.subtle),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.name,
                                  style: context.typography.heading.h5.copyWith(
                                    color: context.colors.foreground.main,
                                  ),
                                ),
                                Text(
                                  k.date(v.date),
                                  style: context.typography.body.small.copyWith(
                                    color: context.colors.foreground.subtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            valueText(context, v, metric),
                            style: context.typography.heading.h5.copyWith(
                              color: context.colors.foreground.main,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
