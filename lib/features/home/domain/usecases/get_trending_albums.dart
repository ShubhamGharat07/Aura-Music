import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';

/// Loads the trending album grid shown on home (PRD S03).

/// Returns the albums trending across the catalog.
final class GetTrendingAlbums implements UseCase<List<Album>, NoParams> {
  /// Creates the use case.
  const GetTrendingAlbums(this._repository);

  final HomeRepository _repository;

  static const int _limit = 24;

  @override
  Future<Either<Failure, List<Album>>> call(NoParams params) =>
      _repository.trendingAlbums(limit: _limit);
}
