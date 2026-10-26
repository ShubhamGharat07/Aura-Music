import 'package:aura_music/features/player/domain/entities/track.dart';

/// Locally stored liked songs (PRD F08 / S14). Part of the offline library —
/// no account, no network; rows live in the encrypted Drift database.

/// Liked songs contract.
abstract interface class LikedSongsRepository {
  /// Emits the liked list (most recent first) on every change.
  Stream<List<Track>> watchLiked();

  /// Current liked list snapshot (most recent first).
  Future<List<Track>> all();

  /// Whether [trackId] is liked.
  Future<bool> isLiked(String trackId);

  /// Adds or removes [track]; returns `true` when it is now liked.
  Future<bool> toggle(Track track);

  /// Removes [trackId] from the liked list.
  Future<void> remove(String trackId);

  /// Removes every liked track.
  Future<void> clear();
}
