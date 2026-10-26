import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';

/// Removes a track from the liked list (e.g. swipe action on S14).

/// Unlikes a track.
final class RemoveLikedTrack {
  /// Creates the use case.
  const RemoveLikedTrack(this._repository);

  final LikedSongsRepository _repository;

  /// Removes [trackId] from the liked list.
  Future<void> call(String trackId) => _repository.remove(trackId);
}
