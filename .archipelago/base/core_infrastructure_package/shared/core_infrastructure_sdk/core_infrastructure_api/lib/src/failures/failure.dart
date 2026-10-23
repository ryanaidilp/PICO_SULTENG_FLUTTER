import 'package:dependencies_core/meta.dart';

/// Standard failure class for handling errors in clean architecture.
/// Provides consistent error handling across the entire application.
@immutable
class const Failure({required final String message, final int? errno}) {
  factory fromJson(Map<String, dynamic> json) => Failure(
    message: json['message'] as String? ?? json['error'] as String? ?? '',
    errno: json['errno'] as int,
  );

  @override
  int get hashCode => message.hashCode ^ errno.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure && message == other.message && errno == other.errno;

  Failure copyWith({String? message}) =>
      Failure(message: message ?? this.message);

  Map<String, dynamic> toJson() => {'message': message};

  @override
  String toString() => 'Failure(message: $message, errno: $errno)';
}
