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
        // ODP and PDP exist only in the first 120 days; later rows have none.
        monitoring: i < 120
            ? const Monitoring(
                odpActive: 120,
                odpFinished: 800,
                pdpActive: 30,
                pdpFinished: 90,
              )
            : null,
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
  CountingCases(CaseSeries s, {super.provinces})
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

const _provinceNames = {
  '11': 'Aceh',
  '12': 'Sumatera Utara',
  '13': 'Sumatera Barat',
  '14': 'Riau',
  '15': 'Jambi',
  '16': 'Sumatera Selatan',
  '17': 'Bengkulu',
  '18': 'Lampung',
  '19': 'Kepulauan Bangka Belitung',
  '21': 'Kepulauan Riau',
  '31': 'DKI Jakarta',
  '32': 'Jawa Barat',
  '33': 'Jawa Tengah',
  '34': 'DI Yogyakarta',
  '35': 'Jawa Timur',
  '36': 'Banten',
  '51': 'Bali',
  '52': 'Nusa Tenggara Barat',
  '53': 'Nusa Tenggara Timur',
  '61': 'Kalimantan Barat',
  '62': 'Kalimantan Tengah',
  '63': 'Kalimantan Selatan',
  '64': 'Kalimantan Timur',
  '65': 'Kalimantan Utara',
  '71': 'Sulawesi Utara',
  '72': 'Sulawesi Tengah',
  '73': 'Sulawesi Selatan',
  '74': 'Sulawesi Tenggara',
  '75': 'Gorontalo',
  '76': 'Sulawesi Barat',
  '81': 'Maluku',
  '82': 'Maluku Utara',
  '91': 'Papua Barat',
  '94': 'Papua',
};

/// The 34 provinces, Aceh first (API order), cumulative positive by code.
Either<PicoFailure, DataSnapshot<List<AreaSummary>>> provinceSummaries() =>
    fakeSnapshot([
      for (final e in _provinceNames.entries)
        AreaSummary(
          area: AreaRef.province(e.key),
          name: e.value,
          latest: CaseDay(
            date: DateTime(2024, 1, 14),
            daily: CaseCounts.zero,
            cumulative: CaseCounts(
              positive: 1000 * int.parse(e.key),
              recovered: 900 * int.parse(e.key),
              deceased: 30,
              active: 0,
            ),
          ),
        ),
    ]);

/// A latest gender snapshot of Sulawesi Tengah (C03 fixture).
GenderSnapshot genderSnapshot() => const GenderSnapshot(
  sourceDay: 799,
  positive: GenderGroup(
    male: GenderCounts(
      total: 10199,
      ageGroups: {
        '0_14': 263,
        '15_19': 898,
        '20_24': 2888,
        '25_49': 3180,
        '50_54': 1978,
        '55_plus': 991,
      },
    ),
    female: GenderCounts(
      total: 12585,
      ageGroups: {
        '0_14': 324,
        '15_19': 1107,
        '20_24': 3564,
        '25_49': 3924,
        '50_54': 2441,
        '55_plus': 1223,
      },
    ),
  ),
  pdp: GenderGroup(
    male: GenderCounts(total: 178, ageGroups: {'0_14': 16}),
    female: GenderCounts(total: 112, ageGroups: {'0_14': 9}),
  ),
);
