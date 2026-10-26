import 'package:aura_music/features/player/domain/entities/playback_session.dart';

/// Persists the last playback session so the queue + position survive a
/// restart (PRD S06). Pure Dart: no `dio`, `drift` or Flutter imports.
abstract interface class PlaybackSessionRepository {
  /// Reads the stored snapshot; null when nothing was saved.
  Future<PlaybackSession?> read();

  /// Overwrites the stored snapshot.
  Future<void> write(PlaybackSession session);

  /// Deletes the stored snapshot.
  Future<void> clear();
}
