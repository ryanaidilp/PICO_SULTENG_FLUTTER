import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/presentation/bloc/area_bloc.dart';
import 'package:statistik/src/presentation/bloc/area_event.dart';
import 'package:statistik/src/presentation/bloc/area_state.dart';
import 'package:statistik/src/presentation/ui/widgets/area_widgets.dart';

/// The area page: the tab root `/statistik` (national, or the area in the
/// query) and, through [ProvinceAreaPage], `/statistik/provinsi/{id}`.
///
/// Every change is a new [AreaQuery]. The bloc recomputes the view with no new
/// request, and the page replaces its route with the canonical path, so the
/// URL always restores the same view on a cold open.
class AreaContent extends StatefulWidget {
  /// Creates the view for [initial]. [onNavigate] and [onOpen] are replaced in
  /// tests.
  const AreaContent({
    required this.initial,
    this.onNavigate,
    this.onOpen,
    super.key,
  });

  /// The query read from the route.
  final AreaQuery initial;

  /// Replaces the current route with a canonical path.
  final ValueChanged<String>? onNavigate;

  /// Opens another C07 path.
  final ValueChanged<String>? onOpen;

  @override
  State<AreaContent> createState() => _AreaContentState();
}

class _AreaContentState extends State<AreaContent> {
  @override
  void initState() {
    super.initState();
    context.read<AreaBloc>().add(AreaOpened(widget.initial));
  }

  void _navigate(String path) {
    final fn = widget.onNavigate;
    if (fn != null) {
      fn(path);
    } else if (context.router.currentPath != Uri.parse(path).path ||
        context.router.currentUrl != path) {
      unawaited(context.router.replacePath(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AreaBloc>();
    final open =
        widget.onOpen ?? (p) => unawaited(context.router.navigatePath(p));
    return BlocBuilder<AreaBloc, AreaState>(
      builder: (context, s) {
        void retry() => bloc.add(const AreaRefreshed());
        void change(AreaQuery q) {
          bloc.add(AreaQueryChanged(q));
          _navigate(q.path);
        }

        if (s.loading) return const PicoStateView.loading();
        final failure = s.failure;
        final view = s.view;
        final snap = s.snapshot;
        if (failure != null || view == null || snap == null) {
          return failure?.kind == PicoFailureKind.network
              ? PicoStateView.offline(onRetry: retry)
              : PicoStateView.error(onRetry: retry);
        }
        final bounds = DateTimeRange(
          start: snap.data.days.first.date,
          end: snap.data.days.last.date,
        );
        return RefreshIndicator.adaptive(
          onRefresh: () {
            final done = Completer<void>();
            bloc.add(AreaRefreshed(done: done));
            return done.future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AreaControls(
                query: s.query,
                compare: s.compare,
                range: DateTimeRange(
                  start: view.range.start,
                  end: view.range.end,
                ),
                bounds: bounds,
                onQuery: change,
                onCompare: (_) => bloc.add(const AreaCompareToggled()),
                onLevel: (level) => switch (level) {
                  AreaLevel.national => change(
                    s.query.copyWith(area: const AreaRef.national()),
                  ),
                  AreaLevel.province => change(
                    s.query.copyWith(
                      area: s.query.area is ProvinceArea
                          ? s.query.area
                          : const AreaRef.province(kSultengProvinceId),
                    ),
                  ),
                  AreaLevel.regency => open(PicoRoutes.kabupatenList),
                },
              ),
              const SizedBox(height: 16),
              Text(
                snap.data.areaName,
                style: context.typography.heading.h3.copyWith(
                  color: context.colors.foreground.main,
                ),
              ),
              const SizedBox(height: 12),
              AreaChart(view: view, query: s.query, compare: s.compare),
              const SizedBox(height: 16),
              AreaTiles(day: view.last),
              const SizedBox(height: 12),
              AreaTotals(view: view, metric: s.query.metric),
              const SizedBox(height: 8),
              AreaLinks(query: s.query, onOpen: open),
              const SizedBox(height: 16),
              PicoDataStamp(
                dataDate: snap.data.days.last.date,
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
}

/// `/statistik`: national by default, or the area in the query.
@RoutePage()
class AreaPage extends StatelessWidget {
  /// Creates the page from the query parameters of the route.
  const AreaPage({
    @QueryParam('level') this.level,
    @QueryParam('id') this.id,
    @QueryParam('metric') this.metric,
    @QueryParam('from') this.from,
    @QueryParam('to') this.to,
    @QueryParam('daily') this.daily,
    super.key,
  });

  /// `national|province|regency`.
  final String? level;

  /// Province id or regency code.
  final String? id;

  /// Case type.
  final String? metric;

  /// First day `YYYY-MM-DD`.
  final String? from;

  /// Last day `YYYY-MM-DD`.
  final String? to;

  /// `true|false`.
  final String? daily;

  @override
  Widget build(BuildContext context) => AreaContent(
    initial: AreaQuery.fromParams({
      'level': level,
      'id': id,
      'metric': metric,
      'from': from,
      'to': to,
      'daily': daily,
    }),
  );
}

/// `/statistik/provinsi/{id}`.
@RoutePage()
class ProvinceAreaPage extends StatelessWidget {
  /// Creates the page for province [id].
  const ProvinceAreaPage({
    @PathParam('id') required this.id,
    @QueryParam('metric') this.metric,
    @QueryParam('from') this.from,
    @QueryParam('to') this.to,
    @QueryParam('daily') this.daily,
    super.key,
  });

  /// Province id.
  final String id;

  /// Case type.
  final String? metric;

  /// First day.
  final String? from;

  /// Last day.
  final String? to;

  /// `true|false`.
  final String? daily;

  @override
  Widget build(BuildContext context) => AreaContent(
    initial: AreaQuery.fromParams({
      'level': 'province',
      'id': id,
      'metric': metric,
      'from': from,
      'to': to,
      'daily': daily,
    }),
  );
}
