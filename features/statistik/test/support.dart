import 'dart:math' as math;

import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_api/testing.dart';

/// Sulteng-like series from 2020-03-02 to 2024-01-14 with the real 2021-07-15
/// day: 308 new positive, 93 recovered, 7 deceased, 208 active.
CaseSeries sultengSeries({AreaRef area = const AreaRef.province('72')}) {
  final days = <CaseDay>[];
  var cumPos = 0;
  var cumRec = 0;
  var cumDec = 0;
  for (var i = 0; i < 1414; i++) {
    final date = DateTime(2020, 3, 2 + i);
    final isFixtureDay = date == DateTime(2021, 7, 15);
    final pos = isFixtureDay
        ? 308
        : (60 * math.exp(-math.pow((i - 700) / 90, 2))).round();
    final rec = isFixtureDay ? 93 : (pos * .8).round();
    final dec = isFixtureDay ? 7 : (pos * .03).round();
    // A negative daily active on 2021-08-01 (more recoveries than cases).
    final negative = date == DateTime(2021, 8, 1);
    final r = negative ? 40 : rec;
    cumPos += pos;
    cumRec += r;
    cumDec += dec;
    days.add(
      CaseDay(
        date: date,
        daily: CaseCounts(
          positive: pos,
          recovered: r,
          deceased: dec,
          active: pos - r - dec,
        ),
        cumulative: CaseCounts(
          positive: cumPos,
          recovered: cumRec,
          deceased: cumDec,
          active: cumPos - cumRec - cumDec,
        ),
      ),
    );
  }
  return CaseSeries.fromDays(
    area: area,
    areaName: 'Sulawesi Tengah',
    days: days,
  );
}

/// Counts `watchSeries` calls per area.
class CountingCases extends FakeCaseRepository {
  CountingCases(CaseSeries s)
    : super(
        series: {
          s.area: s,
          const AreaRef.national(): CaseSeries.fromDays(
            area: const AreaRef.national(),
            areaName: 'Indonesia',
            days: s.days,
          ),
        },
      );

  final Map<AreaRef, int> calls = {};

  @override
  Watch<CaseSeries> watchSeries(AreaRef area, {bool forceRefresh = false}) {
    calls[area] = (calls[area] ?? 0) + 1;
    return super.watchSeries(area, forceRefresh: forceRefresh);
  }
}
