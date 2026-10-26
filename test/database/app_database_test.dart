import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';

void main() {
  group('AppDatabase (in-memory)', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('caches track metadata', () async {
      await db
          .into(db.cachedTracks)
          .insert(
            CachedTracksCompanion.insert(
              id: 'audius:1',
              title: 'Neon Horizon',
              artist: 'Aurora Skies',
              updatedAt: DateTime(2026, 1, 1),
            ),
          );

      final row = await db.select(db.cachedTracks).getSingle();
      expect(row.id, 'audius:1');
      expect(row.title, 'Neon Horizon');
      expect(row.durationMs, 0);
    });

    test('persists download status enum round-trip', () async {
      await db
          .into(db.downloadEntries)
          .insert(
            DownloadEntriesCompanion.insert(
              trackId: 'audius:1',
              title: 'Neon Horizon',
              artist: 'Aurora Skies',
              status: DownloadStatus.completed,
              createdAt: DateTime(2026, 1, 1),
            ),
          );

      final row = await db.select(db.downloadEntries).getSingle();
      expect(row.status, DownloadStatus.completed);
      expect(row.filePath, isNull);
    });

    test('stores liked songs', () async {
      await db
          .into(db.likedSongs)
          .insert(
            LikedSongsCompanion.insert(
              trackId: 'jiosaavn:1',
              title: 'Kesariya',
              artist: 'Arijit Singh',
              likedAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
            ),
          );

      final row = await db.select(db.likedSongs).getSingle();
      expect(row.trackId, 'jiosaavn:1');
      expect(row.album, isNull);
    });

    test('stores play history ordered by playedAt', () async {
      await db.batch((b) {
        b.insertAll(db.playHistory, [
          PlayHistoryCompanion.insert(
            trackId: 'jiosaavn:1',
            title: 'Kesariya',
            artist: 'Arijit Singh',
            playedAt: DateTime.utc(2026, 1, 1),
          ),
          PlayHistoryCompanion.insert(
            trackId: 'jiosaavn:2',
            title: 'Apna Bana Le',
            artist: 'Arijit Singh',
            playedAt: DateTime.utc(2026, 1, 2),
          ),
        ]);
      });

      final rows = await (db.select(
        db.playHistory,
      )..orderBy([(t) => OrderingTerm.desc(t.playedAt)])).get();
      expect(rows.first.trackId, 'jiosaavn:2');
      expect(rows, hasLength(2));
    });

    test('stores user playlists and ordered songs', () async {
      await db
          .into(db.playlists)
          .insert(
            PlaylistsCompanion.insert(
              id: 'pl-1',
              name: 'Road trip',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          );
      await db.batch((b) {
        b.insertAll(db.playlistSongs, [
          PlaylistSongsCompanion.insert(
            playlistId: 'pl-1',
            trackId: 'jiosaavn:1',
            title: 'A',
            artist: 'X',
            position: 0,
          ),
          PlaylistSongsCompanion.insert(
            playlistId: 'pl-1',
            trackId: 'jiosaavn:2',
            title: 'B',
            artist: 'Y',
            position: 1,
          ),
        ]);
      });

      final rows =
          await (db.select(db.playlistSongs)
                ..where((t) => t.playlistId.equals('pl-1'))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      expect(rows.map((r) => r.trackId), ['jiosaavn:1', 'jiosaavn:2']);
    });

    test('cascade deletes playlist songs with their playlist', () async {
      await db
          .into(db.playlists)
          .insert(
            PlaylistsCompanion.insert(
              id: 'pl-1',
              name: 'Road trip',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          );
      await db
          .into(db.playlistSongs)
          .insert(
            PlaylistSongsCompanion.insert(
              playlistId: 'pl-1',
              trackId: 'jiosaavn:1',
              title: 'A',
              artist: 'X',
              position: 0,
            ),
          );

      await (db.delete(db.playlists)..where((t) => t.id.equals('pl-1'))).go();

      expect(await db.select(db.playlistSongs).get(), isEmpty);
    });

    test('search history is unique per query', () async {
      await db
          .into(db.searchHistoryEntries)
          .insertOnConflictUpdate(
            SearchHistoryEntriesCompanion.insert(
              query: 'arijit',
              searchedAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
            ),
          );
      await db
          .into(db.searchHistoryEntries)
          .insertOnConflictUpdate(
            SearchHistoryEntriesCompanion.insert(
              query: 'arijit',
              searchedAt: DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
            ),
          );

      expect(await db.select(db.searchHistoryEntries).get(), hasLength(1));
    });
  });

  group('AppDatabase migrations', () {
    test(
      'upgrades a v1 database to v3, adding library/cache tables and keeping data',
      () async {
        final dir = await Directory.systemTemp.createTemp('aura_db_migration');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/aura.sqlite');

        final v2 = AppDatabase(NativeDatabase(file));
        await v2
            .into(v2.downloadEntries)
            .insert(
              DownloadEntriesCompanion.insert(
                trackId: 'jiosaavn:1',
                title: 'Kesariya',
                artist: 'Arijit Singh',
                status: DownloadStatus.completed,
                createdAt: DateTime.utc(2026, 1, 1),
              ),
            );

        for (final table in [
          'playlist_songs',
          'playlists',
          'liked_songs',
          'history',
          'search_history',
          'api_cache_entries',
        ]) {
          await v2.customStatement('DROP TABLE IF EXISTS $table');
        }
        for (final index in ['history_played_at', 'playlist_songs_position']) {
          await v2.customStatement('DROP INDEX IF EXISTS $index');
        }
        await v2.customStatement('PRAGMA user_version = 1');
        await v2.close();

        final upgraded = AppDatabase(NativeDatabase(file));
        addTearDown(upgraded.close);
        await upgraded.customSelect('SELECT 1').get();

        expect(upgraded.schemaVersion, 3);
        expect(
          await upgraded.select(upgraded.downloadEntries).get(),
          hasLength(1),
        );

        await upgraded
            .into(upgraded.likedSongs)
            .insert(
              LikedSongsCompanion.insert(
                trackId: 'jiosaavn:2',
                title: 'Apna Bana Le',
                artist: 'Arijit Singh',
                likedAt: DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
              ),
            );
        expect(await upgraded.select(upgraded.likedSongs).get(), hasLength(1));

        final index = await upgraded
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'history_played_at'",
            )
            .getSingleOrNull();
        expect(index, isNotNull);
      },
    );
  });
}
