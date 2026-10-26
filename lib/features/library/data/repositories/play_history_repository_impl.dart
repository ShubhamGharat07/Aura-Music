import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/history_dao.dart';
import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// [PlayHistoryRepository] over the Drift `history` table.

/// Drift-backed play history repository.
final class DriftPlayHistoryRepository implements PlayHistoryRepository {
  /// Creates the repository.
  const DriftPlayHistoryRepository(this._dao);

  final HistoryDao _dao;

  @override
  Stream<List<HistoryEntry>> watchRecent({int limit = 200}) => _dao
      .watchAll(limit: limit)
      .map((rows) => rows.map(_toEntry).toList(growable: false));

  @override
  Future<List<HistoryEntry>> recent({int limit = 200}) async =>
      (await _dao.all(limit: limit)).map(_toEntry).toList(growable: false);

  @override
  Future<void> record(Track track) => _dao.add(
    PlayHistoryCompanion.insert(
      trackId: track.id,
      title: track.title,
      artist: track.artist,
      album: Value(track.album),
      artUrl: Value(track.artUrl),
      durationMs: Value(track.duration.inMilliseconds),
      streamUrl: Value(track.streamUrl),
      playedAt: DateTime.now(),
    ),
  );

  @override
  Future<void> clear() => _dao.clear();

  HistoryEntry _toEntry(PlayHistoryData row) => HistoryEntry(
    track: Track(
      id: row.trackId,
      title: row.title,
      artist: row.artist,
      album: row.album,
      artUrl: row.artUrl,
      duration: Duration(milliseconds: row.durationMs),
      streamUrl: row.streamUrl,
    ),
    playedAt: row.playedAt,
  );
}
