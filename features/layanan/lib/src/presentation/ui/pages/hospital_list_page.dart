import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:layanan/src/domain/hospital_math.dart';
import 'package:layanan/src/l10n/translations.g.dart';
import 'package:layanan/src/presentation/bloc/hospitals_bloc.dart';
import 'package:layanan/src/presentation/bloc/hospitals_event.dart';
import 'package:layanan/src/presentation/bloc/hospitals_state.dart';
import 'package:layanan/src/presentation/ui/widgets/layanan_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// `/layanan/rumah-sakit`: hospitals grouped by kabupaten with a search field.
@RoutePage()
class HospitalListPage extends StatefulWidget {
  /// Creates the page. [onOpen] is for tests; it defaults to the router.
  const new({this.onOpen, super.key});

  /// Opens a path.
  final ValueChanged<String>? onOpen;

  @override
  State<HospitalListPage> createState() => _HospitalListPageState();
}

class _HospitalListPageState extends State<HospitalListPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh(HospitalsBloc bloc) {
    final done = Completer<void>();
    bloc.add(HospitalsRefreshed(done: done));
    return done.future;
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<HospitalsBloc, HospitalsState>(
        builder: (context, s) {
          final bloc = context.read<HospitalsBloc>();
          final t = context.t;
          final data = s.data;
          if (s.loading) return const PicoStateView.loading();
          if (data == null) {
            void retry() => bloc.add(const HospitalsRefreshed());
            return s.failure?.kind == PicoFailureKind.network
                ? PicoStateView.offline(onRetry: retry)
                : PicoStateView.error(onRetry: retry);
          }
          final names = {for (final r in data.regencies) r.code: r.name};
          final groups = groupHospitals(
            data.hospitals,
            data.regencies,
            query: _query,
          );
          return RefreshIndicator.adaptive(
            onRefresh: () => _refresh(bloc),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PageHeader(title: t.hospitalTitle),
                const SizedBox(height: 8),
                PicoTextField(
                  controller: _controller,
                  label: t.searchLabel,
                  hint: t.searchHint,
                  textInputAction: TextInputAction.search,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: t.searchClear,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                if (data.hospitals.isEmpty)
                  SizedBox(
                    height: 280,
                    child: PicoStateView.empty(message: t.noHospitals),
                  )
                else if (groups.isEmpty)
                  SizedBox(
                    height: 280,
                    child: PicoStateView.empty(
                      message: t.noMatch(query: _query.trim()),
                    ),
                  )
                else
                  for (final g in groups) ...[
                    const SizedBox(height: 12),
                    PicoSectionHeader(title: g.name),
                    for (final h in g.items)
                      HospitalRow(
                        hospital: h,
                        regencyName: names[h.regencyCode] ?? h.regencyCode,
                        onTap: () {
                          final path = PicoRoutes.rumahSakitDetail(h.code);
                          (widget.onOpen ??
                              (p) => context.router.navigatePath(p))(path);
                        },
                      ),
                  ],
              ],
            ),
          );
        },
      );
}
