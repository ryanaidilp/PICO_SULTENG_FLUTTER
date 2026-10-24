import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/area_view.dart';
import 'package:statistik/src/l10n/translations.g.dart';

PicoState stateOf(CaseMetric m) => switch (m) {
  CaseMetric.positive => PicoState.positive,
  CaseMetric.recovered => PicoState.recovered,
  CaseMetric.deceased => PicoState.deceased,
  CaseMetric.active => PicoState.active,
};

/// The case type dropdown of the first app, with the state mark before the
/// label (never colour alone).
class CaseTypeDropdown extends StatelessWidget {
  /// Creates the dropdown.
  const CaseTypeDropdown({
    required this.metric,
    required this.onChanged,
    super.key,
  });

  /// The chosen type.
  final CaseMetric metric;

  /// A type was chosen.
  final ValueChanged<CaseMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = PicoKitText.of(context);
    final colors = context.picoStates;
    return PicoDropdown<CaseMetric>(
      semanticLabel: context.t.caseTypeLabel,
      value: metric,
      leading: PicoMarkView(
        mark: stateOf(metric).mark,
        color: colors.of(stateOf(metric)),
        size: 12,
      ),
      items: [
        for (final m in CaseMetric.values)
          PicoDropdownItem(m, k.stateLabel(stateOf(m))),
      ],
      onChanged: onChanged,
    );
  }
}

/// Picks one calendar year of the data, or the whole range. Years come from
/// the data bounds; the last year ends on the last day with data.
class YearDropdown extends StatelessWidget {
  /// Creates the dropdown.
  const YearDropdown({
    required this.range,
    required this.bounds,
    required this.onChanged,
    super.key,
  });

  /// Effective range.
  final DateTimeRange range;

  /// Data bounds.
  final DateTimeRange bounds;

  /// A range was chosen.
  final ValueChanged<DateTimeRange> onChanged;

  DateTimeRange _yearRange(int y) => DateTimeRange(
    start: DateTime(y).isBefore(bounds.start) ? bounds.start : DateTime(y),
    end: DateTime(y, 12, 31).isAfter(bounds.end)
        ? bounds.end
        : DateTime(y, 12, 31),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final years = [
      for (var y = bounds.end.year; y >= bounds.start.year; y--) y,
    ];
    // 0 is all years, -1 a custom range (7, 30 or 90 days, or picked dates).
    final current = range == bounds
        ? 0
        : years.firstWhere((y) => _yearRange(y) == range, orElse: () => -1);
    return PicoDropdown<int>(
      semanticLabel: t.yearLabel,
      value: current,
      leading: const Icon(Icons.calendar_today_outlined, size: 16),
      items: [
        if (current == -1) PicoDropdownItem(-1, t.yearCustom),
        PicoDropdownItem(0, t.yearAll),
        for (final y in years) PicoDropdownItem(y, '$y'),
      ],
      onChanged: (y) {
        if (y != -1) onChanged(y == 0 ? bounds : _yearRange(y));
      },
    );
  }
}

/// Nasional, Provinsi, Kabupaten. It stays on screen in the loading, offline
/// and error states too, so the user can still reach Kabupaten (which can
/// answer from saved data) when the national series is not available.
class AreaLevelBar extends StatelessWidget {
  /// Creates the bar.
  const AreaLevelBar({required this.level, required this.onLevel, super.key});

  /// The current level.
  final AreaLevel level;

  /// A level was chosen.
  final ValueChanged<AreaLevel> onLevel;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    String levelLabel(AreaLevel l) => switch (l) {
      AreaLevel.national => t.levelNational,
      AreaLevel.province => t.levelProvince,
      AreaLevel.regency => t.levelRegency,
    };
    return Semantics(
      label: t.levelLabel,
      container: true,
      child: PicoSegmented<AreaLevel>(
        values: AreaLevel.values,
        selected: level,
        label: levelLabel,
        onChanged: onLevel,
      ),
    );
  }
}

/// Level, case type, daily or cumulative, compare and date range controls.
class AreaControls extends StatelessWidget {
  /// Creates the controls.
  const AreaControls({
    required this.query,
    required this.compare,
    required this.range,
    required this.bounds,
    required this.onQuery,
    required this.onCompare,
    required this.onLevel,
    super.key,
  });

  /// Current query.
  final AreaQuery query;

  /// Compare overlay flag.
  final bool compare;

  /// Effective range.
  final DateTimeRange range;

