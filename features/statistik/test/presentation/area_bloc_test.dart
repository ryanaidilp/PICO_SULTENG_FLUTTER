import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';
import 'package:statistik/src/domain/area_query.dart';
import 'package:statistik/src/presentation/bloc/area_bloc.dart';
import 'package:statistik/src/presentation/bloc/area_event.dart';

import '../support.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late CountingCases repo;
  late AreaBloc bloc;

  setUp(() {
    repo = CountingCases(sultengSeries());
    bloc = AreaBloc(repo);
  });
  tearDown(() => bloc.close());

  test('opening an area loads its series once', () async {
    bloc.add(const AreaOpened(AreaQuery()));
    await settle();
    expect(bloc.state.loading, isFalse);
    expect(bloc.state.view, isNotNull);
    expect(repo.calls[const AreaRef.national()], 1);
  });

  test(
    'changing metric, daily or range emits a new view with no new request',
    () async {
      bloc.add(const AreaOpened(AreaQuery()));
      await settle();
      final first = bloc.state.view;
      bloc
        ..add(const AreaQueryChanged(AreaQuery(metric: CaseMetric.active)))
        ..add(
          const AreaQueryChanged(
            AreaQuery(metric: CaseMetric.active, daily: false),
          ),
        );
      await settle();
      bloc.add(
        AreaQueryChanged(
          AreaQuery(
            metric: CaseMetric.active,
            daily: false,
            from: DateTime(2021, 7, 15),
            to: DateTime(2021, 7, 15),
          ),
        ),
      );
      await settle();
      expect(bloc.state.query.metric, CaseMetric.active);
      expect(bloc.state.view, isNot(first));
      expect(bloc.state.view!.days.length, 1);
      expect(repo.calls[const AreaRef.national()], 1);
    },
  );

  test('changing the area asks the repository for that area', () async {
    bloc.add(const AreaOpened(AreaQuery()));
    await settle();
    bloc.add(const AreaQueryChanged(AreaQuery(area: AreaRef.province('72'))));
    await settle();
    expect(repo.calls[const AreaRef.province('72')], 1);
    expect(bloc.state.snapshot!.data.areaName, 'Sulawesi Tengah');
  });

  test('re-opening with the same query does not reload', () async {
    bloc.add(const AreaOpened(AreaQuery()));
    await settle();
    bloc.add(const AreaOpened(AreaQuery()));
    await settle();
    expect(repo.calls[const AreaRef.national()], 1);
  });

  test(
    'refresh asks again with forceRefresh and the done future completes',
    () async {
      bloc.add(const AreaOpened(AreaQuery()));
      await settle();
      final done = Completer<void>();
      bloc.add(AreaRefreshed(done: done));
      await done.future.timeout(const Duration(seconds: 2));
      expect(repo.calls[const AreaRef.national()], 2);
    },
  );

  test('a failed series with no copy is a failure state', () async {
    final failing = FakeCaseRepository();
    final b = AreaBloc(failing);
    b.add(const AreaOpened(AreaQuery(area: AreaRef.province('99'))));
    await settle();
    expect(b.state.failure!.kind, PicoFailureKind.notFound);
    expect(b.state.loading, isFalse);
    await b.close();
  });

  test('compare toggles without a request', () async {
    bloc.add(const AreaOpened(AreaQuery()));
    await settle();
    bloc.add(const AreaCompareToggled());
    await settle();
    expect(bloc.state.compare, isTrue);
    expect(repo.calls[const AreaRef.national()], 1);
  });
}
