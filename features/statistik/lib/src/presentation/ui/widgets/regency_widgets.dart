import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/regency_math.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/ui/widgets/area_widgets.dart';

/// One kabupaten: name, the chosen metric (cumulative and daily) of the
/// latest day and a woven bar to compare. One semantics node.
class RegencyRow extends StatelessWidget {
  const RegencyRow({
    required this.name,
    required this.summary,
    required this.metric,
    required this.max,
    required this.onTap,
    super.key,
  });

  final String name;
  final AreaSummary summary;
  final CaseMetric metric;

  /// Scale of the bars: the largest cumulative value in the list.
  final int max;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = PicoKitText.of(context);
    final state = stateOf(metric);
    final cumulative = cumulativeOf(summary, metric);
    final daily = dailyOf(summary, metric);
    final dailyText =
        '${daily > 0
            ? '▲'
            : daily < 0
            ? '▼'
            : '■'} ${daily > 0 ? '+' : ''}${k.number(daily)}';
    final label = t.regencyRow(
      name: name,
      metric: k.stateLabel(state).toLowerCase(),
      value: k.number(cumulative),
      date: k.date(summary.latest.date),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
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
                      Expanded(
                        child: Text(
                          name,
                          style: context.typography.heading.h5.copyWith(
                            color: context.colors.foreground.main,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: context.colors.foreground.subtle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PicoWovenBar(
                    items: [
                      WovenBarItem(
                        label:
                            '${k.stateLabel(state)} · ${t.regencyCumulative}',
                        value: cumulative < 0 ? 0 : cumulative,
                        max: max,
                        state: state,
                      ),
                    ],
                  ),
                  Text(
                    '${t.regencyDaily(value: dailyText)} · ${k.date(summary.latest.date)}',
                    style: context.typography.body.small.copyWith(
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

/// The retry row of a kabupaten whose data did not load.
class FailedRegencyRow extends StatelessWidget {
  const FailedRegencyRow({
    required this.name,
    required this.onRetry,
    super.key,
  });

  final String name;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline.subtle),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.regencyFailed(name: name),
                  style: context.typography.body.regular.copyWith(
                    color: context.colors.foreground.main,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(t.regencyRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
