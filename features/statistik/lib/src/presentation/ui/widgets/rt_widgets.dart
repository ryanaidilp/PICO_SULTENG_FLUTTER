import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/domain/rt_view.dart';
import 'package:statistik/src/l10n/translations.g.dart';

/// Nasional, Provinsi, Kabupaten, with the picker of the chosen level.
class RtAreaControls extends StatelessWidget {
  const RtAreaControls({
    required this.area,
    required this.onArea,
    required this.onPickProvince,
    required this.onPickRegency,
    super.key,
  });

  final AreaRef area;
  final ValueChanged<AreaRef> onArea;
  final VoidCallback onPickProvince;
  final VoidCallback onPickRegency;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    String label(AreaLevel l) => switch (l) {
      AreaLevel.national => t.levelNational,
      AreaLevel.province => t.levelProvince,
      AreaLevel.regency => t.levelRegency,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: t.rtArea,
          container: true,
          child: PicoSegmented<AreaLevel>(
            values: AreaLevel.values,
            selected: levelOf(area),
            label: label,
            onChanged: (l) => switch (l) {
              AreaLevel.national => onArea(const AreaRef.national()),
              AreaLevel.province => onArea(
                area is ProvinceArea
                    ? area
                    : const AreaRef.province(kSultengProvinceId),
              ),
              AreaLevel.regency => onPickRegency(),
            },
          ),
        ),
        if (area is ProvinceArea)
          TextButton.icon(
            onPressed: onPickProvince,
            icon: const Icon(Icons.swap_horiz),
            label: Text(t.provinceChange),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        if (area is RegencyArea)
          TextButton.icon(
            onPressed: onPickRegency,
            icon: const Icon(Icons.swap_horiz),
            label: Text(t.rtPickRegency),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
      ],
    );
  }
}

String _percent(int part, int whole) =>
    whole == 0 ? '0' : (part * 100 / whole).round().toString();

/// Range bar, the chart, the latest value, the null-day note and the
/// explainer.
class RtBody extends StatelessWidget {
  const RtBody({
    required this.view,
    required this.areaName,
    required this.bounds,
    required this.onRange,
    required this.onMethod,
    required this.stamp,
    super.key,
  });

  final RtView view;
  final String areaName;
  final DateTimeRange bounds;
  final ValueChanged<DateTimeRange> onRange;
  final VoidCallback onMethod;
  final Widget stamp;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final text = context.typography.body;
    final main = context.colors.foreground.main;
    final latest = view.latest;
    final range = DateTimeRange(start: view.range.start, end: view.range.end);
    final end = k.date(RtMethod.nationalLastDay);
    Widget p(String s, {bool small = false, bool strong = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        s,
        style: (small ? text.small : text.regular).copyWith(
          color: small ? context.colors.foreground.subtle : main,
          fontWeight: strong ? FontWeight.w600 : null,
        ),
      ),
    );
    final summary = view.computedDays == 0
        ? null
        : t.rtSummary(
            area: areaName,
            range: k.range(view.range.start, view.range.end),
            above: k.number(view.daysAboveOne),
            computed: k.number(view.computedDays),
            share: _percent(view.daysAboveOne, view.computedDays),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PicoDateRangeBar(range: range, bounds: bounds, onChanged: onRange),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            areaName,
            style: context.typography.heading.h4.copyWith(color: main),
          ),
        ),
        const SizedBox(height: 8),
        if (latest == null)
          p(t.rtNone, strong: true)
        else ...[
          p(
            latest.rt.lower == null || latest.rt.upper == null
                ? t.rtLatestNoBounds(
                    value: k.decimal(latest.rt.value),
                    date: k.date(latest.date),
                  )
                : t.rtLatest(
                    value: k.decimal(latest.rt.value),
                    lower: k.decimal(latest.rt.lower!),
                    upper: k.decimal(latest.rt.upper!),
                    date: k.date(latest.date),
                  ),
            strong: true,
          ),
          if (view.latestIsOlderThanData)
            p(t.rtLatestDataDay(date: k.date(view.lastDataDay)), small: true),
          PicoRtChart(
            points: view.points,
            range: range,
            semanticsSummary: summary,
          ),
          const SizedBox(height: 8),
          // Text labels, so the line and the band never rely on colour or
          // hatching alone.
          p(t.rtThreshold, small: true),
          p(
            t.rtBand(percent: k.number(RtMethod.credibleIntervalPercent)),
            small: true,
          ),
        ],
        if (view.nullDays > 0) ...[
          p(t.rtNullDays(count: k.number(view.nullDays)), strong: true),
          p(
            t.rtNullReason(min: k.number(RtMethod.minCasesInWindow), end: end),
            small: true,
          ),
        ],
        const SizedBox(height: 8),
        PicoSectionHeader(title: t.rtWhatTitle),
        const SizedBox(height: 8),
        p(t.rtWhat),
        p(t.rtRead(percent: k.number(RtMethod.credibleIntervalPercent))),
        PicoSectionHeader(title: t.rtMethodTitle),
        const SizedBox(height: 8),
        p(
          t.rtMethod(
            window: k.number(RtMethod.windowDays),
            mean: k.decimal(RtMethod.serialIntervalMean, digits: 1),
            sd: k.decimal(RtMethod.serialIntervalSd, digits: 1),
          ),
        ),
        PicoSectionHeader(title: t.rtMissingTitle),
        const SizedBox(height: 8),
        p(
          t.rtMissing(
            window: k.number(RtMethod.windowDays),
            min: k.number(RtMethod.minCasesInWindow),
            end: end,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onMethod,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(t.rtMore),
          ),
        ),
        const SizedBox(height: 8),
        stamp,
      ],
    );
  }
}
