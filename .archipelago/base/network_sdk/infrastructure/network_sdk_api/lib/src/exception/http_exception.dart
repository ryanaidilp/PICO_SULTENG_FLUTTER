library;

import 'package:dependencies_core/meta.dart';

part 'http_cancelled_exception.dart';
part 'http_network_exception.dart';
part 'http_parse_exception.dart';
part 'http_request_exception.dart';
part 'http_timeout_exception.dart';

/// Base exception for all HTTP-related errors.
@immutable
sealed class const HttpException(
  final String message, {
  final int? statusCode,
  final Object? data,
}) implements Exception {
  @override
  String toString() =>
      'HttpException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
