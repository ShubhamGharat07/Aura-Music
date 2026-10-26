import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';

/// Deletes a user playlist and its songs.

/// Deletes a user playlist.
final class DeletePlaylist {
  /// Creates the use case.
  const DeletePlaylist(this._repository);

  final UserPlaylistRepository _repository;

  /// Deletes playlist [id].
  Future<void> call(String id) => _repository.delete(id);
}
