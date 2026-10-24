import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistik/src/l10n/translations.g.dart';
import 'package:statistik/src/presentation/bloc/watch_cubit.dart';
import 'package:statistik/src/presentation/ui/widgets/tests_widgets.dart';

/// `/statistik/tes`: the test types and the last recorded totals of Sulawesi
/// Tengah. The totals have no date in the API, so none is shown.
@RoutePage()
class TestsPage extends StatelessWidget {
  const TestsPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TestTypesCubit, WatchState<List<TestType>>>(
    builder: (context, types) =>
        BlocBuilder<TestTotalsCubit, WatchState<List<TestTotal>>>(
          builder: (context, totals) {
            final t = context.t;
            final text = context.typography;
            final typesCubit = context.read<TestTypesCubit>();
            final totalsCubit = context.read<TestTotalsCubit>();
            if (types.loading) return const PicoStateView.loading();
            final list = types.data;
            if (list == null) {
              void retry() => unawaited(typesCubit.refresh());
              return types.failure?.kind == PicoFailureKind.network
                  ? PicoStateView.offline(onRetry: retry)
                  : PicoStateView.error(onRetry: retry);
            }
            final byKey = {
              for (final r in totals.data ?? const <TestTotal>[]) r.typeKey: r,
            };
            return RefreshIndicator.adaptive(
              onRefresh: () =>
                  Future.wait([typesCubit.refresh(), totalsCubit.refresh()]),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      t.testsTitle,
                      style: text.heading.h3.copyWith(
                        color: context.colors.foreground.main,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.testsIntro,
                    style: text.body.regular.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // The API gives no date for these totals: say so in
                  // words and show no date.
                  Text(
                    '${t.testsTotalsTitle}. ${t.testsTotalsNote}',
                    style: text.body.small.copyWith(
                      color: context.colors.foreground.subtle,
                    ),
                  ),
                  if (list.isEmpty)
                    SizedBox(
                      height: 240,
                      child: PicoStateView.empty(message: t.testsNone),
                    ),
                  for (final type in list)
                    TestCard(type: type, total: byKey[type.key]),
                ],
              ),
            );
          },
        ),
  );
}
