import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Loads the songs behind one mood / genre chip (PRD S03).

/// Returns tracks curated for [Genre].
final class GetGenreTracks implements UseCase<List<Track>, Genre> {
  /// Creates the use case.
  const GetGenreTracks(this._repository);

  final HomeRepository _repository;

  static const int _limit = 20;

  @override
  Future<Either<Failure, List<Track>>> call(Genre genre) =>
      _repository.byGenre(genre, limit: _limit);
}
