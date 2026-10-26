import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Locally stored play history (PRD S15). Rows live in the encrypted Drift
/// database; no account, no network.

/// Play-history contract.
abstract interface class PlayHistoryRepository {
  /// Emits history (newest first) on every change.
  Stream<List<HistoryEntry>> watchRecent({int limit});

  /// History snapshot (newest first).
  Future<List<HistoryEntry>> recent({int limit});

  /// Records that [track] was played (now).
  Future<void> record(Track track);

  /// Removes the entire history.
  Future<void> clear();
}
