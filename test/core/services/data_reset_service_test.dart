import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/services/data_reset_service.dart';
import 'package:aura_music/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory downloads;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    downloads = await Directory.systemTemp.createTemp('aura-reset');
    SharedPreferences.setMockInitialValues({'appearance.amoled': true});
  });

  tearDown(() async {
    await db.close();
    if (downloads.existsSync()) await downloads.delete(recursive: true);
  });

  test(
    'clears every table, the preferences and the downloads folder',
    () async {
      await db
          .into(db.likedSongs)
          .insert(
            LikedSongsCompanion.insert(
              trackId: 't1',
              title: 'Neon',
              artist: 'Aurora',
              likedAt: 1,
            ),
          );
      await db
          .into(db.searchHistoryEntries)
          .insert(
            SearchHistoryEntriesCompanion.insert(query: 'neon', searchedAt: 1),
          );
      await File(
        '${downloads.path}${Platform.pathSeparator}song.mp3',
      ).writeAsString('audio');

      final prefs = await SharedPreferences.getInstance();
      final service = DataResetService(
        db,
        prefs,
        downloadsDirectory: () async => downloads,
      );

      await service.clearAll();

      expect(await db.select(db.likedSongs).get(), isEmpty);
      expect(await db.select(db.searchHistoryEntries).get(), isEmpty);
      expect(prefs.getBool('appearance.amoled'), isNull);
      expect(downloads.existsSync(), isFalse);
    },
  );

  test('is idempotent when there is nothing to clear', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = DataResetService(
      db,
      prefs,
      downloadsDirectory: () async => downloads,
    );

    await service.clearAll();
    await service.clearAll();

    expect(await db.select(db.likedSongs).get(), isEmpty);
  });
}
