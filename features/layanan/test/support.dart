import 'package:pico_data_api/pico_data_api.dart';

/// Hospital 19 of the C03 fixture: 3 bed types, 3 phone contacts, coordinates.
final sindhu = Hospital(
  id: 19,
  code: '7271025',
  name: 'RS Tk.III 14.06.01 Dr. Sindhu Trisno',
  address:
      'Jl. Sisingamangaraja No.4, Besusu Tim., Kec. Palu Tim., Kota Palu, '
      'Sulawesi Tengah 94118',
  regencyCode: '7271',
  location: const LatLng(-0.8959781, 119.8874783),
  contacts: [
    Contact(
      kind: ContactKind.phone,
      label: 'Telepon',
      value: '081213756763',
      uri: Uri(scheme: 'tel', path: '081213756763'),
    ),
    Contact(
      kind: ContactKind.phone,
      label: 'Telepon',
      value: '085256394088',
      uri: Uri(scheme: 'tel', path: '085256394088'),
    ),
    Contact(
      kind: ContactKind.phone,
      label: 'Telepon',
      value: '0451411903',
      uri: Uri(scheme: 'tel', path: '0451411903'),
    ),
  ],
  beds: const [
    Bed(typeName: 'IGD Khusus Covid', available: 2, total: 2),
    Bed(typeName: 'Isolasi Tanpa Tekanan Negatif', available: 16, total: 22),
    Bed(
      typeName: 'ICU Tekanan Negatif tanpa Ventilator',
      available: 3,
      total: 4,
    ),
  ],
  igdCount: 2,
);

/// A hospital with no coordinates, no beds and no contacts.
const noCoords = Hospital(
  id: 2,
  code: '7205001',
  name: 'RSUD Mokopido Tolitoli',
  address: 'Jl. Dr. Moh. Hatta, Tolitoli',
  regencyCode: '7208',
  contacts: [],
  beds: [],
  igdCount: 0,
);

/// Accented name to prove folding.
const accented = Hospital(
  id: 3,
  code: '7202010',
  name: 'RSUD Luwuk Pétra',
  address: '',
  regencyCode: '7201',
  contacts: [],
  beds: [Bed(typeName: 'Isolasi', available: 0, total: 0)],
  igdCount: 1,
);

const regencies = [
  Regency(code: '7201', name: 'Banggai Kepulauan'),
  Regency(code: '7208', name: 'Tolitoli'),
  Regency(code: '7271', name: 'Kota Palu'),
];

final all = [sindhu, noCoords, accented];

Contact _phone(String v) => Contact(
  kind: ContactKind.phone,
  label: 'Telepon',
  value: v,
  uri: Uri(scheme: 'tel', path: v),
);

/// Banggai with 2 members (C03 fixture) and a second group.
final taskForces = [
  TaskForceGroup(
    regencyCode: '7202',
    regencyName: 'Banggai',
    members: [
      TaskForce(
        name: 'dr. Anang (Kepala Dinkes Banggai)',
        contacts: [_phone('081241415651')],
      ),
      TaskForce(
        name: 'Ibu Nur Datu Adam (Jubir)',
        contacts: [_phone('085281691921')],
      ),
    ],
  ),
  TaskForceGroup(
    regencyCode: '7271',
    regencyName: 'Kota Palu',
    members: [
      TaskForce(name: 'Pak Budi', contacts: [_phone('0451111')]),
    ],
  ),
];

/// Donation 2 of the fixture: image on a dead host, one account with spaces.
final donation = Donation(
  id: 2,
  title: 'Untuk Kawan Baik',
  initiator: '@yaumilmasri',
  url: Uri.parse('https://www.instagram.com/yaumilmasri/'),
  description: 'Teman-teman saya di Palu banyak yang Isoman.',
  imageUrl: 'https://banuacoders.com/storage/donations/a.jpg',
  acceptsGoods: true,
  deliveryAddress: 'Jl. Ki Hajar No. 76A, Kota Palu',
  accounts: const [
    BankAccount(
      bankName: 'BCA',
      accountNumber: '7921 0246 85',
      accountHolder: 'Yaumil',
      logoUrl: 'https://banuacoders.com/logo.png',
    ),
  ],
  contacts: [
    _phone('085256087018'),
    const Contact(
      kind: ContactKind.telegram,
      label: 'Telegram',
      value: 'evansevansevans',
    ),
  ],
);

final doctors = [
  Telemedicine(
    id: 1,
    name: 'dr. Evans Suryani',
    isFree: true,
    schedules: const [
      Schedule(days: 'Senin-Jumat', time: '07:00-20:00', timezone: 'WIB'),
    ],
    contacts: [
      Contact(
        kind: ContactKind.telegram,
        label: 'Telegram',
        value: 'evansevansevans',
        uri: Uri.parse('https://t.me/evansevansevans'),
      ),
    ],
  ),
  const Telemedicine(
    id: 2,
    name: 'dr. Berbayar',
    isFree: false,
    schedules: [],
    contacts: [],
  ),
];
