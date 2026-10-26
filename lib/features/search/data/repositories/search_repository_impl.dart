import 'package:drift/drift.dart' show Value;
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/database/app_database.dart'
    show CachedTrack, CachedTracksCompanion;
import 'package:aura_music/database/daos/cached_tracks_dao.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/domain/entities/search_results.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';

/// [SearchRepository] implementation over the shared JioSaavn client. Combines
/// the four type queries into one [SearchResults]; [guardRemote] maps
/// data-layer exceptions at the boundary.
///
/// Offline fallback: successful song results are mirrored into `cached_tracks`,
/// so when the network is down the same query still returns songs from the last
/// successful search instead of an empty error screen.

/// Multi-type JioSaavn search with a local fallback.
final class SearchRepositoryImpl implements SearchRepository {
  /// Creates the repository.
  const SearchRepositoryImpl(this._remote, {CachedTracksDao? cache})
    : _cache = cache;

  final JiosaavnRemoteDataSource _remote;
  final CachedTracksDao? _cache;

  @override
  Future<Either<Failure, SearchResults>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Right(SearchResults());
    final remote = await guardRemote(() async {
      // The four type queries are independent, so one round trip's worth of
      // latency covers all of them instead of four sequential waits.
      final responses = await Future.wait(<Future<Object>>[
        _remote.search(trimmed, limit: 30),
        _remote.searchAlbums(trimmed, limit: 20),
        _remote.searchArtists(trimmed, limit: 20),
        _remote.searchPlaylists(trimmed, limit: 20),
      ]);
      final songs = responses[0] as List<Track>;
      await _cacheSongs(songs);
      return SearchResults(
        songs: songs,
        albums: responses[1] as List<Album>,
        artists: responses[2] as List<Artist>,
        playlists: responses[3] as List<Playlist>,
      );
    });
    if (remote.isRight()) return remote;
    final cached = await _cachedSongs(trimmed);
    if (cached.isEmpty) return remote;
    return Right(SearchResults(songs: cached));
  }

  @override
  Future<Either<Failure, List<Track>>> suggestions(
    String query, {
    int limit = 8,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Right(<Track>[]));
    return guardRemote(() => _remote.search(trimmed, limit: limit));
  }

  @override
  Future<Either<Failure, List<Track>>> browse({int limit = 10}) =>
      guardRemote(() async {
        // Pull a wider window than we show, then rank by lifetime plays so the
        // idle list behaves like a "most played" chart.
        final tracks = await _remote.trending(limit: limit * 2);
        final ranked = tracks.toList()
          ..sort((a, b) => b.playCount.compareTo(a.playCount));
        return ranked.take(limit).toList(growable: false);
      });

  Future<void> _cacheSongs(List<Track> songs) async {
    final cache = _cache;
    if (cache == null || songs.isEmpty) return;
    final now = DateTime.now();
    try {
      await cache.upsertAll(songs.map((track) => _companion(track, now)));
    } on Object {
      // The cache is a convenience: never fail a search because of it.
    }
  }

  Future<List<Track>> _cachedSongs(String query) async {
    final cache = _cache;
    if (cache == null) return const <Track>[];
    try {
      final rows = await cache.search(query);
      return rows.map(_toTrack).toList(growable: false);
    } on Object {
      return const <Track>[];
    }
  }

  CachedTracksCompanion _companion(Track track, DateTime now) =>
      CachedTracksCompanion.insert(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: Value(track.album),
        artUrl: Value(track.artUrl),
        durationMs: Value(track.duration.inMilliseconds),
        streamUrl: Value(track.streamUrl),
        updatedAt: now,
      );

  Track _toTrack(CachedTrack row) => Track(
    id: row.id,
    title: row.title,
    artist: row.artist,
    album: row.album,
    artUrl: row.artUrl,
    duration: Duration(milliseconds: row.durationMs),
    streamUrl: row.streamUrl,
  );
}
