import 'package:dependencies_core/meta.dart';

/// A functional programming type that represents values with two possibilities:
/// a value of type [Left] or a value of type [Right].
///
/// By convention, [Left] is used for error cases and [Right] for success cases.
@immutable
sealed class const Either<L, R>() {
  /// Returns true if this is a [Right] instance.
  bool get isRight => this is Right<L, R>;

  /// Returns true if this is a [Left] instance.
  bool get isLeft => this is Left<L, R>;

  /// Transforms the [Right] value using the provided function.
  /// If this is a [Left], returns the same [Left] unchanged.
  Either<L, T> map<T>(T Function(R value) f) => switch (this) {
    final Left<L, R> left => Left(left.value),
    final Right<L, R> right => Right(f(right.value)),
  };

  /// Transforms the [Left] value using the provided function.
  /// If this is a [Right], returns the same [Right] unchanged.
  Either<T, R> mapLeft<T>(T Function(L value) f) => switch (this) {
    final Left<L, R> left => Left(f(left.value)),
    final Right<L, R> right => Right(right.value),
  };

  /// Executes one of the provided functions based on the type.
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      switch (this) {
        final Left<L, R> left => onLeft(left.value),
        final Right<L, R> right => onRight(right.value),
      };

  /// Returns the [Right] value or null if this is a [Left].
  R? get rightOrNull => switch (this) {
    Left<L, R>() => null,
    final Right<L, R> right => right.value,
  };

  /// Returns the [Left] value or null if this is a [Right].
  L? get leftOrNull => switch (this) {
    final Left<L, R> left => left.value,
    Right<L, R>() => null,
  };

  /// Returns the [Right] value or throws if this is a [Left].
  R get right => switch (this) {
    final Left<L, R> left => throw StateError('Called right on Left($left)'),
    final Right<L, R> right => right.value,
  };

  /// Returns the [Left] value or throws if this is a [Right].
  L get left => switch (this) {
    final Left<L, R> left => left.value,
    final Right<L, R> right => throw StateError('Called left on Right($right)'),
  };
}

/// Represents the left side of [Either], typically used for error cases.
@immutable
final class const Left<L, R>(final L value) extends Either<L, R> {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Left<L, R> && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

/// Represents the right side of [Either], typically used for success cases.
@immutable
final class const Right<L, R>(final R value) extends Either<L, R> {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Right<L, R> && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}
