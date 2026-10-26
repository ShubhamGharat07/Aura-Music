import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `history` table (data layer only).

/// Play-history row gateway.
final class HistoryDao {
  /// Creates the DAO.
  const HistoryDao(this._db);

  final AppDatabase _db;

  /// Streams history, newest first (stable on same-second plays via `id`).
  Stream<List<PlayHistoryData>> watchAll({int limit = 200}) =>
      (_db.select(_db.playHistory)
            ..orderBy([
              (t) => OrderingTerm.desc(t.playedAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .watch();

  /// Reads history, newest first.
  Future<List<PlayHistoryData>> all({int limit = 200}) =>
      (_db.select(_db.playHistory)
            ..orderBy([
              (t) => OrderingTerm.desc(t.playedAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .get();

  /// Appends a play.
  Future<void> add(PlayHistoryCompanion entry) =>
      _db.into(_db.playHistory).insert(entry);

  /// Removes every history row.
  Future<void> clear() => _db.delete(_db.playHistory).go();
}
