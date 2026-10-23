import 'package:core_infrastructure_api/core_infrastructure_api.dart';
import 'package:dependencies_core/equality.dart';

/// Where a [DataSnapshot] came from.
enum DataSource {
  /// Fresh from the API.
  network,

  /// From the offline snapshot store.
  cache,
}

/// Data with the facts the "Data per ..." stamp needs.
final class DataSnapshot<T> extends Equatable {
  /// Creates a snapshot.
  const new({
    required this.data,
    required this.fetchedAt,
    required this.source,
    this.isStale = false,
  });

  /// The data.
  final T data;

  /// When this copy came from the network.
  final DateTime fetchedAt;

  /// Network or cache.
  final DataSource source;

  /// Older than the TTL, or a refresh failed.
  final bool isStale;

  @override
  List<Object?> get props => [data, fetchedAt, source, isStale];
}

/// Why a request failed (C01 error table).
enum PicoFailureKind {
  /// No network or timeout.
  network,

  /// HTTP 429 after one retry.
  rateLimited,

  /// HTTP 404.
  notFound,

  /// HTTP 400, a client bug.
  badRequest,

  /// HTTP 5xx, `status: error` or unparseable JSON.
  server,
}

/// A failure features can show. Features never see an exception.
final class PicoFailure extends Failure {
  /// Creates a failure.
  const new(this.kind, {required super.message});

  /// Kind.
  final PicoFailureKind kind;

  @override
  bool operator ==(Object other) =>
      other is PicoFailure && other.kind == kind && other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'PicoFailure($kind, $message)';
}

/// Stream rule for every `watch*` method (C05):
/// 1. a cached copy is emitted first,
/// 2. a missing or stale copy (or `forceRefresh`) is fetched and emitted,
/// 3. a failed fetch with a copy emits the copy again with `isStale`,
/// 4. a failed fetch without a copy emits one `Left`,
/// 5. the stream then closes.
typedef Watch<T> = Stream<Either<PicoFailure, DataSnapshot<T>>>;
