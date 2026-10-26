import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/search_history_dao.dart';
import 'package:aura_music/features/search/data/repositories/search_history_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DriftSearchHistoryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftSearchHistoryRepository(SearchHistoryDao(db));
  });
  tearDown(() => db.close());

  test('keeps newest first and de-duplicates case-insensitively', () async {
    await repository.add('neon');
    await repository.add('aurora');
    await repository.add('NEON');

    expect(await repository.recent(), <String>['NEON', 'aurora']);
  });

  test('ignores blank input', () async {
    await repository.add('   ');

    expect(await repository.recent(), isEmpty);
  });

  test('caps history at ten entries', () async {
    for (var i = 0; i < 12; i++) {
      await repository.add('term$i');
    }

    final recent = await repository.recent();
    expect(recent, hasLength(10));
    expect(recent.first, 'term11');
  });

  test('clear removes all history', () async {
    await repository.add('neon');

    await repository.clear();

    expect(await repository.recent(), isEmpty);
  });
}
