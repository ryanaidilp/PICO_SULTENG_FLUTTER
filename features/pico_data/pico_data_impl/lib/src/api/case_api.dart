import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoints.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';

/// The case endpoints of C02, mapped to domain models.
///
/// Always asks for full lists (`all=true`, `load_all=true`) and filters by
/// date on the device, so no date parameter is ever sent.
class CaseApi {
  /// Creates the API over [client].
  CaseApi(this._client);

  final PicoApiClient _client;

  /// `GET /national/latest`.
  Future<Either<PicoFailure, CaseDay>> nationalLatest() =>
      _client.fetch(PicoEndpoints.nationalLatest);

  /// `GET /national?all=true`, ascending by date.
  Future<Either<PicoFailure, CaseSeries>> nationalSeries() =>
      _client.fetch(PicoEndpoints.nationalSeries);

  /// `GET /provinces`, the 34 provinces with their latest case.
  Future<Either<PicoFailure, List<AreaSummary>>> provinces() =>
      _client.fetch(PicoEndpoints.provinces);

  /// `GET /provinces/{id}/cases?all=true`, ascending by date.
  Future<Either<PicoFailure, CaseSeries>> provinceSeries(String id) =>
      _client.fetch(PicoEndpoints.provinceSeries(id));

  /// `GET /regencies?load_all=true`: codes and names of the 13 kabupaten.
  Future<Either<PicoFailure, List<Regency>>> regencies() =>
      _client.fetch(PicoEndpoints.regencies);

  /// `GET /regencies/{code}/cases`, all days, ascending by date.
  Future<Either<PicoFailure, CaseSeries>> regencySeries(String code) =>
      _client.fetch(PicoEndpoints.regencySeries(code));
}
