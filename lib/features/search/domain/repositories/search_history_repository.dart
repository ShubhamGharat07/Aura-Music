/// Local recent-search history contract (PRD S04). Persists terms
/// newest-first in the encrypted Drift `search_history` table.
abstract interface class SearchHistoryRepository {
  /// Recent terms, newest first.
  Future<List<String>> recent();

  /// Records [query] as the newest term (de-duplicated, capped).
  Future<void> add(String query);

  /// Clears all history.
  Future<void> clear();

  /// Removes a single [query] (case-insensitive).
  Future<void> remove(String query);
}
