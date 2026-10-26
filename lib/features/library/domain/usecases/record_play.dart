import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Records a playback in the user's history.

/// Appends a play.
final class RecordPlay {
  /// Creates the use case.
  const RecordPlay(this._repository);

  final PlayHistoryRepository _repository;

  /// Records that [track] just started playing.
  Future<void> call(Track track) => _repository.record(track);
}
