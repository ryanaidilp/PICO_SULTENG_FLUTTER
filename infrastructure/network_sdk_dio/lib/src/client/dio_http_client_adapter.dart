import 'package:dio/dio.dart' as dio;
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/src/conversions/dio_conversions.dart';
import 'package:network_sdk_dio/src/interceptor/dio_interceptor_adapter.dart';

/// Implements the vendor-agnostic [api.HttpClient] port over an injected
/// [dio.Dio] instance.
///
/// This is a façade, not a second transport: every request is issued
/// through [dio.Dio.request] (which itself calls [dio.Dio.fetch]) on the
/// SAME [dio.Dio] instance registered elsewhere in DI, so it shares that
/// instance's interceptor chain (auth, retry, logging, etc.) and connection
/// pool. Never construct a second [dio.Dio] inside this adapter.
///
/// Callers that depend on the [api.HttpClient] port never see a
/// [dio.DioException] — every failure surfaces as an [api.HttpException]
/// (see [DioConversions.toHttpException]).
///
/// Example usage in DI:
/// ```dart
/// @LazySingleton(as: HttpClient)
/// DioHttpClientAdapter apiHttpClient(Dio dio) => DioHttpClientAdapter(dio);
/// ```
class DioHttpClientAdapter(final dio.Dio _dio) implements api.HttpClient {
  @override
  Future<api.HttpResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    api.RequestOptions? options,
  }) => _send('GET', path, queryParameters: queryParameters, options: options);

  @override
  Future<api.HttpResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    api.RequestOptions? options,
  }) => _send(
    'POST',
    path,
    body: body,
    queryParameters: queryParameters,
    options: options,
  );

  @override
  Future<api.HttpResponse> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    api.RequestOptions? options,
  }) => _send(
    'PUT',
    path,
    body: body,
    queryParameters: queryParameters,
    options: options,
  );

  @override
  Future<api.HttpResponse> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    api.RequestOptions? options,
  }) => _send(
    'PATCH',
    path,
    body: body,
    queryParameters: queryParameters,
    options: options,
  );

  @override
  Future<api.HttpResponse> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    api.RequestOptions? options,
  }) => _send(
    'DELETE',
    path,
    body: body,
    queryParameters: queryParameters,
    options: options,
  );

  @override
  void addInterceptor(api.HttpInterceptor interceptor) {
    _dio.interceptors.add(DioInterceptorAdapter(interceptor));
  }

  @override
  void removeInterceptor(api.HttpInterceptor interceptor) {
    _dio.interceptors.removeWhere(
      (i) => i is DioInterceptorAdapter && i.interceptor == interceptor,
    );
  }

  @override
  void dispose() => _dio.close();

  Future<api.HttpResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    api.RequestOptions? options,
  }) async {
    // One Dio token per request, bridged from the caller's token and
    // detached when the request settles. An already-cancelled token cancels
    // it at once, and Dio then throws before reaching the transport.
    final token = options?.cancelToken;
    final dioToken = token == null ? null : dio.CancelToken();
    final detach = token?.onCancel(() => dioToken!.cancel(token.reason));
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        cancelToken: dioToken,
        options: DioConversions.toDioOptions(method, options),
      );
      return DioConversions.toHttpResponse(response);
    } on dio.DioException catch (e) {
      throw DioConversions.toHttpException(e);
    } finally {
      detach?.call();
    }
  }
}
