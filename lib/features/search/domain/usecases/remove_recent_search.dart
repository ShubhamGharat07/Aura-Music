import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';

/// Removes one recent search term (PRD S04 chip ×).

/// Deletes a recent term.
final class RemoveRecentSearch implements UseCase<Unit, String> {
  /// Creates the use case.
  const RemoveRecentSearch(this._repository);

  final SearchHistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String query) async {
    await _repository.remove(query);
    return const Right(unit);
  }
}
