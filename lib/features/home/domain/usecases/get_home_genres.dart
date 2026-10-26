import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';

/// Loads the mood / genre chips shown on home (PRD S03).

/// Returns the catalog's mood and genre channels.
final class GetHomeGenres implements UseCase<List<Genre>, NoParams> {
  /// Creates the use case.
  const GetHomeGenres(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<Genre>>> call(NoParams params) =>
      _repository.genres();
}
