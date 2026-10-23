import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/case_mappers.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';

/// The case endpoints of C02, mapped to domain models.
///
/// Always asks for full lists (`all=true`, `load_all=true`) and filters by
/// date on the device, so no date parameter is ever sent.
class CaseApi {
  /// Creates the API over [client].
  new(this._client);

  final PicoApiClient _client;

  Either<PicoFailure, T> _guard<T>(T Function() f) {
    try {
      return Right(f());
    } on Object catch (e) {
      return Left(PicoFailure(PicoFailureKind.server, message: 'Bad data: $e'));
    }
  }

  Future<Either<PicoFailure, T>> _get<T>(
    String path,
    T Function(Object? data) map, {
    Map<String, Object?>? query,
  }) async => (await _client.getData(
    path,
    query: query,
  )).fold(Left.new, (data) => _guard(() => map(data)));

  /// `GET /national/latest`.
  Future<Either<PicoFailure, CaseDay>> nationalLatest() => _get(
    '/national/latest',
    (d) => caseDayFromNested(d! as Map<String, dynamic>),
  );

  /// `GET /national?all=true`, ascending by date.
  Future<Either<PicoFailure, CaseSeries>> nationalSeries() => _get(
    '/national',
    (d) => seriesFromNested(
      d! as List<dynamic>,
      area: const AreaRef.national(),
      fallbackName: 'Indonesia',
    ),
    query: {'all': true},
  );

  /// `GET /provinces`, the 34 provinces with their latest case.
  Future<Either<PicoFailure, List<AreaSummary>>> provinces() =>
      _get('/provinces', (d) => provinceSummaries(d! as List<dynamic>));

  /// `GET /provinces/{id}/cases?all=true`, ascending by date.
  Future<Either<PicoFailure, CaseSeries>> provinceSeries(String id) => _get(
    '/provinces/$id/cases',
    (d) => seriesFromNested(
      d! as List<dynamic>,
      area: AreaRef.province(id),
      fallbackName: id,
    ),
    query: {'all': true},
  );

  /// `GET /regencies?load_all=true`: codes and names of the 13 kabupaten.
  Future<Either<PicoFailure, List<({String code, String name})>>> regencies() =>
      _get(
        '/regencies',
        (d) => regencyList(d! as List<dynamic>),
        query: {'load_all': true},
      );

  /// `GET /regencies/{code}/cases`, all days, ascending by date.
  Future<Either<PicoFailure, CaseSeries>> regencySeries(String code) => _get(
    '/regencies/$code/cases',
    (d) => seriesFromRegency(d! as List<dynamic>, code: code),
  );
}
