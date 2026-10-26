import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `downloads` table (data layer only).

/// Download row gateway.
final class DownloadsDao {
  /// Creates the DAO.
  const DownloadsDao(this._db);

  final AppDatabase _db;

  /// Streams every download, newest first.
  Stream<List<DownloadEntry>> watchAll() => (_db.select(
    _db.downloadEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  /// Reads every download, newest first.
  Future<List<DownloadEntry>> all() => (_db.select(
    _db.downloadEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Reads one row by track id.
  Future<DownloadEntry?> byTrack(String trackId) => (_db.select(
    _db.downloadEntries,
  )..where((t) => t.trackId.equals(trackId))).getSingleOrNull();

  /// Inserts a new row (or replaces the existing track snapshot).
  Future<void> create(DownloadEntriesCompanion entry) =>
      _db.into(_db.downloadEntries).insertOnConflictUpdate(entry);

  /// Updates only the columns present in [entry].
  Future<void> patch(String trackId, DownloadEntriesCompanion entry) =>
      (_db.update(
        _db.downloadEntries,
      )..where((t) => t.trackId.equals(trackId))).write(entry);

  /// Deletes a row.
  Future<void> delete(String trackId) => (_db.delete(
    _db.downloadEntries,
  )..where((t) => t.trackId.equals(trackId))).go();
}
