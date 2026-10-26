import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';

/// Clears the entire play history.

/// Clears play history.
final class ClearHistory {
  /// Creates the use case.
  const ClearHistory(this._repository);

  final PlayHistoryRepository _repository;

  /// Removes every history entry.
  Future<void> call() => _repository.clear();
}
