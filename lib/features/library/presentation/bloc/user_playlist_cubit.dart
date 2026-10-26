import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/library/domain/usecases/delete_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/get_user_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/remove_track_from_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/rename_playlist.dart';

/// User-playlist detail load status.

/// Single user-playlist status.
enum UserPlaylistStatus {
  /// Fetch in flight.
  loading,

  /// Loaded.
  ready,

  /// Playlist does not exist.
  missing,

  /// Fetch failed.
  error,
}

/// Immutable single-playlist state.
final class UserPlaylistState extends Equatable {
  /// Creates the state.
  const UserPlaylistState({
    this.status = UserPlaylistStatus.loading,
    this.id = '',
    this.detail,
    this.error,
  });

  /// Current status.
  final UserPlaylistStatus status;

  /// Playlist id being edited.
  final String id;

  /// Loaded detail (when [status] is [UserPlaylistStatus.ready]).
  final UserPlaylistDetail? detail;

  /// Error message when [status] is [UserPlaylistStatus.error].
  final String? error;

  /// Copies with overrides.
  UserPlaylistState copyWith({
    UserPlaylistStatus? status,
    String? id,
    UserPlaylistDetail? detail,
    String? error,
  }) {
    return UserPlaylistState(
      status: status ?? this.status,
      id: id ?? this.id,
      detail: detail ?? this.detail,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, id, detail, error];
}

/// Loads one user playlist and drives rename / delete / remove-track (PRD S13).
final class UserPlaylistCubit extends Cubit<UserPlaylistState> {
  /// Creates the cubit.
  UserPlaylistCubit(this._get, this._rename, this._delete, this._removeTrack)
    : super(const UserPlaylistState());

  final GetUserPlaylist _get;
  final RenamePlaylist _rename;
  final DeletePlaylist _delete;
  final RemoveTrackFromPlaylist _removeTrack;

  /// Loads the playlist with [id].
  Future<void> load(String id) async {
    emit(UserPlaylistState(status: UserPlaylistStatus.loading, id: id));
    final detail = await _get(id);
    if (detail == null) {
      emit(state.copyWith(status: UserPlaylistStatus.missing));
      return;
    }
    emit(state.copyWith(status: UserPlaylistStatus.ready, detail: detail));
  }

  /// Renames the current playlist, then reloads.
  Future<void> rename(String name) async {
    if (state.id.isEmpty) return;
    await _rename(state.id, name);
    await load(state.id);
  }

  /// Deletes the current playlist.
  Future<void> delete() async {
    if (state.id.isEmpty) return;
    await _delete(state.id);
  }

  /// Removes a track, then reloads.
  Future<void> removeTrack(String trackId) async {
    if (state.id.isEmpty) return;
    await _removeTrack(state.id, trackId);
    await load(state.id);
  }
}
