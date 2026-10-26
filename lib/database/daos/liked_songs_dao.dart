import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `liked_songs` table (data layer only).

/// Liked songs row gateway.
final class LikedSongsDao {
  /// Creates the DAO.
  const LikedSongsDao(this._db);

  final AppDatabase _db;

  /// Streams liked songs, most recently liked first.
  Stream<List<LikedSong>> watchAll() => (_db.select(
    _db.likedSongs,
  )..orderBy([(t) => OrderingTerm.desc(t.likedAt)])).watch();

  /// Reads liked songs, most recently liked first.
  Future<List<LikedSong>> all() => (_db.select(
    _db.likedSongs,
  )..orderBy([(t) => OrderingTerm.desc(t.likedAt)])).get();

  /// Whether [trackId] is liked.
  Future<bool> contains(String trackId) async =>
      await (_db.select(
        _db.likedSongs,
      )..where((t) => t.trackId.equals(trackId))).getSingleOrNull() !=
      null;

  /// Inserts or replaces the liked-song snapshot for a track.
  Future<void> upsert(LikedSongsCompanion entry) =>
      _db.into(_db.likedSongs).insertOnConflictUpdate(entry);

  /// Removes a liked-song row.
  Future<void> delete(String trackId) => (_db.delete(
    _db.likedSongs,
  )..where((t) => t.trackId.equals(trackId))).go();

  /// Removes every liked-song row.
  Future<void> clear() => _db.delete(_db.likedSongs).go();
}
