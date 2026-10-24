import 'package:core_infrastructure_api/src/base/either.dart';
import 'package:core_infrastructure_api/src/failures/failure.dart';
import 'package:dependencies_core/meta.dart';

/// Base use case for implementing business logic with repository pattern.
///
/// [Result] - The type of result returned by the use case
/// [Param] - The type of parameter passed to the use case
/// [Repository] - The repository interface this use case depends on
abstract class const BaseUseCase<Result, Param, Repository>({
  @protected required final Repository repo,
}) {
  /// Execute the use case with the given parameters.
  /// Returns either a [Failure] or [Result] wrapped in Either.
  Future<Either<Failure, Result>> call(Param param);
}

/// Base use case that doesn't require any parameters.
abstract class const BaseUseCaseNoParam<Result, Repository>({
  @protected required final Repository repo,
}) {
  /// Execute the use case without parameters.
  /// Returns either a [Failure] or [Result] wrapped in Either.
  Future<Either<Failure, Result>> call();
}
