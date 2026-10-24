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
