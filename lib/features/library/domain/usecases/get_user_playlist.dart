import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';

/// Loads one user playlist with its songs.

/// Reads a user playlist.
final class GetUserPlaylist {
  /// Creates the use case.
  const GetUserPlaylist(this._repository);

  final UserPlaylistRepository _repository;

  /// Returns the playlist detail, or null when missing.
  Future<UserPlaylistDetail?> call(String id) => _repository.detail(id);
}
