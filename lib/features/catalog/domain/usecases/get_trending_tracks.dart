import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Loads the trending feed for the home screen.

/// Returns up to [limit] trending tracks.
final class GetTrendingTracks implements UseCase<List<Track>, int> {
  /// Creates the use case.
  const GetTrendingTracks(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, List<Track>>> call(int limit) =>
      _repository.trending(limit: limit);
}
