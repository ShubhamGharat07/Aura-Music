import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';

/// Records a submitted search term (PRD S04).

/// De-duplicates and caps history inside the repository.
final class SaveRecentSearch implements UseCase<Unit, String> {
  /// Creates the use case.
  const SaveRecentSearch(this._repository);

  final SearchHistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String query) async {
    await _repository.add(query);
    return const Right(unit);
  }
}
