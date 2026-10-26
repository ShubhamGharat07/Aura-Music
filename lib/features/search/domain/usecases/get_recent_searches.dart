import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';

/// Reads recent search terms (PRD S04).

/// Returns terms newest-first; local storage never fails in practice.
final class GetRecentSearches implements UseCase<List<String>, NoParams> {
  /// Creates the use case.
  const GetRecentSearches(this._repository);

  final SearchHistoryRepository _repository;

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async =>
      Right(await _repository.recent());
}
