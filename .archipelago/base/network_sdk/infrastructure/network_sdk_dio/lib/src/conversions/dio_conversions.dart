import 'package:dio/dio.dart' as dio;
import 'package:network_sdk_api/network_sdk_api.dart' as api;

/// Shared conversion helpers between Dio's types and the vendor-agnostic
/// `network_sdk_api` types.
///
/// Used by both [api.HttpInterceptor] adaptation (`DioInterceptorAdapter`)
/// and the [api.HttpClient] port implementation (`DioHttpClientAdapter`) so
/// the two conversion paths can never drift from each other.
abstract final class DioConversions() {
  /// Converts a Dio [dio.Response] into a vendor-agnostic [api.HttpResponse].
  static api.HttpResponse toHttpResponse(dio.Response<dynamic> response) =>
      api.HttpResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        headers: response.headers.map.map(
          (key, value) => MapEntry(key, value.join(', ')),
        ),
        statusMessage: response.statusMessage,
      );

  /// Converts a vendor-agnostic [api.HttpResponse] back into a Dio
  /// [dio.Response], reusing [original]'s `requestOptions`.
  static dio.Response<dynamic> toDioResponse(
    api.HttpResponse response,
    dio.Response<dynamic> original,
  ) => dio.Response<dynamic>(
    requestOptions: original.requestOptions,
    statusCode: response.statusCode,
    data: response.data,
    headers: dio.Headers.fromMap(
      response.headers.map((key, value) => MapEntry(key, [value])),
    ),
    statusMessage: response.statusMessage,
  );

  /// Converts a [dio.DioException] into a vendor-agnostic [api.HttpException].
  ///
  /// Prefers an already-wrapped [api.HttpException] carried in
  /// [dio.DioException.error] — produced by `DioInterceptorAdapter`'s reject
  /// path (`onRequest`/`onResponse`/`onError`) whenever an interceptor throws
  /// or returns an [api.HttpException] — over re-deriving one from
  /// [dio.DioException.type], which collapses to
  /// [dio.DioExceptionType.unknown] for interceptor-rejected errors and would
  /// lose the original status code and exception subtype.
  static api.HttpException toHttpException(dio.DioException error) {
    final wrapped = error.error;
    if (wrapped is api.HttpException) {
      return wrapped;
    }

    return switch (error.type) {
      dio.DioExceptionType.connectionTimeout ||
      dio.DioExceptionType.sendTimeout ||
      dio.DioExceptionType.receiveTimeout ||
      dio.DioExceptionType.transformTimeout => api.HttpTimeoutException(
        error.message,
      ),
      dio.DioExceptionType.cancel => api.HttpCancelledException(error.message),
      dio.DioExceptionType.connectionError => api.HttpNetworkException(
        error.message,
      ),
      dio.DioExceptionType.badResponse => api.HttpRequestException(
        error.message ?? 'Request failed',
        statusCode: error.response?.statusCode,
        data: error.response?.data,
      ),
      // Catch-all covering dio.DioExceptionType.badCertificate,
      // dio.DioExceptionType.unknown, and any value a future dio release
      // adds to the enum. Deliberately NOT listed alongside a wildcard
      // (an exhaustive switch with every current member spelled out plus
      // `_` makes the wildcard dead code and trips `unreachable_switch_case`)
      // — folding them into the wildcard keeps it genuinely reachable today
      // while still absorbing tomorrow's additions instead of breaking
      // every generated project's compile step again.
      _ => api.HttpRequestException(
        error.message ?? 'Unknown error',
        data: error.error,
      ),
    };
  }

  /// Builds a Dio [dio.Options] for an outbound request from an
  /// [api.RequestOptions], carrying the HTTP [method].
  static dio.Options toDioOptions(String method, api.RequestOptions? options) =>
      dio.Options(
        method: method,
        headers: options?.headers,
        extra: options?.extra,
        connectTimeout: options?.connectTimeout,
        receiveTimeout: options?.receiveTimeout,
        sendTimeout: options?.sendTimeout,
        followRedirects: options?.followRedirects ?? true,
        maxRedirects: options?.maxRedirects ?? 5,
      );
}
