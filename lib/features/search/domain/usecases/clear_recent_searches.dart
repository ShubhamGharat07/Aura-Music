import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';

/// Clears all recent search history (PRD S04).

/// Idempotent.
final class ClearRecentSearches implements UseCase<Unit, NoParams> {
  /// Creates the use case.
  const ClearRecentSearches(this._repository);

  final SearchHistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    await _repository.clear();
    return const Right(unit);
  }
}
