import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';

/// One UseCase = one action (PRD 5.2, Single Responsibility).
/// BLoCs depend on UseCases only, never on repositories directly.

/// Base contract for all use cases.
abstract class UseCase<Success, Params> {
  /// Executes the use case.
  Future<Either<Failure, Success>> call(Params params);
}

/// Marker for use cases that take no parameters.
final class NoParams extends Equatable {
  /// Creates no-params marker.
  const NoParams();

  @override
  List<Object?> get props => [];
}