  /// Data bounds.
  final DateTimeRange bounds;

  /// A query change.
  final ValueChanged<AreaQuery> onQuery;

  /// Compare toggled.
  final ValueChanged<bool> onCompare;

  /// A level was chosen.
  final ValueChanged<AreaLevel> onLevel;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AreaLevelBar(level: query.level, onLevel: onLevel),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CaseTypeDropdown(
              metric: query.metric,
              onChanged: (m) => onQuery(query.copyWith(metric: m)),
            ),
            YearDropdown(
              range: range,
              bounds: bounds,
              onChanged: (r) =>
                  onQuery(query.copyWith(from: r.start, to: r.end)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(t.cumulative),
          value: !query.daily,
          onChanged: (c) => onQuery(query.copyWith(daily: !c)),
        ),
        MergeSemantics(
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(t.compare),
            subtitle: query.daily ? Text(t.compareHint) : null,
            value: compare && !query.daily,
            onChanged: query.daily ? null : onCompare,
          ),
        ),
        PicoDateRangeBar(
          range: range,
          bounds: bounds,
          onChanged: (r) => onQuery(query.copyWith(from: r.start, to: r.end)),
        ),
      ],
    );
  }
}

/// The four tiles of the last day in range: cumulative value and the day's
/// change, with a minus sign and a down arrow when the change is negative.
class AreaTiles extends StatelessWidget {
  /// Creates the tiles.
  const AreaTiles({required this.day, super.key});

  /// The last day in range.
  final CaseDay day;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.5;
    return LayoutBuilder(
      builder: (context, box) {
        final w = large ? box.maxWidth : (box.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in CaseMetric.values)
              SizedBox(
                width: w,
                child: PicoStatTile(
                  state: stateOf(m),
                  value: day.cumulative.of(m),
                  delta: day.daily.of(m),
                  date: day.date,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "Total dalam rentang" for the chosen metric and the daily peak note.
class AreaTotals extends StatelessWidget {
  /// Creates the summary.
  const AreaTotals({required this.view, required this.metric, super.key});

  /// The derived view.
  final AreaView view;

  /// The chosen metric.
  final CaseMetric metric;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final style = context.typography.body.regular.copyWith(
      color: context.colors.foreground.main,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.totalInRange}: ${k.number(view.totals.of(metric))}',
          style: style,
        ),
        const SizedBox(height: 4),
        Text(
          t.peak(
            value: k.number(view.peak.daily.of(metric)),
            date: k.date(view.peak.date),
          ),
          style: style,
        ),
      ],
    );
  }
}

/// The line chart of the chosen metric, or the four cumulative metrics when
/// "Bandingkan" is on.
class AreaChart extends StatelessWidget {
  /// Creates the chart.
  const AreaChart({
    required this.view,
    required this.query,
    required this.compare,
    super.key,
  });

  /// The derived view.
  final AreaView view;

  /// The query.
  final AreaQuery query;

  /// Compare overlay (cumulative only).
  final bool compare;

  @override
  Widget build(BuildContext context) {
    final overlay = compare && !query.daily;
    final metrics = overlay ? CaseMetric.values : [query.metric];
    return PicoLineChart(
      range: DateTimeRange(start: view.range.start, end: view.range.end),
      yLabel: query.daily ? context.t.yDaily : context.t.yCumulative,
      series: [
        for (final m in metrics)
          ChartSeries(
            state: stateOf(m),
            points: [
              for (final d in view.days)
                (d.date, query.daily ? d.daily.of(m) : d.cumulative.of(m)),
            ],
          ),
      ],
    );
  }
}

/// Text links under the chart: Rt, Tes and Peta.
class AreaLinks extends StatelessWidget {
  /// Creates the links.
  const AreaLinks({required this.query, required this.onOpen, super.key});

  /// Current query (the Rt link keeps the area).
  final AreaQuery query;

  /// Opens a path.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final rtArea = switch (query.area) {
      NationalArea() => 'national',
      ProvinceArea(:final id) => 'province:$id',
      RegencyArea(:final code) => 'regency:$code',
    };
    Widget link(String label, String path) => TextButton(
      onPressed: () => onOpen(path),
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(label),
    );
    return Wrap(
      spacing: 8,
      children: [
        link(t.seeRt, PicoRoutes.rt(area: rtArea)),
        link(t.tests, PicoRoutes.tes),
        link(t.map, PicoRoutes.peta()),
      ],
    );
  }
}
