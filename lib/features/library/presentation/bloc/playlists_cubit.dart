import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/add_track_to_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/create_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/watch_playlists.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// User-playlists load status.

/// User-playlists load status.
enum PlaylistsStatus {
  /// Stream not yet delivered.
  loading,

  /// Has playlists.
  ready,

  /// No playlists yet.
  empty,

  /// Stream failed.
  error,
}

/// Immutable user-playlists state.
final class PlaylistsState extends Equatable {
  /// Creates the state.
  const PlaylistsState({
    this.status = PlaylistsStatus.loading,
    this.playlists = const [],
    this.error,
  });

  /// Current status.
  final PlaylistsStatus status;

  /// The user's playlists (most recently updated first).
  final List<UserPlaylist> playlists;

  /// Error message when [status] is [PlaylistsStatus.error].
  final String? error;

  /// Copies with overrides.
  PlaylistsState copyWith({
    PlaylistsStatus? status,
    List<UserPlaylist>? playlists,
    String? error,
  }) {
    return PlaylistsState(
      status: status ?? this.status,
      playlists: playlists ?? this.playlists,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, playlists, error];
}

/// Watches user playlists and drives create / add-track (PRD S12).
final class PlaylistsCubit extends Cubit<PlaylistsState> {
  /// Creates the cubit.
  PlaylistsCubit(this._watch, this._create, this._addTrack)
    : super(const PlaylistsState());

  final WatchPlaylists _watch;
  final CreatePlaylist _create;
  final AddTrackToPlaylist _addTrack;
  StreamSubscription<List<UserPlaylist>>? _sub;

  /// Subscribes to the playlist stream; stays live with the database.
  Future<void> load() async {
    await _sub?.cancel();
    _sub = _watch().listen(
      (playlists) => emit(
        state.copyWith(
          status: playlists.isEmpty
              ? PlaylistsStatus.empty
              : PlaylistsStatus.ready,
          playlists: playlists,
        ),
      ),
      onError: (_, _) => emit(
        state.copyWith(
          status: PlaylistsStatus.error,
          error: 'Could not load playlists',
        ),
      ),
    );
  }

  /// Creates a playlist and returns its id.
  Future<String> create(String name) => _create(name);

  /// Appends [track] to playlist [playlistId].
  Future<void> addTrack(String playlistId, Track track) =>
      _addTrack(playlistId, track);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
