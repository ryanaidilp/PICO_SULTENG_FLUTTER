part of 'http_exception.dart';

/// Exception thrown when an HTTP request times out.
final class const HttpTimeoutException([String? message])
    extends HttpException {
  this : super(message ?? 'Request timed out');

  @override
  String toString() => 'HttpTimeoutException: $message';
}
