import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';

/// Fetches lightweight song suggestions for the type-ahead list (PRD S04).

/// Returns an empty list for a blank query.
final class GetSuggestions implements UseCase<List<Track>, String> {
  /// Creates the use case.
  const GetSuggestions(this._repository);

  final SearchRepository _repository;

  @override
  Future<Either<Failure, List<Track>>> call(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Right(<Track>[]));
    return _repository.suggestions(trimmed, limit: 8);
  }
}
