import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:peta/src/domain/map_values.dart';
import 'package:peta/src/l10n/translations.g.dart';
import 'package:peta/src/presentation/bloc/peta_bloc.dart';
import 'package:peta/src/presentation/bloc/peta_event.dart';
import 'package:peta/src/presentation/bloc/peta_state.dart';
import 'package:peta/src/presentation/ui/widgets/peta_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// `/peta?metric=&date=`: the 13 kabupaten and kota on one map.
@RoutePage()
class PetaPage extends StatelessWidget {
  const PetaPage({
    @QueryParam('metric') this.metric,
    @QueryParam('date') this.date,
    super.key,
  });

  /// `positive|recovered|deceased|active|rt`.
  final String? metric;

  /// `YYYY-MM-DD`, within the data range.
  final String? date;

  @override
  Widget build(BuildContext context) =>
      PetaContent(initialMetric: metric, initialDate: date);
}

/// The map page body. [onOpen] opens a C07 path; replaced in tests.
class PetaContent extends StatefulWidget {
  const PetaContent({
    this.initialMetric,
    this.initialDate,
    this.onOpen,
    this.pickDate,
    super.key,
  });

  final String? initialMetric;
  final String? initialDate;
  final ValueChanged<String>? onOpen;

  /// Chooses a date. Defaults to the Material date picker. For tests.
  final Future<DateTime?> Function(BuildContext)? pickDate;

  @override
  State<PetaContent> createState() => _PetaContentState();
}

DateTime? _parseDate(String? s) {
  if (s == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return null;
  final p = s.split('-').map(int.parse).toList();
  final d = DateTime(p[0], p[1], p[2]);
  if (d.month != p[1] || d.day != p[2]) return null;
  return d.isBefore(kDataStart) || d.isAfter(kDataEnd) ? null : d;
}

class _PetaContentState extends State<PetaContent> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<PetaBloc>();
    final m = PetaMetric.values.where((e) => e.name == widget.initialMetric);
    if (m.isNotEmpty) bloc.add(PetaMetricChanged(m.first));
    final d = _parseDate(widget.initialDate);
    if (d != null) bloc.add(PetaDateChosen(d));
  }

  Future<DateTime?> _pick(BuildContext context) =>
      widget.pickDate?.call(context) ??
      showDatePicker(
        context: context,
        firstDate: kDataStart,
        lastDate: kDataEnd,
        initialDate: context.read<PetaBloc>().state.date ?? kDataEnd,
      );

  void _open(String path) =>
      (widget.onOpen ?? (p) => unawaited(context.router.navigatePath(p)))(path);

  Future<void> _sheet(BuildContext context, PetaState s, String code) async {
    final bloc = context.read<PetaBloc>();
    bloc.add(PetaSelected(code));
    final v = s.values.where((e) => e.code == code);
    if (v.isEmpty) return;
    final value = v.first;
    final t = context.t;
    final k = PicoKitText.of(context);
    final metric = s.metric;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                value.name,
                style: sheet.typography.heading.h4.copyWith(
                  color: sheet.colors.foreground.main,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.sheetValue(
                metric: metricLabel(context, metric),
                value: valueText(context, value, metric),
              ),
              style: sheet.typography.body.regular.copyWith(
                color: sheet.colors.foreground.main,
              ),
            ),
            Text(
              t.sheetDate(date: k.date(value.date)),
              style: sheet.typography.body.small.copyWith(
                color: sheet.colors.foreground.subtle,
              ),
            ),
            const SizedBox(height: 12),
            PicoButton(
              label: t.seeStats,
              onPressed: () {
                Navigator.of(sheet).pop();
                _open(PicoRoutes.kabupatenDetail(value.code));
              },
            ),
          ],
        ),
      ),
    );
    if (mounted) bloc.add(const PetaSelected(null));
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PetaBloc, PetaState>(
    builder: (context, s) {
      final bloc = context.read<PetaBloc>();
      final t = context.t;
      final k = PicoKitText.of(context);
      if (s.regions == null && s.failure == null) {
        return const PicoStateView.loading();
      }
      if (s.snapshot == null) {
        if (s.failure == null) return const PicoStateView.loading();
        void retry() => bloc.add(const PetaRefreshed());
        return s.failure!.kind == PicoFailureKind.network
            ? PicoStateView.offline(onRetry: retry)
            : PicoStateView.error(onRetry: retry);
      }
      final values = s.values;
      final dateText = s.date == null ? t.dateLatest : k.date(s.date!);
      return RefreshIndicator.adaptive(
        onRefresh: () {
          final done = Completer<void>();
          bloc.add(PetaRefreshed(done: done));
          return done.future;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              label: t.metricLabel,
              container: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in PetaMetric.values)
                    ChoiceChip(
                      avatar: PicoMarkView(
                        mark: stateOfMetric(m).mark,
                        color: context.picoStates.of(stateOfMetric(m)),
                        size: 12,
                      ),
                      label: Text(metricLabel(context, m)),
                      selected: s.metric == m,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => bloc.add(PetaMetricChanged(m)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(t.dateLatest),
                  selected: s.date == null,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => bloc.add(const PetaDateChosen(null)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final d = await _pick(context);
                    if (d != null) bloc.add(PetaDateChosen(d));
                  },
                  icon: const Icon(Icons.event),
                  label: Text(s.date == null ? t.datePick : dateText),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: t.viewLabel,
              container: true,
              child: PicoSegmented<bool>(
                values: const [false, true],
                selected: s.list,
                label: (l) => l ? t.viewList : t.viewMap,
                onChanged: (l) => bloc.add(PetaViewChanged(list: l)),
              ),
            ),
            const SizedBox(height: 12),
            if (s.dateLoading)
              Semantics(
                liveRegion: true,
                child: Text(
                  t.dateLoading(date: dateText),
                  style: context.typography.body.regular.copyWith(
                    color: context.colors.foreground.main,
                  ),
                ),
              )
            else if (!s.done && values.length < (s.regions?.length ?? 13))
              Semantics(
                liveRegion: true,
                child: Text(
                  t.regencyProgress(
                    n: k.number(values.length),
                    total: k.number(s.regions?.length ?? 13),
                  ),
                  style: context.typography.body.regular.copyWith(
                    color: context.colors.foreground.main,
                  ),
                ),
              ),
            if (s.regions == null)
              SizedBox(
                height: 240,
                child: Center(child: Text(t.loadingRegions)),
              )
            else if (s.list)
              PetaList(
                values: values,
                metric: s.metric,
                onSelect: (c) => _sheet(context, s, c),
              )
            else ...[
              Semantics(
                container: true,
                label: t.mapLabel(
                  metric: metricLabel(context, s.metric),
                  date: dateText,
                ),
                child: PetaMap(
                  regions: s.regions!,
                  values: values,
                  metric: s.metric,
                  selected: s.selected,
                  onSelect: (c) => _sheet(context, s, c),
                ),
              ),
              const SizedBox(height: 8),
              PetaLegend(values: values, metric: s.metric),
            ],
            if (values.isEmpty && s.done && !s.dateLoading)
              SizedBox(
                height: 160,
                child: PicoStateView.empty(message: t.none),
              ),
            const SizedBox(height: 12),
            PicoDataStamp(
              dataDate: s.snapshot!.data.isEmpty
                  ? kDataEnd
                  : s.snapshot!.data.first.latest.date,
              fetchedAt: s.snapshot!.fetchedAt,
              fromCache: s.snapshot!.source == DataSource.cache,
              isStale: s.snapshot!.isStale,
            ),
          ],
        ),
      );
    },
  );
}
