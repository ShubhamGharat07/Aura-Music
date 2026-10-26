import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';

/// Streams the user's play history, kept live by the database.

/// Watches play history.
final class WatchHistory {
  /// Creates the use case.
  const WatchHistory(this._repository);

  final PlayHistoryRepository _repository;

  /// Emits history (newest first) on every change.
  Stream<List<HistoryEntry>> call({int limit = 200}) =>
      _repository.watchRecent(limit: limit);
}
