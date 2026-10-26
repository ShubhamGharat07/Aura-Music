import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';

/// Streams the user's playlists, kept live by the database.

/// Watches user playlists.
final class WatchPlaylists {
  /// Creates the use case.
  const WatchPlaylists(this._repository);

  final UserPlaylistRepository _repository;

  /// Emits playlists on every change.
  Stream<List<UserPlaylist>> call() => _repository.watchAll();
}
