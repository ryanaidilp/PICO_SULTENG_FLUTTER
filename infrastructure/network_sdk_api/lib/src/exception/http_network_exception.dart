part of 'http_exception.dart';

/// Exception thrown when a network connection fails.
final class const HttpNetworkException([String? message])
    extends HttpException {
  this : super(message ?? 'Network connection failed');

  @override
  String toString() => 'HttpNetworkException: $message';
}
