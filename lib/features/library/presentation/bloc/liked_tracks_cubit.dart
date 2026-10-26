import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/library/domain/usecases/remove_liked_track.dart';
import 'package:aura_music/features/library/domain/usecases/toggle_like.dart';
import 'package:aura_music/features/library/domain/usecases/watch_liked_tracks.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Ordering for the liked-songs list (PRD S14 sort).

/// Liked-songs sort order.
enum LikedSort {
  /// Most recently liked first (default).
  recent,

  /// Track title A–Z.
  title,

  /// Artist A–Z.
  artist,
}

/// Liked-songs load status.
enum LikedTracksStatus {
  /// Stream not yet delivered.
  loading,

  /// Has likes.
  ready,

  /// No likes yet.
  empty,

  /// Stream failed.
  error,
}

/// Immutable liked-songs state (search + sort are view state, kept here so the
/// list stays a pure function of state).
final class LikedTracksState extends Equatable {
  /// Creates the state.
  const LikedTracksState({
    this.status = LikedTracksStatus.loading,
    this.tracks = const [],
    this.query = '',
    this.sort = LikedSort.recent,
    this.error,
  });

  /// Current status.
  final LikedTracksStatus status;

  /// All liked tracks (most recent first, as stored).
  final List<Track> tracks;

  /// In-list search query.
  final String query;

  /// Active sort order.
  final LikedSort sort;

  /// Error message when [status] is [LikedTracksStatus.error].
  final String? error;

  /// Tracks filtered by [query] and ordered by [sort].
  List<Track> get visible {
    final needle = query.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? [...tracks]
        : tracks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(needle) ||
                    t.artist.toLowerCase().contains(needle),
              )
              .toList();
    switch (sort) {
      case LikedSort.recent:
        break;
      case LikedSort.title:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case LikedSort.artist:
        filtered.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
    }
    return List.unmodifiable(filtered);
  }

  /// Copies with overrides.
  LikedTracksState copyWith({
    LikedTracksStatus? status,
    List<Track>? tracks,
    String? query,
    LikedSort? sort,
    String? error,
  }) {
    return LikedTracksState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, tracks, query, sort, error];
}

/// Watches locally liked songs and drives unlike / search / sort (PRD S14).
final class LikedTracksCubit extends Cubit<LikedTracksState> {
  /// Creates the cubit.
  LikedTracksCubit(this._watchLiked, this._toggleLike, this._removeLiked)
    : super(const LikedTracksState());

  final WatchLikedTracks _watchLiked;
  final ToggleLike _toggleLike;
  final RemoveLikedTrack _removeLiked;

  StreamSubscription<List<Track>>? _sub;

  /// Subscribes to the liked stream; stays live with the database.
  Future<void> load() async {
    await _sub?.cancel();
    _sub = _watchLiked().listen(
      (tracks) => emit(_onTracks(tracks)),
      onError: (_, _) => emit(
        state.copyWith(
          status: LikedTracksStatus.error,
          error: 'Could not load liked songs',
        ),
      ),
    );
  }

  LikedTracksState _onTracks(List<Track> tracks) => state.copyWith(
    status: tracks.isEmpty ? LikedTracksStatus.empty : LikedTracksStatus.ready,
    tracks: tracks,
  );

  /// Filters the list to [query].
  void search(String query) => emit(state.copyWith(query: query));

  /// Cycles recent → title → artist → recent.
  void cycleSort() {
    final next = switch (state.sort) {
      LikedSort.recent => LikedSort.title,
      LikedSort.title => LikedSort.artist,
      LikedSort.artist => LikedSort.recent,
    };
    emit(state.copyWith(sort: next));
  }

  /// Adds or removes [track] from the liked list.
  Future<void> toggle(Track track) => _toggleLike(track);

  /// Removes a track (swipe-to-unlike).
  Future<void> unlike(String trackId) => _removeLiked(trackId);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
