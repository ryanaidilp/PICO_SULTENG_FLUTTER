import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/watch_cubit.dart';

/// Cubit of the test types.
typedef TestTypesCubit = WatchCubit<List<TestType>>;

/// Cubit of the latest test totals.
typedef TestTotalsCubit = WatchCubit<List<TestTotal>>;

/// Short badge of a test type key: `pcr` PCR, `rdt_ab` RDT-Ab.
String testBadge(String key) => switch (key) {
  'pcr' => 'PCR',
  'rdt' => 'RDT',
  'tcm' => 'TCM',
  'rdt_ab' => 'RDT-Ab',
  'rdt_ag' => 'RDT-Ag',
  _ => key.toUpperCase().replaceAll('_', '-'),
};

/// Brand icon key of a test type.
String testIconKey(String key) =>
    key == 'pcr' || key == 'tcm' ? 'test.pcr' : 'test.rapid';

/// API text is Indonesian whatever the UI language, so it carries the `id`
/// locale for screen readers and hyphenation.
const _apiLocale = Locale('id');

/// One test type: icon, badge, name, the recommended label as text, sample,
/// duration, and the totals (or "no totals") under it.
class TestCard extends StatelessWidget {
  const TestCard({required this.type, this.total, super.key});

  final TestType type;

  /// The latest totals of this type, or null when the API has none.
  final TestTotal? total;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final text = context.typography;
    final main = context.colors.foreground.main;
    final subtle = context.colors.foreground.subtle;
    final tot = total;
    final max = tot == null
        ? 1
        : [
            tot.positive,
            tot.negative,
            tot.process,
            tot.invalid,
          ].fold<int>(1, (a, b) => a > b ? a : b);
    return Padding(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PicoBrandIcon(
                    testIconKey(type.key),
                    duotone: true,
                    size: 32,
                    color: main,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        '${testBadge(type.key)} · ${type.name}',
                        locale: _apiLocale,
                        style: text.heading.h5.copyWith(color: main),
                      ),
                    ),
                  ),
                ],
              ),
              if (type.isRecommended)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.testRecommended,
                    style: text.label.caption.copyWith(color: main),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                t.testSample(value: type.sample),
                locale: _apiLocale,
                style: text.body.small.copyWith(color: subtle),
              ),
              Text(
                t.testDuration(value: type.duration),
                locale: _apiLocale,
                style: text.body.small.copyWith(color: subtle),
              ),
              const SizedBox(height: 8),
              if (tot == null)
                Text(
                  t.testNoTotals,
                  style: text.body.regular.copyWith(color: subtle),
                )
              else
                PicoWovenBar(
                  items: [
                    WovenBarItem(
                      label: t.testsPositive,
                      value: tot.positive,
                      max: max,
                      state: PicoState.positive,
                    ),
                    WovenBarItem(
                      label: t.testsNegative,
                      value: tot.negative,
                      max: max,
                      state: PicoState.recovered,
                    ),
                    WovenBarItem(
                      label: t.testsProcess,
                      value: tot.process,
                      max: max,
                      state: PicoState.active,
                    ),
                    WovenBarItem(
                      label: t.testsInvalid,
                      value: tot.invalid,
                      max: max,
                      state: PicoState.deceased,
                    ),
                  ],
                  valueFormat: k.number,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
