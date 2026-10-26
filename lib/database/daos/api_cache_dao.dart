import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `api_cache_entries` table (data layer only).
/// Stores JSON snapshots of remote responses so a cold start can render from
/// disk instead of re-hitting the catalog.

/// Remote-response snapshot gateway.
final class ApiCacheDao {
  /// Creates the DAO.
  const ApiCacheDao(this._db);

  final AppDatabase _db;

  /// Reads one snapshot, or null when the key was never cached.
  Future<ApiCacheEntry?> read(String key) => (_db.select(
    _db.apiCacheEntries,
  )..where((t) => t.cacheKey.equals(key))).getSingleOrNull();

  /// Inserts / replaces the snapshot for [key].
  Future<void> write(String key, String payload) => _db
      .into(_db.apiCacheEntries)
      .insertOnConflictUpdate(
        ApiCacheEntriesCompanion.insert(
          cacheKey: key,
          payload: payload,
          storedAt: DateTime.now(),
        ),
      );

  /// Deletes every snapshot (used by "clear all data" style resets).
  Future<void> clear() => _db.delete(_db.apiCacheEntries).go();
}
