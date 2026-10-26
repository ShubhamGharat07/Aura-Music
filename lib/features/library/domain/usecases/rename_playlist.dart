import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';

/// Renames a user playlist.

/// Renames a user playlist.
final class RenamePlaylist {
  /// Creates the use case.
  const RenamePlaylist(this._repository);

  final UserPlaylistRepository _repository;

  /// Renames playlist [id] to [name].
  Future<void> call(String id, String name) => _repository.rename(id, name);
}
