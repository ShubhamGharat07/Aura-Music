import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Locally stored user playlists (PRD S12/S13, offline-first).

/// User-playlist contract.
abstract interface class UserPlaylistRepository {
  /// Emits playlists (most recently updated first) on every change.
  Stream<List<UserPlaylist>> watchAll();

  /// Playlists snapshot (most recently updated first).
  Future<List<UserPlaylist>> all();

  /// A playlist with its songs, or null when it no longer exists.
  Future<UserPlaylistDetail?> detail(String id);

  /// Creates a playlist and returns its id.
  Future<String> create(String name, {String? description});

  /// Renames a playlist.
  Future<void> rename(String id, String name);

  /// Deletes a playlist and its songs.
  Future<void> delete(String id);

  /// Appends [track] to a playlist (no-op when already present).
  Future<void> addTrack(String playlistId, Track track);

  /// Removes a track from a playlist.
  Future<void> removeTrack(String playlistId, String trackId);
}
