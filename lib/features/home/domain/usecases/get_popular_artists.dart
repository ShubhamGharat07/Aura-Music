import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';

/// Loads the popular-artist row shown on home (PRD S03).

/// Returns the catalog's popular artists.
final class GetPopularArtists implements UseCase<List<Artist>, NoParams> {
  /// Creates the use case.
  const GetPopularArtists(this._repository);

  final HomeRepository _repository;

  static const int _limit = 20;

  @override
  Future<Either<Failure, List<Artist>>> call(NoParams params) =>
      _repository.popularArtists(limit: _limit);
}
