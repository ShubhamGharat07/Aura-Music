import 'package:aura_music/database/daos/api_cache_dao.dart';

/// Disk-backed cache for remote JSON snapshots (SQLite via [ApiCacheDao]).
///
/// A cold start reads the last successful response from disk, so reopening the
/// app within [DefaultTtl] does not repeat the same API calls. Expired rows are
/// ignored (the caller falls back to the network and overwrites them). Failures
/// are swallowed: the cache must never break a screen.

/// SQLite-backed response cache.
final class PersistentCache {
  /// Creates the cache.
  const PersistentCache(this._dao);

  /// Default freshness window for cached snapshots.
  static const Duration defaultTtl = Duration(hours: 1);

  final ApiCacheDao _dao;

  /// Returns the decoded snapshot for [key], or null when missing, expired or
  /// unreadable.
  Future<T?> read<T>(
    String key, {
    required Duration ttl,
    required T Function(String payload) decode,
  }) async {
    try {
      final row = await _dao.read(key);
      if (row == null) return null;
      if (DateTime.now().difference(row.storedAt) > ttl) return null;
      return decode(row.payload);
    } on Object {
      return null;
    }
  }

  /// Saves [payload] for [key]. Best effort.
  Future<void> write(String key, String payload) async {
    try {
      await _dao.write(key, payload);
    } on Object {
      // A cache write must never fail the request that produced the data.
    }
  }
}
