import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:identifiers/identifiers.dart';
import 'package:infografis/src/l10n/translations.g.dart';
import 'package:infografis/src/presentation/bloc/infografis_bloc.dart';
import 'package:infografis/src/presentation/bloc/infografis_event.dart';
import 'package:infografis/src/presentation/bloc/infografis_state.dart';
import 'package:infografis/src/presentation/ui/widgets/infografis_widgets.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// `/info/infografis`: a 2 column grid that loads the next page at the end.
@RoutePage()
class InfografisPage extends StatelessWidget {
  const new({this.onOpen, super.key});

  /// Opens a path. Defaults to the router.
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InfografisBloc, InfografisState>(
        builder: (context, s) {
          final bloc = context.read<InfografisBloc>();
          if (s.loading) return const PicoStateView.loading();
          if (s.items.isEmpty) {
            void retry() => bloc.add(const InfografisRefreshed());
            if (s.failure == null) {
              return PicoStateView.empty(message: context.t.noItems);
            }
            return s.failure!.kind == PicoFailureKind.network
                ? PicoStateView.offline(onRetry: retry)
                : PicoStateView.error(onRetry: retry);
          }
          void open(String p) =>
              (onOpen ?? (x) => context.router.navigatePath(x))(p);
          final large = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.5;
          final cols = large ? 1 : 2;
          final rows = <Widget>[];
          for (var i = 0; i < s.items.length; i += cols) {
            final chunk = s.items.skip(i).take(cols).toList();
            rows.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var j = 0; j < cols; j++) ...[
                        if (j > 0) const SizedBox(width: 8),
                        Expanded(
                          child: j < chunk.length
                              ? InfographicCard(
                                  item: chunk[j],
                                  onTap: () => open(
                                    PicoRoutes.infografisDetail(chunk[j].id),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }
          return NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) {
              // Near the end, or too short to scroll at all: load the next.
              if (n.metrics.extentAfter < 400) {
                bloc.add(const InfografisMoreRequested());
              }
              return false;
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 400) {
                  bloc.add(const InfografisMoreRequested());
                }
                return false;
              },
              child: RefreshIndicator.adaptive(
                onRefresh: () {
                  final done = Completer<void>();
                  bloc.add(InfografisRefreshed(done: done));
                  return done.future;
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...rows,
                    if (s.loadingMore)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Semantics(
                            label: context.t.loadingMore,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    if (s.failure != null && !s.loadingMore && s.hasNext)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              bloc.add(const InfografisMoreRequested()),
                          child: Text(PicoKitText.of(context).retry),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
