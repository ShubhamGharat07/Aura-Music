import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';

/// Loads the editorial chart playlists shown on home (PRD S03).

/// Returns the top chart playlists.
final class GetTopCharts implements UseCase<List<Playlist>, NoParams> {
  /// Creates the use case.
  const GetTopCharts(this._repository);

  final HomeRepository _repository;

  static const int _limit = 12;

  @override
  Future<Either<Failure, List<Playlist>>> call(NoParams params) =>
      _repository.charts(limit: _limit);
}
