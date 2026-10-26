import 'dart:async';

import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/data/persistent_cache.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/core/utils/ttl_cache.dart';
import 'package:aura_music/features/catalog/data/cache/catalog_cache_codec.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// [HomeRepository] implementation over the JioSaavn catalog. Each section is
/// an independent call so a failure in one leaves the others usable, and a
/// short-lived cache stops the feed from re-hitting the network every time the
/// user returns to Home.
///
/// The catalog has no "genre songs" endpoint, so a mood / genre section is
/// resolved as a playlist search followed by the top curated playlist's songs.

/// JioSaavn-backed home feed repository.
final class HomeRepositoryImpl implements HomeRepository {
  /// Creates the repository. Caches are injectable for tests.
  HomeRepositoryImpl(
    this._remote, {
    TtlCache<String, List<Track>>? cache,
    TtlCache<String, List<Genre>>? genresCache,
    TtlCache<String, List<Album>>? albumsCache,
    TtlCache<String, List<Artist>>? artistsCache,
    PersistentCache? persistentCache,
  }) : _cache = cache ?? TtlCache<String, List<Track>>(ttl: _defaultTtl),
       _genresCache =
           genresCache ?? TtlCache<String, List<Genre>>(ttl: _genresTtl),
       _albumsCache =
           albumsCache ?? TtlCache<String, List<Album>>(ttl: _albumsTtl),
       _artistsCache =
           artistsCache ?? TtlCache<String, List<Artist>>(ttl: _artistsTtl),
       _disk = persistentCache;

  final JiosaavnRemoteDataSource _remote;
  final TtlCache<String, List<Track>> _cache;
  final TtlCache<String, List<Genre>> _genresCache;
  final TtlCache<String, List<Album>> _albumsCache;
  final TtlCache<String, List<Artist>> _artistsCache;
  final PersistentCache? _disk;

  final Map<String, Future<Either<Failure, List<Track>>>> _inFlight = {};
  final Map<String, Future<Either<Failure, List<Genre>>>> _inFlightGenres = {};
  final Map<String, Future<Either<Failure, List<Album>>>> _inFlightAlbums = {};
  final Map<String, Future<Either<Failure, List<Artist>>>> _inFlightArtists =
      {};

  static const String _newReleasesQuery = 'New Releases';
  static const String _genresKey = 'genres';
  static const Duration _defaultTtl = Duration(minutes: 5);
  static const Duration _genresTtl = Duration(hours: 12);
  static const Duration _albumsTtl = Duration(minutes: 20);
  static const Duration _artistsTtl = Duration(hours: 6);
  // Snapshots survive process restarts so an app relaunch within these windows
  // paints from disk without repeating the same catalog calls.
  static const Duration _feedDiskTtl = Duration(hours: 1);
  static const Duration _albumsDiskTtl = Duration(hours: 12);
  static const Duration _editorialDiskTtl = Duration(hours: 24);
  static const int _curatedPlaylistCount = 5;

  @override
  Future<Either<Failure, List<Track>>> trending({int limit = 20}) => _cached(
    'trending:$limit',
    () => _remote.trending(limit: limit),
    diskKey: 'home:trending:$limit',
  );

  @override
  Future<Either<Failure, List<Track>>> newReleases({int limit = 20}) => _cached(
    'new:$limit',
    () => _remote.search(_newReleasesQuery, limit: limit),
    diskKey: 'home:new:$limit',
  );

  @override
  Future<Either<Failure, List<Track>>> byArtist(
    String artist, {
    int limit = 20,
  }) {
    final query = artist.trim();
    if (query.isEmpty) return Future.value(const Right(<Track>[]));
    return _cached(
      'artist:$query:$limit',
      () => _remote.search(query, limit: limit),
      diskKey: 'home:artist:${query.toLowerCase()}:$limit',
    );
  }

  /// Mood / genre filters. Cached for the whole session: the catalog's browse
  /// list is editorial and does not change while the app is open.
  @override
  Future<Either<Failure, List<Genre>>> genres() => _cachedValue(
    _genresCache,
    _inFlightGenres,
    _genresKey,
    _remote.genres,
    diskKey: 'home:genres',
    encode: encodeGenres,
    decode: decodeGenres,
    diskTtl: _editorialDiskTtl,
  );

