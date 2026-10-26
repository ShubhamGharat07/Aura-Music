import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Lyrics lookup contract (domain). Implemented in `data/` against LRCLIB,
/// with Unison as a fallback provider.

/// Resolves lyrics for a track (null when none exist).
abstract interface class LyricsRepository {
  /// Fetches lyrics for [track], or `Right(null)` when not found.
  Future<Either<Failure, Lyrics?>> forTrack(Track track);
}
