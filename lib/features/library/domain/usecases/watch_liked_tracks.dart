import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Streams the user's liked songs, kept live by the database.

/// Watches liked songs.
final class WatchLikedTracks {
  /// Creates the use case.
  const WatchLikedTracks(this._repository);

  final LikedSongsRepository _repository;

  /// Emits the liked list on every change.
  Stream<List<Track>> call() => _repository.watchLiked();
}
