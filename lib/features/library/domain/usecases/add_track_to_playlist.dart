import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Appends a track to a user playlist.

/// Adds a track to a playlist.
final class AddTrackToPlaylist {
  /// Creates the use case.
  const AddTrackToPlaylist(this._repository);

  final UserPlaylistRepository _repository;

  /// Appends [track] to playlist [playlistId].
  Future<void> call(String playlistId, Track track) =>
      _repository.addTrack(playlistId, track);
}
