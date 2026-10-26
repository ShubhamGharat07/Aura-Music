import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';

/// Removes a track from a user playlist.

/// Removes a track from a playlist.
final class RemoveTrackFromPlaylist {
  /// Creates the use case.
  const RemoveTrackFromPlaylist(this._repository);

  final UserPlaylistRepository _repository;

  /// Removes [trackId] from playlist [playlistId].
  Future<void> call(String playlistId, String trackId) =>
      _repository.removeTrack(playlistId, trackId);
}
