import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dependencies/network.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/endpoint.dart';

/// Body size above which JSON is decoded off the UI isolate (C05).
const int kIsolateDecodeThreshold = 100 * 1024;

/// A response body with its validator.
final class FetchedBody {
  /// Creates a fetched body.
  const new(this.body, {this.etag, this.notModified = false});

  /// The raw text (empty for a 304).
  final String body;

  /// The `ETag` header, when the API sends one.
  final String? etag;

  /// The server answered 304: the saved copy is still current.
  final bool notModified;
}

/// Reads the PICO API (C01): envelope, failure mapping, one retry on 429.
///
/// Only plain `YYYY-MM-DD` dates and `all=true` / `load_all=true` are ever
/// sent. The client never sends ISO datetimes or `sort`, and does not rely on
/// API behaviour that is not deployed yet (gzip, `include_latest_case`,
/// province sort, 400 and 404 changes).
class PicoApiClient {
  /// Creates a client over [dio]. [retryDelay] is the wait before the single
  /// retry after HTTP 429.
  new(this._dio, {this.retryDelay = const Duration(seconds: 2)});

  /// Builds a client for [baseUrl] with the C01 timeouts and User-Agent.
  factory create({
    required String baseUrl,
    required String userAgent,
    HttpClientAdapter? adapter,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.plain,
        headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
        // Status codes are mapped here, not thrown by dio.
        validateStatus: (_) => true,
      ),
    );
    if (adapter != null) dio.httpClientAdapter = adapter;
    return PicoApiClient(dio, retryDelay: retryDelay);
  }

  final Dio _dio;

  /// Wait before the retry after HTTP 429.
  final Duration retryDelay;

  /// GETs [path] and returns the envelope `data`, or a [PicoFailure].
  ///
  /// A paginated payload (`{"data": [...], "pagination": ...}`) is unwrapped
  /// to its list.
  ///
  /// With [unwrapPage] false the paginated map is returned whole, for callers
  /// that need `pagination.has_next`.
  Future<Either<PicoFailure, Object?>> getData(
    String path, {
    Map<String, Object?>? query,
    bool unwrapPage = true,
  }) async {
    final body = await getBody(path, query: query);
    return switch (body) {
      Left(:final value) => Left(value),
      Right(:final value) => decode(value, unwrapPage: unwrapPage),
    };
  }

  /// [getData] then [map]. A mapping error becomes [PicoFailureKind.server],
  /// never an exception.
  Future<Either<PicoFailure, T>> getMapped<T>(
    String path,
    T Function(Object? data) map, {
    Map<String, Object?>? query,
    bool unwrapPage = true,
  }) async => (await getData(
    path,
    query: query,
    unwrapPage: unwrapPage,
  )).fold(Left.new, (data) => _mapGuard(data, map));

  /// Fetches an [Endpoint] and maps it.
  Future<Either<PicoFailure, T>> fetch<T>(Endpoint<T> endpoint) => getMapped(
    endpoint.path,
    endpoint.map,
    query: endpoint.query,
    unwrapPage: endpoint.unwrapPage,
  );

  /// Decodes a stored or fresh body and maps it with [endpoint].
  ///
  /// A body over 100 KB is decoded AND mapped in one isolate: only the typed
  /// result comes back, so the UI isolate never walks the generic JSON graph.
  Future<Either<PicoFailure, T>> parse<T>(
    Endpoint<T> endpoint,
    String body,
  ) async {
    if (body.length <= kIsolateDecodeThreshold) {
      return _decodeAndMap(body, endpoint.unwrapPage, endpoint.map);
    }
    final map = endpoint.map;
    final unwrap = endpoint.unwrapPage;
    return Isolate.run(() => _decodeAndMap(body, unwrap, map));
  }

  Either<PicoFailure, T> _mapGuard<T>(
    Object? data,
    T Function(Object? data) map,
  ) {
    try {
      return Right(map(data));
    } on Object catch (e) {
      return Left(PicoFailure(PicoFailureKind.server, message: 'Bad data: $e'));
    }
  }

  /// GETs [path] and returns the raw response body (HTTP status mapped, one
  /// retry after 429). The body is what the snapshot store keeps, so network
  /// and cache parse the same text.
  Future<Either<PicoFailure, String>> getBody(
    String path, {
    Map<String, Object?>? query,
  }) async => (await fetchBody(
    path,
    query: query,
  )).fold(Left.new, (f) => Right(f.body));

  /// Like [getBody], with the `ETag` of the answer. With [ifNoneMatch] a
  /// `304` comes back as [FetchedBody.notModified] (an empty body).
  Future<Either<PicoFailure, FetchedBody>> fetchBody(
    String path, {
    Map<String, Object?>? query,
    String? ifNoneMatch,
  }) async {
    var result = await _once(path, query, ifNoneMatch);
    if (result.leftOrNull?.kind == PicoFailureKind.rateLimited) {
      await Future<void>.delayed(retryDelay);
      result = await _once(path, query, ifNoneMatch);
    }
    return result;
  }

  Future<Either<PicoFailure, FetchedBody>> _once(
    String path,
    Map<String, Object?>? query,
    String? ifNoneMatch,
  ) async {
    final Response<String> res;
    try {
      res = await _dio.get<String>(
        path,
        queryParameters: query,
        options: ifNoneMatch == null
            ? null
            : Options(headers: {'If-None-Match': ifNoneMatch}),
      );
    } on DioException catch (e) {
      return Left(_fromDio(e));
    }
    final status = res.statusCode ?? 0;
    if (status == 304 && ifNoneMatch != null) {
      return Right(FetchedBody('', etag: ifNoneMatch, notModified: true));
    }
    final failure = _fromStatus(status);
    if (failure != null) return Left(failure);
    return Right(FetchedBody(res.data ?? '', etag: res.headers.value('etag')));
  }

  /// Decodes a body and checks the envelope. Bodies over 100 KB decode in an
  /// isolate. A paginated payload is unwrapped to its list unless
  /// [unwrapPage] is false.
  Future<Either<PicoFailure, Object?>> decode(
    String body, {
    bool unwrapPage = true,
  }) async => body.length > kIsolateDecodeThreshold
      ? Isolate.run(() => decodeEnvelope(body, unwrapPage: unwrapPage))
      : decodeEnvelope(body, unwrapPage: unwrapPage);

  PicoFailure? _fromStatus(int status) {
    if (status >= 200 && status < 300) return null;
    final kind = switch (status) {
      404 => PicoFailureKind.notFound,
      429 => PicoFailureKind.rateLimited,
      400 => PicoFailureKind.badRequest,
      _ => PicoFailureKind.server,
    };
    return PicoFailure(kind, message: 'HTTP $status');
  }

  PicoFailure _fromDio(DioException e) => PicoFailure(
    e.type == DioExceptionType.badResponse
        ? PicoFailureKind.server
        : PicoFailureKind.network,
    message: e.message ?? e.type.name,
  );
}

