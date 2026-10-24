import 'package:dio/dio.dart' as dio;
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/src/conversions/dio_conversions.dart';

/// Adapts [api.HttpInterceptor] to Dio's [dio.Interceptor].
class DioInterceptorAdapter(final api.HttpInterceptor _interceptor)
    extends dio.Interceptor {
  /// The wrapped interceptor for comparison purposes.
  api.HttpInterceptor get interceptor => _interceptor;

  @override
  Future<void> onRequest(
    dio.RequestOptions options,
    dio.RequestInterceptorHandler handler,
  ) async {
    try {
      final request = _convertToHttpRequest(options);
      final modifiedRequest = await _interceptor.onRequest(request);
      final modifiedOptions = _convertToRequestOptions(
        modifiedRequest,
        options,
      );
      handler.next(modifiedOptions);
    } on api.HttpException catch (e) {
      handler.reject(
        dio.DioException(requestOptions: options, error: e, message: e.message),
      );
    }
  }

  @override
  Future<void> onResponse(
    dio.Response<dynamic> response,
    dio.ResponseInterceptorHandler handler,
  ) async {
    try {
      final httpResponse = DioConversions.toHttpResponse(response);
      final modifiedResponse = await _interceptor.onResponse(httpResponse);
      final modifiedDioResponse = DioConversions.toDioResponse(
        modifiedResponse,
        response,
      );
      handler.next(modifiedDioResponse);
    } on api.HttpException catch (e) {
      handler.reject(
        dio.DioException(
          requestOptions: response.requestOptions,
          error: e,
          message: e.message,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    dio.DioException err,
    dio.ErrorInterceptorHandler handler,
  ) async {
    final httpException = DioConversions.toHttpException(err);
    final result = await _interceptor.onError(httpException);

    if (result is api.HttpResponse) {
      handler.resolve(DioConversions.toDioResponse(result, err.response!));
    } else if (result is api.HttpException) {
      handler.reject(
        dio.DioException(
          requestOptions: err.requestOptions,
          error: result,
          message: result.message,
        ),
      );
    } else {
      handler.next(err);
    }
  }

  api.HttpRequest _convertToHttpRequest(dio.RequestOptions options) =>
      api.HttpRequest(
        method: _convertMethod(options.method),
        path: options.path,
        baseUrl: options.baseUrl,
        body: options.data,
        options: api.RequestOptions(
          headers: options.headers.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
          queryParameters: options.queryParameters,
          connectTimeout: options.connectTimeout,
          receiveTimeout: options.receiveTimeout,
          sendTimeout: options.sendTimeout,
          followRedirects: options.followRedirects,
          maxRedirects: options.maxRedirects,
          extra: options.extra,
        ),
      );

  dio.RequestOptions _convertToRequestOptions(
    api.HttpRequest request,
    dio.RequestOptions original,
  ) => original.copyWith(
    method: request.method.name.toUpperCase(),
    path: request.path,
    baseUrl: request.baseUrl ?? original.baseUrl,
    data: request.body,
    headers: request.options?.headers,
    queryParameters: request.options?.queryParameters,
    connectTimeout: request.options?.connectTimeout,
    receiveTimeout: request.options?.receiveTimeout,
    sendTimeout: request.options?.sendTimeout,
    followRedirects: request.options?.followRedirects ?? true,
    maxRedirects: request.options?.maxRedirects ?? 5,
    extra: request.options?.extra,
  );

  api.HttpMethod _convertMethod(String method) =>
      switch (method.toUpperCase()) {
        'GET' => api.HttpMethod.get,
        'POST' => api.HttpMethod.post,
        'PUT' => api.HttpMethod.put,
        'PATCH' => api.HttpMethod.patch,
        'DELETE' => api.HttpMethod.delete,
        'HEAD' => api.HttpMethod.head,
        'OPTIONS' => api.HttpMethod.options,
        _ => api.HttpMethod.get,
      };
}
