import 'package:pico_data_api/pico_data_api.dart';

DoseStats doses(
  int d1,
  int d2,
  double c1,
  double c2, {
  int dd1 = 0,
  int dd2 = 0,
}) => DoseStats(
  dailyDose1: dd1,
  dailyDose2: dd2,
  cumulativeDose1: d1,
  cumulativeDose2: d2,
  coverageDose1: c1,
  coverageDose2: c2,
);

/// The Sulteng row of 2021-05-04 as the API sent it (C03 fixture values).
VaccinationDay sultengDay(DateTime date, {int scale = 1}) => VaccinationDay(
  date: date,
  target: 2240548,
  total: doses(81885 * scale, 61974 * scale, 3.65, 2.77),
  groups: {
    VaccineGroup.elderly: GroupStats(
      target: 25292,
      doses: doses(6084, 3790, 24.06, 14.98),
    ),
    VaccineGroup.healthWorker: GroupStats(
      target: 24698,
      doses: doses(24788, 23075, 100.36, 93.43),
    ),
    VaccineGroup.publik: GroupStats(target: 1374811, doses: doses(0, 0, 0, 0)),
    VaccineGroup.publicOfficer: GroupStats(
      target: 65471,
      doses: doses(51013, 35109, 77.92, 53.63),
    ),
    VaccineGroup.teenager: GroupStats(target: 0, doses: doses(0, 0, 0, 0)),
  },
);

VaccinationSeries sultengSeries() => VaccinationSeries.fromDays(
  VaccinationScope.sulteng,
  [sultengDay(DateTime(2021, 4, 4)), sultengDay(DateTime(2021, 5, 4))],
);

VaccinationSeries nationalSeries() =>
    VaccinationSeries.fromDays(VaccinationScope.national, [
      VaccinationDay(
        date: DateTime(2021, 2),
        target: 208265720,
        total: doses(1000, 0, 0.01, 0),
        groups: {
          VaccineGroup.healthWorker: GroupStats(
            target: 1468764,
            doses: doses(0, 0, 0, 0),
          ),
        },
      ),
    ]);

const regencies = [
  Regency(code: '7202', name: 'Banggai'),
  Regency(code: '7271', name: 'Kota Palu'),
];

const mapolda = VaccineLocation(
  name: 'Gerai Vaksinasi Presisi Mapolda',
  address: 'Jl. Soekarno-Hatta, Palu',
  regencyCode: '7271',
  hours: '08:00 - 12:00',
  firstDose: true,
  secondDose: false,
);

const withQuota = VaccineLocation(
  name: 'Puskesmas Kamonji',
  address: 'Jl. Kamonji',
  regencyCode: '7202',
  firstDose: true,
  secondDose: true,
  dailyQuota: 120,
  stockRemaining: 35,
  notes: 'Bawa KTP',
);
