import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/player/domain/entities/playback_session.dart';
import 'package:aura_music/features/player/domain/repositories/playback_session_repository.dart';

/// Reads the last playback session (PRD S06). A `null` success value means
/// there is nothing to restore.
final class RestorePlaybackSession
    implements UseCase<PlaybackSession?, NoParams> {
  /// Creates the use case.
  const RestorePlaybackSession(this._repository);

  final PlaybackSessionRepository _repository;

  @override
  Future<Either<Failure, PlaybackSession?>> call(NoParams params) async {
    try {
      return Right(await _repository.read());
    } on Object catch (error) {
      return Left(CacheFailure(error.toString()));
    }
  }
}
