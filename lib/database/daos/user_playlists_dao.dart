import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `playlists` / `playlist_songs` tables (data layer
/// only). Track snapshots are denormalised so playlists work offline.

/// User playlist gateway.
final class UserPlaylistsDao {
  /// Creates the DAO.
  const UserPlaylistsDao(this._db);

  final AppDatabase _db;

  /// Streams playlists, most recently updated first.
  Stream<List<Playlist>> watchAll() => (_db.select(
    _db.playlists,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Reads playlists, most recently updated first.
  Future<List<Playlist>> all() => (_db.select(
    _db.playlists,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  /// One playlist by id.
  Future<Playlist?> byId(String id) => (_db.select(
    _db.playlists,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts or replaces a playlist row.
  Future<void> upsert(PlaylistsCompanion entry) =>
      _db.into(_db.playlists).insertOnConflictUpdate(entry);

  /// Renames a playlist and bumps its `updatedAt`.
  Future<void> rename(String id, String name, DateTime at) =>
      (_db.update(_db.playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(name: Value(name), updatedAt: Value(at)),
      );

  /// Touches `updatedAt` (e.g. after a membership change).
  Future<void> touch(String id, DateTime at) =>
      (_db.update(_db.playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(updatedAt: Value(at)),
      );

  /// Deletes a playlist (its songs cascade away via the foreign key).
  Future<void> delete(String id) =>
      (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();

  /// Number of songs in a playlist.
  Future<int> count(String playlistId) async {
    final total = _db.playlistSongs.playlistId.count();
    final query = _db.selectOnly(_db.playlistSongs)
      ..addColumns([total])
      ..where(_db.playlistSongs.playlistId.equals(playlistId));
    return (await query.getSingle()).read(total) ?? 0;
  }

  /// Streams a playlist's songs in playlist order.
  Stream<List<PlaylistSong>> watchSongs(String playlistId) =>
      (_db.select(_db.playlistSongs)
            ..where((t) => t.playlistId.equals(playlistId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .watch();

  /// Reads a playlist's songs in playlist order.
  Future<List<PlaylistSong>> songs(String playlistId) =>
      (_db.select(_db.playlistSongs)
            ..where((t) => t.playlistId.equals(playlistId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  /// Inserts or replaces a membership row.
  Future<void> upsertSong(PlaylistSongsCompanion entry) =>
      _db.into(_db.playlistSongs).insertOnConflictUpdate(entry);

  /// Removes a track from a playlist.
  Future<void> removeSong(String playlistId, String trackId) =>
      (_db.delete(_db.playlistSongs)..where(
            (t) => t.playlistId.equals(playlistId) & t.trackId.equals(trackId),
          ))
          .go();

  /// Next append position for a playlist.
  Future<int> nextPosition(String playlistId) async {
    final maxPosition = _db.playlistSongs.position.max();
    final query = _db.selectOnly(_db.playlistSongs)
      ..addColumns([maxPosition])
      ..where(_db.playlistSongs.playlistId.equals(playlistId));
    final max = (await query.getSingle()).read(maxPosition);
    return max == null ? 0 : max + 1;
  }
}
