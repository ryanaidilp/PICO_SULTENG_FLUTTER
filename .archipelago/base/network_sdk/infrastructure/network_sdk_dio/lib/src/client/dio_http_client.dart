import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:network_sdk_api/network_sdk_api.dart' as api;
import 'package:network_sdk_dio/src/config/dio_config.dart';
import 'package:network_sdk_dio/src/interceptor/auth_interceptor.dart';
import 'package:network_sdk_dio/src/interceptor/dio_interceptor_adapter.dart';

/// Dio-based HTTP client that extends `DioMixin`.
///
/// This allows the client to be registered as `Dio` in DI,
/// giving services direct access to full Dio API.
///
/// Example usage:
/// ```dart
/// // In DI module
/// @lazySingleton
/// DioHttpClient httpClient() => DioHttpClient.init(
///   config: DioConfig(baseUrl: Env.apiBaseUrl),
/// );
///
/// // In service - can receive as Dio
/// class MyService {
///   MyService(Dio dio) : _dio = dio;
///   final Dio _dio;
/// }
/// ```
class DioHttpClient._({
  DioConfig config = const DioConfig(),
  api.AuthTokenProvider? Function()? authTokenProvider,
}) extends DioMixin {
  this {
    options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      contentType: config.contentType,
      followRedirects: config.followRedirects,
      maxRedirects: config.maxRedirects,
      headers: config.headers,
    );

    httpClientAdapter = IOHttpClientAdapter();

    // The auth interceptor goes first: it must attach the bearer before any
    // logging interceptor renders the request, and it must get first refusal
    // on a 401 so a recovered request never looks like a failure to anything
    // downstream.
    if (authTokenProvider != null) {
      interceptors.add(AuthInterceptor(this, authTokenProvider));
    }

    // Add default interceptors
    interceptors.addAll(_defaultInterceptors);

    // Vendor-native interceptors (e.g. the debug network inspector's Alice
    // adapter) arrive through the port, in any order relative to this client.
    api.NetworkInterceptorRegistry.instance.listen((interceptor) {
      if (interceptor is Interceptor) interceptors.add(interceptor);
    });
  }

  /// Creates a new [DioHttpClient] with the given [config].
  ///
  /// [authTokenProvider] resolves the app's [api.AuthTokenProvider], or
  /// returns `null` when no auth feature is installed. It is a *resolver*
  /// rather than an instance so that the lookup happens on the first request
  /// instead of during DI registration — see [AuthInterceptor] for why that
  /// matters. Passing `null` installs no auth interceptor at all.
  // ignore: prefer_constructors_over_static_methods
  static DioHttpClient init({
    DioConfig config = const DioConfig(),
    api.AuthTokenProvider? Function()? authTokenProvider,
  }) => DioHttpClient._(config: config, authTokenProvider: authTokenProvider);

  /// Default interceptors applied in debug mode.
  static List<Interceptor> get _defaultInterceptors => [
    if (kDebugMode)
      LogInterceptor(request: false, requestBody: true, responseBody: true),
  ];

  /// Adds an [api.HttpInterceptor] by wrapping it with [DioInterceptorAdapter].
  void addHttpInterceptor(api.HttpInterceptor interceptor) {
    interceptors.add(DioInterceptorAdapter(interceptor));
  }

  /// Removes an [api.HttpInterceptor].
  void removeHttpInterceptor(api.HttpInterceptor interceptor) {
    interceptors.removeWhere(
      (i) => i is DioInterceptorAdapter && i.interceptor == interceptor,
    );
  }
}
