import 'package:drift/drift.dart';

import 'package:aura_music/database/database_opener.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';

part 'app_database.g.dart';

// Drift schema (PRD 13). Local-first: track cache + offline downloads.
// Opened encrypted (PRD 9.2); see database_opener.dart for the key +
// one-time plaintext migration.

/// Cached track metadata (offline browse / instant startup).
class CachedTracks extends Table {
  /// Stable source id.
  TextColumn get id => text()();

  /// Track title.
  TextColumn get title => text()();

  /// Primary artist.
  TextColumn get artist => text()();

  /// Album name.
  TextColumn get album => text().nullable()();

  /// Artwork URL.
  TextColumn get artUrl => text().nullable()();

  /// Length in milliseconds.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// Last resolved stream URL (may expire).
  TextColumn get streamUrl => text().nullable()();

  /// Row write time.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline downloads (PRD S14). Self-sufficient snapshot per track.
class DownloadEntries extends Table {
  @override
  String get tableName => 'downloads';

  /// Track id (owner).
  TextColumn get trackId => text()();

  /// Track title.
  TextColumn get title => text()();

  /// Primary artist.
  TextColumn get artist => text()();

  /// Album name.
  TextColumn get album => text().nullable()();

  /// Artwork URL.
  TextColumn get artUrl => text().nullable()();

  /// Length in milliseconds.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// [DownloadStatus] ordinal.
  IntColumn get status => intEnum<DownloadStatus>()();

  /// Absolute path to the local file.
  TextColumn get filePath => text().nullable()();

  /// Bytes written so far.
  IntColumn get bytesDownloaded => integer().withDefault(const Constant(0))();

  /// Total bytes (0 until known).
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();

  /// Row create time.
  DateTimeColumn get createdAt => dateTime()();

  /// Completion time.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Last error message.
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {trackId};
}

/// Liked songs (PRD 13 `liked_songs`). Denormalised snapshot so the list is
/// usable offline without joining the track cache.
class LikedSongs extends Table {
  /// Stable source id.
  TextColumn get trackId => text()();

  /// Track title.
  TextColumn get title => text()();

  /// Primary artist.
  TextColumn get artist => text()();

  /// Album name.
  TextColumn get album => text().nullable()();

  /// Artwork URL.
  TextColumn get artUrl => text().nullable()();

  /// Length in milliseconds.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// Last resolved stream URL (may expire).
  TextColumn get streamUrl => text().nullable()();

  /// When the track was liked (epoch milliseconds - precise recency order).
  IntColumn get likedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId};
}

/// Play history (PRD 13 `history`), one row per playback.
@TableIndex(name: 'history_played_at', columns: {#playedAt})
class PlayHistory extends Table {
  @override
  String get tableName => 'history';

  /// Auto-increment row id.
  IntColumn get id => integer().autoIncrement()();

  /// Stable source id.
  TextColumn get trackId => text()();

  /// Track title.
  TextColumn get title => text()();

  /// Primary artist.
  TextColumn get artist => text()();

  /// Album name.
  TextColumn get album => text().nullable()();

  /// Artwork URL.
  TextColumn get artUrl => text().nullable()();

  /// Length in milliseconds.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// Last resolved stream URL (may expire).
  TextColumn get streamUrl => text().nullable()();

  /// When the track was played.
  DateTimeColumn get playedAt => dateTime()();

  /// Milliseconds actually listened to.
  IntColumn get playedMs => integer().withDefault(const Constant(0))();
}

/// User-created playlists (PRD 13 `playlists`).
class Playlists extends Table {
  /// Local uuid (also used for routing).
  TextColumn get id => text()();

  /// Playlist name.
  TextColumn get name => text()();

  /// Optional description.
  TextColumn get description => text().nullable()();

  /// Cover art URL (defaults to first song art).
  TextColumn get artUrl => text().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime()();

  /// Last mutation time (drives sort).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ordered membership of tracks in [Playlists] (PRD 13 `playlist_songs`).
@TableIndex(name: 'playlist_songs_position', columns: {#playlistId, #position})
class PlaylistSongs extends Table {
  /// Owning playlist (cascade-deleted with it).
  TextColumn get playlistId =>
      text().references(Playlists, #id, onDelete: KeyAction.cascade)();

  /// Stable source id.
  TextColumn get trackId => text()();

  /// Track title.
  TextColumn get title => text()();

  /// Primary artist.
  TextColumn get artist => text()();

  /// Album name.
  TextColumn get album => text().nullable()();

  /// Artwork URL.
  TextColumn get artUrl => text().nullable()();

  /// Length in milliseconds.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  /// Last resolved stream URL (may expire).
  TextColumn get streamUrl => text().nullable()();

  /// Zero-based order within the playlist.
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

/// Recent search queries (PRD 13 `search_history`).
class SearchHistoryEntries extends Table {
  @override
  String get tableName => 'search_history';

  /// The searched query (unique per query).
  TextColumn get query => text()();

  /// When the query was last issued (epoch milliseconds).
  IntColumn get searchedAt => integer()();

  @override
  Set<Column> get primaryKey => {query};
}

/// Generic remote-response snapshots (JSON payloads) for offline / fast start.
///
/// Keys are data-layer cache keys (`home:trending:20`, `album:<id>`, ...).
class ApiCacheEntries extends Table {
  /// Cache key.
  TextColumn get cacheKey => text().named('cache_key')();

  /// JSON-encoded response snapshot.
  TextColumn get payload => text()();

  /// Row write time.
  DateTimeColumn get storedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

/// Aura's local database.
@DriftDatabase(
  tables: [
    CachedTracks,
    DownloadEntries,
    LikedSongs,
    PlayHistory,
    Playlists,
    PlaylistSongs,
    SearchHistoryEntries,
    ApiCacheEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database (or a custom [executor] in tests).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openAuraDatabase());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(likedSongs);
        await m.createTable(playHistory);
        await m.createTable(playlists);
        await m.createTable(playlistSongs);
        await m.createTable(searchHistoryEntries);
        await m.createIndex(historyPlayedAt);
        await m.createIndex(playlistSongsPosition);
      }
      if (from < 3) {
        await m.createTable(apiCacheEntries);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