/// Decodes [body], checks the C01 envelope and returns its `data`. Pure and
/// synchronous, so it can run in any isolate.
Either<PicoFailure, Object?> decodeEnvelope(
  String body, {
  bool unwrapPage = true,
}) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return const Left(
      PicoFailure(PicoFailureKind.server, message: 'Response is not JSON'),
    );
  }
  if (json is! Map<String, dynamic> || json['status'] != 'success') {
    return Left(
      PicoFailure(
        PicoFailureKind.server,
        message: json is Map ? '${json['error']}' : 'Unexpected response',
      ),
    );
  }
  var data = json['data'];
  if (unwrapPage &&
      data is Map<String, dynamic> &&
      data['data'] is List &&
      data.containsKey('pagination')) {
    data = data['data'];
  }
  return Right(data);
}

/// [decodeEnvelope] then [map]. A mapping error becomes
/// [PicoFailureKind.server], never an exception.
Either<PicoFailure, T> _decodeAndMap<T>(
  String body,
  bool unwrapPage,
  T Function(Object? data) map,
) {
  final decoded = decodeEnvelope(body, unwrapPage: unwrapPage);
  if (decoded.isLeft) return Left(decoded.left);
  try {
    return Right(map(decoded.right));
  } on Object catch (e) {
    return Left(PicoFailure(PicoFailureKind.server, message: 'Bad data: $e'));
  }
}