  /// Songs for one mood / genre: search curated playlists for the channel name
  /// and take the songs of the best-ranked match. One playlist is enough for a
  /// single carousel and keeps the section to two round trips.
  @override
  Future<Either<Failure, List<Track>>> byGenre(Genre genre, {int limit = 20}) {
    final name = genre.name.trim();
    if (name.isEmpty) return Future.value(const Right(<Track>[]));
    return _cached('genre:${genre.id}:$limit', () async {
      final playlists = await _remote.searchPlaylists(
        name,
        limit: _curatedPlaylistCount,
      );
      if (playlists.isEmpty) return const <Track>[];
      final detail = await _remote.playlist(playlists.first.id);
      return detail.songs.take(limit).toList(growable: false);
    }, diskKey: 'home:genre:${genre.id}:$limit');
  }

  /// Songs for one language: the catalog's language-filtered curated playlists,
  /// best-ranked first. Same two round trips as [byGenre], but the API does the
  /// language filtering itself instead of a search.
  @override
  Future<Either<Failure, List<Track>>> byLanguage(
    CatalogLanguage language, {
    int limit = 20,
  }) {
    final code = language.code.trim();
    if (code.isEmpty) return Future.value(const Right(<Track>[]));
    return _cached('lang:$code:$limit', () async {
      final playlists = await _remote.languagePlaylists(
        code,
        limit: _curatedPlaylistCount,
      );
      if (playlists.isEmpty) return const <Track>[];
      final detail = await _remote.playlist(playlists.first.id);
      return detail.songs.take(limit).toList(growable: false);
    }, diskKey: 'home:lang:$code:$limit');
  }

  Future<Either<Failure, List<Track>>> _cached(
    String key,
    Future<List<Track>> Function() load, {
    required String diskKey,
  }) => _cachedValue(
    _cache,
    _inFlight,
    key,
    load,
    diskKey: diskKey,
    encode: encodeTracks,
    decode: decodeTracks,
    diskTtl: _feedDiskTtl,
  );

  /// Latest album releases. Albums ship with the day's singles, so the catalog
  /// side already drops those; this just adds a short cache, since release
  /// days do not change while the app is open.
  @override
  Future<Either<Failure, List<Album>>> newAlbums({int limit = 30}) =>
      _cachedValue(
        _albumsCache,
        _inFlightAlbums,
        'albums:new:$limit',
        () => _remote.newAlbums(limit: limit),
        diskKey: 'home:albums:new:$limit',
        encode: encodeAlbums,
        decode: decodeAlbums,
        diskTtl: _albumsDiskTtl,
      );

  /// Trending albums, cached like [newAlbums].
  @override
  Future<Either<Failure, List<Album>>> trendingAlbums({int limit = 24}) =>
      _cachedValue(
        _albumsCache,
        _inFlightAlbums,
        'albums:trending:$limit',
        () => _remote.trendingAlbums(limit: limit),
        diskKey: 'home:albums:trending:$limit',
        encode: encodeAlbums,
        decode: decodeAlbums,
        diskTtl: _albumsDiskTtl,
      );

  /// Popular artists of the home artist row. Editorial like [genres], so the
  /// list is cached long and shares the launch payload with them.
  @override
  Future<Either<Failure, List<Artist>>> popularArtists({int limit = 20}) =>
      _cachedValue(
        _artistsCache,
        _inFlightArtists,
        'artists:$limit',
        () => _remote.popularArtists(limit: limit),
        diskKey: 'home:artists:$limit',
        encode: encodeArtists,
        decode: decodeArtists,
        diskTtl: _editorialDiskTtl,
      );

  /// Serves [key] from [cache], otherwise runs [load] once. Concurrent callers
  /// for the same key share a single in-flight request instead of firing
  /// duplicates (the startup prefetch and the first Home paint overlap).
  Future<Either<Failure, V>> _cachedValue<V>(
    TtlCache<String, V> cache,
    Map<String, Future<Either<Failure, V>>> inFlight,
    String key,
    Future<V> Function() load, {
    String? diskKey,
    String Function(V value)? encode,
    V Function(String payload)? decode,
    Duration diskTtl = PersistentCache.defaultTtl,
  }) async {
    final hit = cache.get(key);
    if (hit != null) return Right(hit);
    final pending = inFlight[key];
    if (pending != null) return pending;
    if (diskKey != null && decode != null) {
      final stored = await _disk?.read(diskKey, ttl: diskTtl, decode: decode);
      if (stored != null) {
        cache.set(key, stored);
        return Right(stored);
      }
      final raced = inFlight[key];
      if (raced != null) return raced;
    }
    final future = guardRemote(load);
    inFlight[key] = future;
    try {
      final result = await future;
      result.fold((_) {}, (value) {
        cache.set(key, value);
        final storeKey = diskKey;
        final encodeValue = encode;
        if (storeKey != null && encodeValue != null) {
          unawaited(_disk?.write(storeKey, encodeValue(value)));
        }
      });
      return result;
    } finally {
      inFlight.remove(key);
    }
  }
}
