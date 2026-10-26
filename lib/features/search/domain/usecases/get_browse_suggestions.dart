import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';

/// Ranked "Suggestions" for the empty search screen (PRD S04). Returns real
/// catalog songs ordered by plays — no hard-coded browse list.

/// Loads the idle suggestions list.
final class GetBrowseSuggestions implements UseCase<List<Track>, NoParams> {
  /// Creates the use case.
  const GetBrowseSuggestions(this._repository);

  final SearchRepository _repository;

  /// Number of suggestions shown on the idle screen.
  static const int limit = 10;

  @override
  Future<Either<Failure, List<Track>>> call(NoParams params) =>
      _repository.browse(limit: limit);
}
