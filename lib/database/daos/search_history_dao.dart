import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';

/// Drift queries for the `search_history` table (data layer only).

/// Recent-search row gateway.
final class SearchHistoryDao {
  /// Creates the DAO.
  const SearchHistoryDao(this._db);

  final AppDatabase _db;

  /// Recent queries, newest first.
  Future<List<SearchHistoryEntry>> recent({int limit = 10}) =>
      (_db.select(_db.searchHistoryEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.searchedAt)])
            ..limit(limit))
          .get();

  /// Records [query] as newest: case-insensitive de-dupe, then cap.
  Future<void> add(String query, DateTime at) async {
    final lower = query.toLowerCase();
    await (_db.delete(
      _db.searchHistoryEntries,
    )..where((t) => t.query.lower().equals(lower))).go();
    final previous = await _maxSearchedAt();
    final stamp = at.millisecondsSinceEpoch;
    await _db
        .into(_db.searchHistoryEntries)
        .insertOnConflictUpdate(
          SearchHistoryEntriesCompanion.insert(
            query: query,
            searchedAt: stamp > previous ? stamp : previous + 1,
          ),
        );
    await _prune();
  }

  /// Largest stored timestamp (0 when empty); keeps inserts strictly ordered
  /// even within the same millisecond.
  Future<int> _maxSearchedAt() async {
    final maxExpr = _db.searchHistoryEntries.searchedAt.max();
    final query = _db.selectOnly(_db.searchHistoryEntries)
      ..addColumns([maxExpr]);
    return (await query.getSingle()).read(maxExpr) ?? 0;
  }

  /// Removes every recent-search row.
  Future<void> clear() => _db.delete(_db.searchHistoryEntries).go();

  /// Removes one term (case-insensitive), e.g. the chip's × button.
  Future<void> delete(String query) => (_db.delete(
    _db.searchHistoryEntries,
  )..where((t) => t.query.lower().equals(query.trim().toLowerCase()))).go();

  /// Keeps only the ten newest queries.
  Future<void> _prune() async {
    final kept = await recent();
    final queries = kept.map((row) => row.query).toList(growable: false);
    if (queries.isEmpty) return;
    await (_db.delete(
      _db.searchHistoryEntries,
    )..where((t) => t.query.isNotIn(queries))).go();
  }
}
