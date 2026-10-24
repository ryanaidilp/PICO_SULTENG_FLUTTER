import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:vaksin/src/l10n/translations.g.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_bloc.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_event.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_state.dart';
import 'package:vaksin/src/presentation/ui/widgets/vaksin_widgets.dart';

/// `/layanan/vaksin`: Cakupan and Lokasi.
@RoutePage()
class VaksinPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<VaksinBloc, VaksinState>(
    builder: (context, s) {
      final bloc = context.read<VaksinBloc>();
      final t = context.t;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: PicoSegmented<VaksinSegment>(
              values: VaksinSegment.values,
              selected: s.segment,
              label: (v) => v == VaksinSegment.coverage
                  ? t.segmentCoverage
                  : t.segmentLocations,
              onChanged: (v) => bloc.add(VaksinSegmentChanged(v)),
            ),
          ),
          Expanded(
            child: s.segment == VaksinSegment.coverage
                ? _Coverage(state: s)
                : _Locations(state: s),
          ),
        ],
      );
    },
  );
}

Widget _failure(VaksinBloc bloc, PicoFailure f) {
  void retry() => bloc.add(const VaksinRefreshed());
  return f.kind == PicoFailureKind.network
      ? PicoStateView.offline(onRetry: retry)
      : PicoStateView.error(onRetry: retry);
}

Future<void> _refresh(VaksinBloc bloc) {
  final done = Completer<void>();
  bloc.add(VaksinRefreshed(done: done));
  return done.future;
}

class _Coverage extends StatelessWidget {
  const new({required this.state});

  final VaksinState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VaksinBloc>();
    final t = context.t;
    final k = PicoKitText.of(context);
    final section = state.series;
    final scope = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PicoSegmented<VaccinationScope>(
        values: VaccinationScope.values,
        selected: state.scope,
        label: (v) =>
            v == VaccinationScope.national ? t.scopeNational : t.scopeSulteng,
        onChanged: (v) => bloc.add(VaksinScopeChanged(v)),
      ),
    );
    final snap = section.snapshot;
    final latest = snap?.data.latest;
    Widget body;
    if (section.loading) {
      body = const SizedBox(height: 320, child: PicoStateView.loading());
    } else if (snap == null || latest == null) {
      body = SizedBox(
        height: 360,
        child: _failure(
          bloc,
          section.failure ??
              const PicoFailure(PicoFailureKind.server, message: 'empty'),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.target(value: k.number(latest.target)),
            style: context.typography.body.regular.copyWith(
              color: context.colors.foreground.main,
            ),
          ),
          const SizedBox(height: 8),
          DoseBars(doses: latest.total, target: latest.target),
          const SizedBox(height: 16),
          PicoSectionHeader(title: t.groups),
          const SizedBox(height: 12),
          GroupCoverage(
            groups: {for (final e in latest.groups.entries) e.key: e.value},
          ),
          PicoSectionHeader(title: t.trend),
          const SizedBox(height: 12),
          DoseTrend(series: snap.data),
          const SizedBox(height: 16),
          PicoDataStamp(
            dataDate: latest.date,
            fetchedAt: snap.fetchedAt,
            fromCache: snap.source == DataSource.cache,
            isStale: snap.isStale,
          ),
        ],
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () => _refresh(bloc),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [scope, body],
      ),
    );
  }
}

class _Locations extends StatelessWidget {
  const new({required this.state});

  final VaksinState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VaksinBloc>();
    final section = state.locations;
    final snap = section.snapshot;
    if (section.loading) return const PicoStateView.loading();
    if (snap == null) {
      return _failure(
        bloc,
        section.failure ??
            const PicoFailure(PicoFailureKind.server, message: 'empty'),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () => _refresh(bloc),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [LocationList(data: snap.data)],
      ),
    );
  }
}
