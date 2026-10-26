import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Adds [track] to the liked list, or removes it when already liked.

/// Toggles a track's liked state.
final class ToggleLike {
  /// Creates the use case.
  const ToggleLike(this._repository);

  final LikedSongsRepository _repository;

  /// Returns `true` when [track] is liked after the toggle.
  Future<bool> call(Track track) => _repository.toggle(track);
}
