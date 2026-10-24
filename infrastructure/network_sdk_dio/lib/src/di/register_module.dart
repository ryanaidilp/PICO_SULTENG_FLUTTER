import 'package:app_config/app_config.dart';
import 'package:dependencies/di.dart';
import 'package:dio/dio.dart';
import 'package:network_sdk_dio/network_sdk_dio.dart';

/// Resolves the app's [AuthTokenProvider] from the global service locator,
/// or `null` when no auth feature is installed.
///
/// Deliberately **not** a constructor-injected dependency of the [Dio]
/// registration below:
///
/// - `AuthTokenProvider` is optional. A project can install a network SDK
///   and no auth feature, and `gh<AuthTokenProvider>()` would throw at Dio
///   construction time in exactly that case.
/// - Resolving it eagerly would close the DI cycle `LoginRepository -> Dio
///   -> AuthTokenProvider -> AuthSDK -> LoginRepository`.
/// - It removes any ordering requirement between the network module and the
///   auth module, which are registered independently by two different
///   bricks.
///
/// The lookup is a map probe per request; nothing is memoized, so a provider
/// registered after the first request (or replaced between tests) is still
/// picked up.
AuthTokenProvider? resolveAuthTokenProvider() =>
    GetIt.instance.isRegistered<AuthTokenProvider>()
    ? GetIt.instance<AuthTokenProvider>()
    : null;

/// DI module for network_sdk_dio.
///
/// Registers [DioHttpClient] as [Dio] lazy singleton, and [DioHttpClientAdapter]
/// as the vendor-agnostic [HttpClient] port.
///
/// Since [DioHttpClient] extends [DioMixin], it can be used as [Dio] directly.
/// Services can depend on [Dio] type and receive the configured client.
///
/// Example usage in a service:
/// ```dart
/// class ApiService {
///   ApiService(Dio dio) : _dio = dio;
///   final Dio _dio;
///
///   Future<Response> fetchData() => _dio.get('/data');
/// }
/// ```
///
/// The [DioConfig] can be customized via your app's DI module by providing
/// a custom [DioHttpClient] registration that overrides this one.
@module
abstract class RegisterModule() {
  /// Provides [DioHttpClient] as [Dio] lazy singleton.
  ///
  /// [DioConfig.baseUrl] is sourced from [AppEnv.apiBaseUrl] (populated from
  /// the active flavor's `.env` file — see `shared/app_config`). Override in
  /// your app's DI module for custom configuration.
  ///
  /// The client is wired to [resolveAuthTokenProvider], which installs an
  /// [AuthInterceptor] that attaches the session bearer and renews it once
  /// on a `401`. An app that overrides this registration with its own [Dio]
  /// must pass the same resolver (or add [AuthInterceptor] itself) or it
  /// silently opts out of the whole refresh lifecycle.
  @LazySingleton(as: Dio)
  DioHttpClient httpClient() => DioHttpClient.init(
    config: DioConfig(baseUrl: AppEnv.apiBaseUrl),
    authTokenProvider: resolveAuthTokenProvider,
  );

  /// Provides [DioHttpClientAdapter] as the vendor-agnostic [HttpClient] port.
  ///
  /// This is a façade over the [Dio] singleton above, never a second
  /// transport: requests made through the [HttpClient] port traverse the
  /// same interceptor chain and connection pool as a direct [Dio] call.
  @LazySingleton(as: HttpClient)
  DioHttpClientAdapter apiHttpClient(Dio dio) => DioHttpClientAdapter(dio);
}
