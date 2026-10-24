import 'package:network_sdk_api/src/interceptor/http_interceptor.dart';
import 'package:network_sdk_api/src/request/request_options.dart';
import 'package:network_sdk_api/src/response/http_response.dart';

/// Interface for HTTP clients.
///
/// Implementations should handle the actual HTTP communication
/// using libraries like Dio or http.
abstract interface class HttpClient() {
  /// Sends a GET request to the specified [path].
  Future<HttpResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
  });

  /// Sends a POST request to the specified [path].
  Future<HttpResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
  });

  /// Sends a PUT request to the specified [path].
  Future<HttpResponse> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
  });

  /// Sends a PATCH request to the specified [path].
  Future<HttpResponse> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
  });

  /// Sends a DELETE request to the specified [path].
  Future<HttpResponse> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
  });

  /// Adds an interceptor to the client.
  void addInterceptor(HttpInterceptor interceptor);

  /// Removes an interceptor from the client.
  void removeInterceptor(HttpInterceptor interceptor);

  /// Releases resources used by the client.
  void dispose();
}
