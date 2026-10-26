import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';

/// Creates a new user playlist.

/// Creates a user playlist.
final class CreatePlaylist {
  /// Creates the use case.
  const CreatePlaylist(this._repository);

  final UserPlaylistRepository _repository;

  /// Creates a playlist named [name] and returns its id.
  Future<String> call(String name, {String? description}) =>
      _repository.create(name, description: description);
}
