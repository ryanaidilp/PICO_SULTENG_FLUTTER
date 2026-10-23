import 'package:network_sdk_api/src/exception/http_exception.dart';
import 'package:network_sdk_api/src/request/http_request.dart';
import 'package:network_sdk_api/src/response/http_response.dart';

/// Interface for HTTP request/response interceptors.
///
/// Interceptors can modify requests before they are sent,
/// modify responses before they are returned, and handle errors.
abstract class const HttpInterceptor() {
  /// Called before a request is sent.
  ///
  /// Return a modified [HttpRequest] or the original.
  /// Throw an [HttpException] to abort the request.
  Future<HttpRequest> onRequest(HttpRequest request);

  /// Called after a response is received.
  ///
  /// Return a modified [HttpResponse] or the original.
  /// Throw an [HttpException] to trigger error handling.
  Future<HttpResponse> onResponse(HttpResponse response);

  /// Called when an error occurs.
  ///
  /// Return an [HttpException] (possibly modified) to continue error handling.
  /// Return an [HttpResponse] to recover from the error.
  Future<Object> onError(HttpException error);
}
