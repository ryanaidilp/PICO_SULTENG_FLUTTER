import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dependencies/network.dart';
import 'package:pico_data_api/pico_data_api.dart';

/// Body size above which JSON is decoded off the UI isolate (C05).
const int kIsolateDecodeThreshold = 100 * 1024;

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
    var result = await _once(path, query, unwrapPage);
    if (result.leftOrNull?.kind == PicoFailureKind.rateLimited) {
      await Future<void>.delayed(retryDelay);
      result = await _once(path, query, unwrapPage);
    }
    return result;
  }

  /// [getData] then [map]. A mapping error becomes [PicoFailureKind.server],
  /// never an exception.
  Future<Either<PicoFailure, T>> getMapped<T>(
    String path,
    T Function(Object? data) map, {
    Map<String, Object?>? query,
    bool unwrapPage = true,
  }) async {
    final r = await getData(path, query: query, unwrapPage: unwrapPage);
    return r.fold(Left.new, (data) {
      try {
        return Right(map(data));
      } on Object catch (e) {
        return Left(
          PicoFailure(PicoFailureKind.server, message: 'Bad data: $e'),
        );
      }
    });
  }

  Future<Either<PicoFailure, Object?>> _once(
    String path,
    Map<String, Object?>? query,
    bool unwrapPage,
  ) async {
    final Response<String> res;
    try {
      res = await _dio.get<String>(path, queryParameters: query);
    } on DioException catch (e) {
      return Left(_fromDio(e));
    }
    final failure = _fromStatus(res.statusCode ?? 0);
    if (failure != null) return Left(failure);

    final body = res.data ?? '';
    final Object? json;
    try {
      json = body.length > kIsolateDecodeThreshold
          ? await Isolate.run(() => jsonDecode(body))
          : jsonDecode(body);
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
