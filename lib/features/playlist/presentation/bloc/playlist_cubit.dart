import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/playlist/domain/usecases/get_playlist.dart';

/// Playlist load state.

/// Playlist status.
enum PlaylistStatus {
  /// Fetch in flight.
  loading,

  /// Playlist ready.
  ready,

  /// Load failed.
  error,
}

/// Immutable playlist state.
final class PlaylistState extends Equatable {
  /// Creates the state.
  const PlaylistState({
    this.status = PlaylistStatus.loading,
    this.detail,
    this.error,
  });

  /// Current status.
  final PlaylistStatus status;

  /// Loaded playlist (when ready).
  final PlaylistDetail? detail;

  /// Error message (when [status] is [PlaylistStatus.error]).
  final String? error;

  @override
  List<Object?> get props => [status, detail, error];
}

/// Loads a playlist via [GetPlaylist].
final class PlaylistCubit extends Cubit<PlaylistState> {
  /// Creates the cubit.
  PlaylistCubit(this._getPlaylist) : super(const PlaylistState());

  final GetPlaylist _getPlaylist;

  /// Loads (or reloads) the playlist for [id].
  Future<void> load(String id) async {
    emit(const PlaylistState());
    final result = await _getPlaylist(id);
    result.fold(
      (failure) => emit(
        PlaylistState(status: PlaylistStatus.error, error: failure.message),
      ),
      (detail) =>
          emit(PlaylistState(status: PlaylistStatus.ready, detail: detail)),
    );
  }
}
