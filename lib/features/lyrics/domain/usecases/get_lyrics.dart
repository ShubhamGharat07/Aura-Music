import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Loads lyrics for a track (null when unavailable).

/// Returns the [Track]'s lyrics.
final class GetLyrics implements UseCase<Lyrics?, Track> {
  /// Creates the use case.
  const GetLyrics(this._repository);

  final LyricsRepository _repository;

  @override
  Future<Either<Failure, Lyrics?>> call(Track track) =>
      _repository.forTrack(track);
}
