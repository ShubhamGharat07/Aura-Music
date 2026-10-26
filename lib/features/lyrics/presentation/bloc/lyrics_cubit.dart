import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/lyrics/domain/usecases/get_lyrics.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Lyrics load status.

/// Lyrics status.
enum LyricsStatus {
  /// Nothing requested yet.
  idle,

  /// Fetch in flight.
  loading,

  /// Lyrics available.
  ready,

  /// No lyrics for this track.
  empty,

  /// Fetch failed.
  error,
}

/// Immutable lyrics state.
final class LyricsState extends Equatable {
  /// Creates the state.
  const LyricsState({
    this.status = LyricsStatus.idle,
    this.trackId,
    this.lyrics,
    this.error,
  });

  /// Current status.
  final LyricsStatus status;

  /// Track the lyrics belong to.
  final String? trackId;

  /// Loaded lyrics (when [status] is [LyricsStatus.ready]).
  final Lyrics? lyrics;

  /// Error message (when [status] is [LyricsStatus.error]).
  final String? error;

  @override
  List<Object?> get props => [status, trackId, lyrics, error];
}

/// Loads lyrics for the now-playing track via [GetLyrics].
final class LyricsCubit extends Cubit<LyricsState> {
  /// Creates the cubit.
  LyricsCubit(this._getLyrics) : super(const LyricsState());

  final GetLyrics _getLyrics;

  /// Loads lyrics for [track]. No-op for a blank track title.
  Future<void> load(Track track) async {
    if (track.title.trim().isEmpty) {
      emit(const LyricsState());
      return;
    }
    emit(LyricsState(status: LyricsStatus.loading, trackId: track.id));
    final result = await _getLyrics(track);
    result.fold(
      (failure) => emit(
        LyricsState(
          status: LyricsStatus.error,
          trackId: track.id,
          error: failure.message,
        ),
      ),
      (lyrics) {
        if (lyrics == null || lyrics.isEmpty) {
          emit(LyricsState(status: LyricsStatus.empty, trackId: track.id));
        } else {
          emit(
            LyricsState(
              status: LyricsStatus.ready,
              trackId: track.id,
              lyrics: lyrics,
            ),
          );
        }
      },
    );
  }
}
