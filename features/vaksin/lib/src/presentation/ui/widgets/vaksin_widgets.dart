import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:vaksin/src/domain/coverage_math.dart';
import 'package:vaksin/src/l10n/translations.g.dart';

String _groupName(Translations t, VaccineGroup g) => switch (g) {
  VaccineGroup.elderly => t.groupElderly,
  VaccineGroup.healthWorker => t.groupHealthWorker,
  VaccineGroup.publik => t.groupPublic,
  VaccineGroup.publicOfficer => t.groupPublicOfficer,
  VaccineGroup.teenager => t.groupTeenager,
};

String _percent(PicoKitText k, double v) => '${k.decimal(v)}%';

/// Dose 1 and dose 2 as woven bars: dose 1 on the plain weave, dose 2 on the
/// stepped diamond, each with its label, so they differ without colour.
class DoseBars extends StatelessWidget {
  /// Creates the bars for [doses] against [target].
  const DoseBars({required this.doses, required this.target, super.key});

  /// Dose numbers.
  final DoseStats doses;

  /// People targeted. A zero target draws empty bars.
  final int target;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    return PicoWovenBar(
      items: [
        WovenBarItem(
          label: t.barLabel(
            dose: t.dose1,
            percent: _percent(k, doses.coverageDose1),
          ),
          value: doses.cumulativeDose1,
          max: target,
          state: PicoState.positive,
        ),
        WovenBarItem(
          label: t.barLabel(
            dose: t.dose2,
            percent: _percent(k, doses.coverageDose2),
          ),
          value: doses.cumulativeDose2,
          max: target,
          state: PicoState.recovered,
        ),
      ],
    );
  }
}

/// The five groups with their coverage. A group with target 0 says "Tidak ada
/// target". A coverage over 100 percent is shown as is, with a note.
class GroupCoverage extends StatelessWidget {
  /// Creates the list for [groups].
  const GroupCoverage({required this.groups, super.key});

  /// Stats per group of the latest day.
  final Map<VaccineGroup, GroupStats> groups;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = context.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in kGroupOrder)
          if (groups[g] case final stats?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _groupName(t, g),
                    style: text.heading.h5.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                  if (!hasTarget(stats))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        t.noTarget,
                        style: text.body.regular.copyWith(
                          color: context.colors.foreground.subtle,
                        ),
                      ),
                    )
                  else ...[
                    DoseBars(doses: stats.doses, target: stats.target),
                    if (exceedsTarget(stats.doses.coverageDose1))
                      Text(
                        t.exceedsNote(dose: t.dose1),
                        style: text.label.caption.copyWith(
                          color: context.colors.foreground.subtle,
                        ),
                      ),
                    if (exceedsTarget(stats.doses.coverageDose2))
                      Text(
                        t.exceedsNote(dose: t.dose2),
                        style: text.label.caption.copyWith(
                          color: context.colors.foreground.subtle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

/// Cumulative dose 1 and dose 2 over time.
class DoseTrend extends StatelessWidget {
  /// Creates the chart for [series].
  const DoseTrend({required this.series, super.key});

  /// The coverage series.
  final VaccinationSeries series;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final days = series.days;
    return PicoLineChart(
      range: DateTimeRange(start: days.first.date, end: days.last.date),
      yLabel: t.yLabel,
      series: [
        ChartSeries(
          state: PicoState.positive,
          label: t.dose1,
          points: [for (final d in days) (d.date, d.total.cumulativeDose1)],
        ),
        ChartSeries(
          state: PicoState.recovered,
          label: t.dose2,
          points: [for (final d in days) (d.date, d.total.cumulativeDose2)],
        ),
      ],
    );
  }
}

/// One vaccination location: a single semantic node. Null quota, stock and
/// notes are hidden, never shown as 0.
class LocationTile extends StatelessWidget {
  /// Creates the tile.
  const LocationTile({required this.location, super.key});

  /// The location.
  final VaccineLocation location;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final text = context.typography;
    final lines = <String>[
      if (location.address.isNotEmpty) location.address,
      if (location.hours != null) t.hours(value: location.hours!),
      [
        if (location.firstDose) t.dose1Offered,
        if (location.secondDose) t.dose2Offered,
      ].join(' · '),
      if (location.dailyQuota != null)
        t.quota(value: k.number(location.dailyQuota!)),
      if (location.stockRemaining != null)
        t.stock(value: k.number(location.stockRemaining!)),
      if (location.notes != null) location.notes!,
    ].where((l) => l.isNotEmpty).toList();
    return Semantics(
      container: true,
      label: [location.name, ...lines].join(', '),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.background.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.colors.outline.subtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: text.heading.h5.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                  for (final l in lines)
                    Text(
                      l,
                      style: text.body.small.copyWith(
                        color: context.colors.foreground.subtle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Locations grouped by kabupaten.
class LocationList extends StatelessWidget {
  /// Creates the list.
  const LocationList({required this.data, super.key});

  /// Locations with regency names.
  final ({List<VaccineLocation> locations, List<Regency> regencies}) data;

  @override
  Widget build(BuildContext context) {
    final groups = groupLocations(data.locations, data.regencies);
    if (groups.isEmpty)
      return PicoStateView.empty(message: context.t.noLocations);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in groups) ...[
          const SizedBox(height: 12),
          PicoSectionHeader(title: g.name),
          for (final l in g.items) LocationTile(location: l),
        ],
      ],
    );
  }
}
