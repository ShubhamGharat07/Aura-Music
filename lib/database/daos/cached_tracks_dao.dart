import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `cached_tracks` table (data layer only).
/// Backs the offline search fallback: every successful remote search keeps a
/// snapshot of its songs so the same query still resolves without a network.

/// Cached-track row gateway.
final class CachedTracksDao {
  /// Creates the DAO.
  const CachedTracksDao(this._db);

  final AppDatabase _db;

  /// Inserts / refreshes [entries] in one batch.
  Future<void> upsertAll(Iterable<CachedTracksCompanion> entries) async {
    final list = entries.toList(growable: false);
    if (list.isEmpty) return;
    await _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.cachedTracks, list),
    );
  }

  /// Case-insensitive title / artist match, newest snapshots first.
  Future<List<CachedTrack>> search(String query, {int limit = 30}) {
    final like = '%${query.toLowerCase()}%';
    return (_db.select(_db.cachedTracks)
          ..where(
            (t) => t.title.lower().like(like) | t.artist.lower().like(like),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
  }
}
