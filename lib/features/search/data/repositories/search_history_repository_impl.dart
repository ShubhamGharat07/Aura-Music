import 'package:aura_music/database/daos/search_history_dao.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';

/// [SearchHistoryRepository] over the Drift `search_history` table.

/// Drift-backed recent-search history.
final class DriftSearchHistoryRepository implements SearchHistoryRepository {
  /// Creates the repository.
  const DriftSearchHistoryRepository(this._dao);

  final SearchHistoryDao _dao;

  @override
  Future<List<String>> recent() async =>
      (await _dao.recent()).map((row) => row.query).toList(growable: false);

  @override
  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await _dao.add(trimmed, DateTime.now());
  }

  @override
  Future<void> clear() => _dao.clear();

  @override
  Future<void> remove(String query) => _dao.delete(query);
}
