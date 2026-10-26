import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/player/domain/entities/playback_session.dart';
import 'package:aura_music/features/player/domain/repositories/playback_session_repository.dart';

/// Persists the current playback session (PRD S06).
final class SavePlaybackSession implements UseCase<Unit, PlaybackSession> {
  /// Creates the use case.
  const SavePlaybackSession(this._repository);

  final PlaybackSessionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(PlaybackSession params) async {
    try {
      await _repository.write(params);
      return const Right(unit);
    } on Object catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
