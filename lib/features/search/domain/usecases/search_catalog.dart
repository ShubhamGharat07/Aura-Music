import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/entities/search_results.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';

/// Runs a multi-type catalog search (PRD S05).

/// Returns grouped results; a blank query short-circuits to empty groups.
final class SearchCatalog implements UseCase<SearchResults, String> {
  /// Creates the use case.
  const SearchCatalog(this._repository);

  final SearchRepository _repository;

  @override
  Future<Either<Failure, SearchResults>> call(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Right(SearchResults()));
    return _repository.search(trimmed);
  }
}
