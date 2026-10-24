import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/regency_math.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/regencies_cubit.dart';
import 'package:statistik/src/presentation/ui/widgets/area_widgets.dart';
import 'package:statistik/src/presentation/ui/widgets/regency_widgets.dart';

/// `/statistik/kabupaten`: the 13 kabupaten and kota side by side, by value or
/// by name, for one case type.
@RoutePage()
class KabupatenPage extends StatefulWidget {
  const KabupatenPage({this.onOpen, super.key});

  /// Opens a path. Defaults to the router.
  final ValueChanged<String>? onOpen;

  @override
  State<KabupatenPage> createState() => _KabupatenPageState();
}

class _KabupatenPageState extends State<KabupatenPage> {
  var _metric = CaseMetric.positive;
  var _sort = RegencySort.value;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RegenciesCubit, RegenciesState>(
        builder: (context, s) {
          final cubit = context.read<RegenciesCubit>();
          final t = context.t;
          final k = PicoKitText.of(context);
          void open(String p) =>
              (widget.onOpen ??
              (x) => unawaited(context.router.navigatePath(x)))(p);
          if (s.loading) return const PicoStateView.loading();
          final names = s.names;
          final snap = s.summaries;
          if (snap == null || names == null) {
            void retry() => cubit.retry();
            return s.failure?.kind == PicoFailureKind.network
                ? PicoStateView.offline(onRetry: retry)
                : PicoStateView.error(onRetry: retry);
          }
          final rows = orderRegencies(
            names,
            snap.data,
            metric: _metric,
            sort: _sort,
          );
          final loaded = snap.data.length;
          final max = snap.data.fold<int>(1, (a, b) {
            final v = cumulativeOf(b, _metric);
            return v > a ? v : a;
          });
          return RefreshIndicator.adaptive(
            onRefresh: cubit.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    t.regencyTitle,
                    style: context.typography.heading.h3.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.regencyNote,
                  style: context.typography.body.small.copyWith(
                    color: context.colors.foreground.subtle,
                  ),
                ),
                const SizedBox(height: 12),
                MetricChips(
                  metric: _metric,
                  onChanged: (m) => setState(() => _metric = m),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: t.sortLabel,
                  container: true,
                  child: PicoSegmented<RegencySort>(
                    values: RegencySort.values,
                    selected: _sort,
                    label: (v) =>
                        v == RegencySort.value ? t.sortValue : t.sortName,
                    onChanged: (v) => setState(() => _sort = v),
                  ),
                ),
                const SizedBox(height: 8),
                if (!s.done && loaded < names.length)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      t.regencyLoading(
                        n: k.number(loaded),
                        total: k.number(names.length),
                      ),
                      style: context.typography.body.regular.copyWith(
                        color: context.colors.foreground.main,
                      ),
                    ),
                  ),
                for (final r in rows)
                  if (r.summary != null)
                    RegencyRow(
                      name: r.regency.name,
                      summary: r.summary!,
                      metric: _metric,
                      max: max,
                      onTap: () =>
                          open(PicoRoutes.kabupatenDetail(r.regency.code)),
                    )
                  else if (s.done)
                    FailedRegencyRow(
                      name: r.regency.name,
                      onRetry: cubit.retry,
                    ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => open(PicoRoutes.peta(metric: _metric.name)),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(t.seeOnMap),
                ),
                const SizedBox(height: 8),
                PicoDataStamp(
                  dataDate: snap.data.isEmpty
                      ? DateTime.now()
                      : snap.data.first.latest.date,
                  fetchedAt: snap.fetchedAt,
                  fromCache: snap.source == DataSource.cache,
                  isStale: snap.isStale,
                ),
              ],
            ),
          );
        },
      );
}
