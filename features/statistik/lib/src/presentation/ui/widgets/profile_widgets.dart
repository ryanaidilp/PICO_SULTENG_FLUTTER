import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/province_math.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/watch_cubit.dart';

/// Cubit of the latest gender snapshot.
typedef GenderCubit = WatchCubit<GenderSnapshot>;

/// ODP and PDP, active and finished, as woven bars on one shared scale. A null
/// value is "no data" (an empty track), never 0. With no data at all: the
/// no-data state with its reason.
class MonitoringSection extends StatelessWidget {
  const MonitoringSection({required this.day, super.key});

  /// The last day in range.
  final CaseDay day;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final m = day.monitoring;
    final style = context.typography.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PicoSectionHeader(title: t.monitoringTitle),
        const SizedBox(height: 4),
        Text(
          t.monitoringDate(date: k.date(day.date)),
          style: style.small.copyWith(color: context.colors.foreground.subtle),
        ),
        const SizedBox(height: 8),
        if (m == null || !m.hasData) ...[
          Semantics(
            container: true,
            child: Text(
              t.monitoringNone,
              style: style.regular.copyWith(
                color: context.colors.foreground.main,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.monitoringReason,
            style: style.small.copyWith(
              color: context.colors.foreground.subtle,
            ),
          ),
        ] else
          Builder(
            builder: (context) {
              final values = [
                m.odpActive,
                m.odpFinished,
                m.pdpActive,
                m.pdpFinished,
              ];
              final max = values.whereType<int>().fold<int>(
                1,
                (a, b) => a > b ? a : b,
              );
              WovenBarItem item(String label, int? v, PicoState s) =>
                  WovenBarItem(label: label, value: v, max: max, state: s);
              return PicoWovenBar(
                items: [
                  item(t.odpActive, m.odpActive, PicoState.active),
                  item(t.odpFinished, m.odpFinished, PicoState.recovered),
                  item(t.pdpActive, m.pdpActive, PicoState.active),
                  item(t.pdpFinished, m.pdpFinished, PicoState.recovered),
                ],
              );
            },
          ),
      ],
    );
  }
}

String _ageLabel(Translations t, String key) => switch (key) {
  '0_14' => t.age014,
  '15_19' => t.age1519,
  '20_24' => t.age2024,
  '25_49' => t.age2549,
  '50_54' => t.age5054,
  '55_plus' => t.age55Plus,
  _ => key,
};

/// Positive cases by gender and age group for Sulawesi Tengah, from the latest
/// snapshot. The API gives no date for it, so it says "Data terakhir yang
/// tercatat" and shows no date.
class GenderSection extends StatelessWidget {
  const GenderSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<GenderCubit, WatchState<GenderSnapshot>>(
    builder: (context, s) {
      final t = context.t;
      final body = context.typography.body;
      final data = s.data;
      Widget content;
      if (s.loading) {
        content = const SizedBox(height: 120, child: PicoStateView.loading());
      } else if (data == null) {
        content = Text(
          t.genderNone,
          style: body.regular.copyWith(color: context.colors.foreground.main),
        );
      } else {
        final g = data.positive;
        final ageMax = [
          for (final c in [g.male, g.female])
            for (final v in c.ageGroups.values) v,
        ].fold<int>(1, (a, b) => a > b ? a : b);
        Widget block(String title, GenderCounts c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                title,
                style: context.typography.heading.h5.copyWith(
                  color: context.colors.foreground.main,
                ),
              ),
            ),
            const SizedBox(height: 4),
            PicoWovenBar(
              items: [
                WovenBarItem(
                  label: t.genderTotal,
                  value: c.total,
                  max: g.male.total + g.female.total,
                  state: PicoState.positive,
                ),
                for (final key in kAgeGroupOrder)
                  if (c.ageGroups.containsKey(key))
                    WovenBarItem(
                      label: _ageLabel(t, key),
                      value: c.ageGroups[key],
                      max: ageMax,
                      state: PicoState.positive,
                    ),
              ],
            ),
          ],
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            block(t.genderMale, g.male),
            block(t.genderFemale, g.female),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PicoSectionHeader(title: t.genderTitle),
          const SizedBox(height: 4),
          Text(
            '${t.genderPositive}. ${t.genderLatest}',
            style: body.small.copyWith(color: context.colors.foreground.subtle),
          ),
          content,
        ],
      );
    },
  );
}
