import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/contact_mapper.dart';
import 'package:pico_data_impl/src/api/dates.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Hospital rows (C03). Coordinates of 0 or null are missing.
List<Hospital> hospitalsFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>())
    Hospital(
      id: _int(j['id']),
      code: '${j['hospital_code']}',
      name: j['name'] as String,
      address: cleanString(j['address']) ?? '',
      regencyCode: '${j['regency_id']}',
      location: _latLng(j['latitude'], j['longitude']),
      contacts: contactList(j['contacts']),
      beds: [
        for (final b
            in (j['beds'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          Bed(
            typeName: b['bed_type_name'] as String? ?? '',
            available: _int(b['available']),
            total: _int(b['total']),
          ),
      ],
      igdCount: _int(j['igd_count']),
    ),
];

LatLng? _latLng(Object? lat, Object? lng) {
  final la = (lat as num?)?.toDouble();
  final lo = (lng as num?)?.toDouble();
  if (la == null || lo == null || (la == 0 && lo == 0)) return null;
  return LatLng(la, lo);
}

/// Task forces grouped by kabupaten (C03).
List<TaskForceGroup> taskForcesFrom(List<dynamic> rows) => [
  for (final g in rows.cast<Map<String, dynamic>>())
    TaskForceGroup(
      regencyCode: '${g['regency_id']}',
      regencyName: g['regency_name'] as String,
      members: [
        for (final m
            in (g['task_forces'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          TaskForce(
            name: m['name'] as String,
            contacts: contactList(m['contacts']),
          ),
      ],
    ),
];

/// Vaccination sites (C03). `"NULL"` and blank text are null.
List<VaccineLocation> vaccineLocationsFrom(List<dynamic> rows) => [
  for (final j in rows.cast<Map<String, dynamic>>())
    VaccineLocation(
      name: j['name'] as String,
      address: cleanString(j['address']) ?? '',
      regencyCode: '${j['regency_id']}',
      hours: cleanString(j['operational_time']),
      firstDose: j['is_first_vaccination'] == true,
      secondDose: j['is_second_vaccination'] == true,
      dailyQuota: (j['daily_vaccination_quota'] as num?)?.toInt(),
      stockRemaining: (j['vaccination_stock_remaining'] as num?)?.toInt(),
      notes: cleanString(j['notes']),
    ),
];

/// Directory endpoints of C03.
class FacilitiesApi {
  /// Creates the API over [client].
  FacilitiesApi(this._client);

  final PicoApiClient _client;

  /// `GET /hospitals?load_all=true`.
  Future<Either<PicoFailure, List<Hospital>>> hospitals() =>
      _client.fetch(PicoEndpoints.hospitals);

  /// `GET /task-forces?load_all=true`.
  Future<Either<PicoFailure, List<TaskForceGroup>>> taskForces() =>
      _client.fetch(PicoEndpoints.taskForces);

  /// `GET /vaccination/locations?load_all=true`.
  Future<Either<PicoFailure, List<VaccineLocation>>> vaccineLocations() =>
      _client.fetch(PicoEndpoints.vaccineLocations);
}
