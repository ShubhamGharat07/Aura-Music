import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/lyrics/data/datasources/lrclib_remote_data_source.dart';
import 'package:aura_music/features/lyrics/data/datasources/unison_remote_data_source.dart';
import 'package:aura_music/features/lyrics/data/lrc_parser.dart';
import 'package:aura_music/features/lyrics/data/ttml_parser.dart';
import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// [LyricsRepository] implementation: LRCLIB first, Unison as a fallback.
///
/// Unison is tried when LRCLIB yields nothing *or* fails, so a single provider
/// outage never blocks lyrics entirely.

/// LRCLIB + Unison-backed lyrics repository.
final class LyricsRepositoryImpl implements LyricsRepository {
  /// Creates the repository.
  const LyricsRepositoryImpl(this._lrclib, this._unison);

  final LrclibRemoteDataSource _lrclib;
  final UnisonRemoteDataSource _unison;

  @override
  Future<Either<Failure, Lyrics?>> forTrack(Track track) async {
    try {
      return Right(await _resolve(track));
    } on NetworkException catch (error) {
      return Left(NetworkFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } on AppException catch (error) {
      return Left(UnknownFailure(error.message));
    }
  }

  Future<Lyrics?> _resolve(Track track) async {
    try {
      final payload = await _lrclib.fetch(
        trackName: track.title,
        artistName: track.artist,
        albumName: track.album,
        durationSeconds: track.duration.inSeconds,
      );
      if (payload != null) {
        final lyrics = LrcParser.build(
          synced: payload.syncedLyrics,
          plain: payload.plainLyrics,
        );
        if (lyrics != null) return lyrics;
      }
    } on AppException {
      // Fall through to Unison.
    }

    final fallback = await _unison.fetch(
      title: track.title,
      artist: track.artist,
      album: track.album,
      durationSeconds: track.duration.inSeconds,
    );
    if (fallback == null) return null;
    if (fallback.format == 'ttml' ||
        TtmlParser.looksLikeTtml(fallback.lyrics)) {
      return TtmlParser.toLyrics(fallback.lyrics);
    }
    return LrcParser.build(synced: fallback.lyrics, plain: fallback.lyrics);
  }
}
