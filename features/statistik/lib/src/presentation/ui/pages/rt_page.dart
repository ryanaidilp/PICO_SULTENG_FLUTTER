import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/domain/rt_view.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/regencies_cubit.dart';
import 'package:statistik/src/presentation/bloc/rt_bloc.dart';
import 'package:statistik/src/presentation/ui/widgets/province_picker.dart';
import 'package:statistik/src/presentation/ui/widgets/rt_widgets.dart';

/// `/statistik/rt?area=national|province:<id>|regency:<code>`.
@RoutePage()
class RtPage extends StatelessWidget {
  const RtPage({@QueryParam('area') this.area, super.key});

  /// The `area` query value.
  final String? area;

  @override
  Widget build(BuildContext context) => RtContent(initial: parseRtArea(area));
}

/// The Rt page body. [onNavigate] replaces the route with its canonical path
/// and [onOpen] opens another path; both are replaced in tests.
class RtContent extends StatefulWidget {
  const RtContent({
    required this.initial,
    this.onNavigate,
    this.onOpen,
    super.key,
  });

  final AreaRef initial;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<String>? onOpen;

  @override
  State<RtContent> createState() => _RtContentState();
}

class _RtContentState extends State<RtContent> {
  @override
  void initState() {
    super.initState();
    context.read<RtBloc>().add(RtOpened(widget.initial));
  }

  void _setArea(AreaRef a) {
    context.read<RtBloc>().add(RtAreaChanged(a));
    final path = PicoRoutes.rt(area: rtAreaParam(a));
    final fn = widget.onNavigate;
    if (fn != null) {
      fn(path);
    } else {
      unawaited(context.router.replacePath(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RtBloc>();
    final open =
        widget.onOpen ?? (p) => unawaited(context.router.navigatePath(p));
    return BlocBuilder<RtBloc, RtState>(
      builder: (context, s) {
        final t = context.t;
        void retry() => bloc.add(const RtRefreshed());
        final body = <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.rtTitle,
              style: context.typography.heading.h3.copyWith(
                color: context.colors.foreground.main,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RtAreaControls(
            area: s.area,
            onArea: _setArea,
            onPickProvince: () => showProvinceSheet(
              context,
              selectedId: s.area is ProvinceArea
                  ? (s.area as ProvinceArea).id
                  : null,
              onPick: (id) => _setArea(AreaRef.province(id)),
            ),
            onPickRegency: () => showRegencySheet(
              context,
              selectedCode: s.area is RegencyArea
                  ? (s.area as RegencyArea).code
                  : null,
              onPick: (c) => _setArea(AreaRef.regency(c)),
            ),
          ),
          const SizedBox(height: 12),
        ];
        Widget content;
        final view = s.view;
        final snap = s.snapshot;
        if (s.loading) {
          content = const SizedBox(height: 320, child: PicoStateView.loading());
        } else if (s.failure?.kind == PicoFailureKind.notFound) {
          content = SizedBox(
            height: 320,
            child: PicoStateView.notFound(message: t.areaNotFound),
          );
        } else if (view == null || snap == null) {
          content = SizedBox(
            height: 320,
            child: s.failure?.kind == PicoFailureKind.network
                ? PicoStateView.offline(onRetry: retry)
                : PicoStateView.error(onRetry: retry),
          );
        } else {
          final bounds = DateTimeRange(
            start: snap.data.days.first.date,
            end: rtEndOf(snap.data),
          );
          content = RtBody(
            view: view,
            areaName: snap.data.areaName,
            bounds: bounds,
            onRange: (r) => bloc.add(RtRangeChanged(r)),
            onMethod: () => open('${PicoRoutes.tentang}#metodologi'),
            stamp: PicoDataStamp(
              dataDate: rtEndOf(snap.data),
              fetchedAt: snap.fetchedAt,
              isStale: snap.isStale,
              offline: snap.isOffline,
              refreshFailed: snap.refreshFailed,
            ),
          );
        }
        return RefreshIndicator.adaptive(
          onRefresh: () {
            final done = Completer<void>();
            bloc.add(RtRefreshed(done: done));
            return done.future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [...body, content],
          ),
        );
      },
    );
  }
}

/// Opens the list of the 13 kabupaten and kota. [onPick] gets the code.
Future<void> showRegencySheet(
  BuildContext context, {
  required String? selectedCode,
  required ValueChanged<String> onPick,
}) {
  final cubit = context.read<RegenciesCubit>();
  final t = context.t;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheet) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<RegenciesCubit, RegenciesState>(
        builder: (c, s) {
          final names = s.names;
          if (names == null) return const PicoStateView.loading();
          return ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  t.rtRegencyTitle,
                  style: c.typography.heading.h4.copyWith(
                    color: c.colors.foreground.main,
                  ),
                ),
              ),
              for (final r in [
                ...names,
              ]..sort((a, b) => a.name.compareTo(b.name)))
                Semantics(
                  button: true,
                  selected: r.code == selectedCode,
                  label: r.name,
                  excludeSemantics: true,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    onPick(r.code);
                  },
                  child: InkWell(
                    onTap: () {
                      Navigator.of(sheet).pop();
                      onPick(r.code);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.name,
                                style: c.typography.body.regular.copyWith(
                                  color: c.colors.foreground.main,
                                ),
                              ),
                            ),
                            if (r.code == selectedCode)
                              Icon(
                                Icons.check,
                                color: c.colors.foreground.main,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
