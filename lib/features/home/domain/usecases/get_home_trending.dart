import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Loads the home "quick picks" / trending section (PRD S03).

/// Returns up to [limit] trending tracks.
final class GetHomeTrending implements UseCase<List<Track>, int> {
  /// Creates the use case.
  const GetHomeTrending(this._repository);

  /// Four Home pages of six tracks.
  static const int homePickLimit = 24;

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<Track>>> call(int limit) =>
      _repository.trending(limit: limit);
}
