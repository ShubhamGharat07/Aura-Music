import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/utils/ttl_cache.dart';
import 'package:aura_music/features/catalog/data/mappers/jiosaavn_mapper.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_album_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_artist_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_genre_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_playlist_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_song_model.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// JioSaavn client (data layer only): catalog search, curated feed, detail
/// pages and inline stream resolution.
///
/// JioSaavn's public `api.php` returns JSON under a `text/html` content-type,
/// so bodies are read as text and decoded explicitly. Mapping lives in
/// [JiosaavnMapper]; this class only talks HTTP.

/// Thin wrapper over the JioSaavn public API.
final class JiosaavnRemoteDataSource {
  /// Creates the data source.
  JiosaavnRemoteDataSource(this._dio);

  final Dio _dio;

  static const JiosaavnMapper _mapper = JiosaavnMapper();

  /// Editorially curated queries that make up the keyless home feed.
  static const List<String> _editorialQueries = <String>[
    'Top Hits',
    'Trending Now',
  ];

  /// Key of the memoised launch payload in [_launchCache].
  static const String _launchKey = 'launch';

  /// The launch payload is editorial, so one fetch serves a whole session.
  static const Duration _launchTtl = Duration(minutes: 30);

  /// Songs / albums requested for an artist page (the catalog caps both).
  static const int _artistSongLimit = 500;
  static const int _artistAlbumLimit = 100;

  /// Bodies up to this size are decoded on the calling isolate; bigger ones go
  /// to a background isolate (spawning one is not worth it for tiny payloads).
  static const int _inlineDecodeLimit = 16 * 1024;

  /// Memoised `webapi.getLaunchData` payload (mood / genre row + artist row).
  final TtlCache<String, Map<String, dynamic>> _launchCache =
      TtlCache<String, Map<String, dynamic>>(ttl: _launchTtl);

  Future<Map<String, dynamic>>? _launchPending;

  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
    'X-Forwarded-For': '49.36.0.1',
    'X-Real-IP': '49.36.0.1',
    'Accept-Language': 'en-IN,en;q=0.9',
    'Cookie': 'explicit_content=1',
  };

  /// Full-text song search.
  Future<List<Track>> search(String query, {int limit = 30}) async => _tracks(
    (await _get(_searchCall('search.getResults', query, limit)))['results'],
  );

  /// Curated home feed, merged from [_editorialQueries] and de-duplicated.
  /// The queries run in parallel and merge in order, so the first paint waits
  /// for one round trip instead of one per query.
  Future<List<Track>> trending({int limit = 40}) async {
    AppException? lastError;
    final batches = await Future.wait(
      _editorialQueries.map((query) async {
        try {
          return await search(query, limit: limit);
        } on AppException catch (error) {
          lastError = error;
          return const <Track>[];
        }
      }),
    );

    final merged = <String, Track>{};
    for (final tracks in batches) {
      for (final track in tracks) {
        merged.putIfAbsent(track.id, () => track);
      }
    }
    if (merged.isEmpty && lastError != null) throw lastError!;
    return merged.values.take(limit).toList(growable: false);
  }

  /// Album matches for [query] (`search.getAlbumResults`).
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async =>
      JiosaavnAlbumModel.listFrom(
        (await _get(
          _searchCall('search.getAlbumResults', query, limit),
        ))['results'],
      ).map(_mapper.album).toList(growable: false);

  /// Artist matches for [query] (`search.getArtistResults`).
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async =>
      JiosaavnArtistModel.listFrom(
        (await _get(
          _searchCall('search.getArtistResults', query, limit),
        ))['results'],
      ).map(_mapper.artist).toList(growable: false);

  /// Playlist matches for [query] (`search.getPlaylistResults`).
  Future<List<Playlist>> searchPlaylists(
    String query, {
    int limit = 20,
  }) async => JiosaavnPlaylistModel.listFrom(
    (await _get(
      _searchCall('search.getPlaylistResults', query, limit),
    ))['results'],
  ).map(_mapper.playlist).toList(growable: false);

  /// Curated playlists for a catalog language code (e.g. `marathi`).
  ///
  /// `content.getFeaturedPlaylists` is the API's only language-aware browse
  /// call: it filters on `languages` and returns the playlists under `data`.
  Future<List<Playlist>> languagePlaylists(
    String language, {
    int limit = 10,
  }) async => JiosaavnPlaylistModel.listFrom(
    (await _get(<String, dynamic>{
      '__call': 'content.getFeaturedPlaylists',
      'languages': language,
      'n': '$limit',
    }))['data'],
  ).map(_mapper.playlist).toList(growable: false);

  /// Latest album releases (`content.getAlbums`).
  ///
  /// The call answers with a mixed "new releases" feed (albums + singles), so
  /// only the album nodes survive: their ids are the ones
  /// `content.getAlbumDetails` can resolve.
  Future<List<Album>> newAlbums({int limit = 30}) async =>
      JiosaavnAlbumModel.listFrom(
            (await _get(<String, dynamic>{
              '__call': 'content.getAlbums',
              'p': '1',
              'n': '$limit',
            }))['data'],
          )
          .where((model) => model.isAlbum)
          .map(_mapper.album)
          .toList(growable: false);

  /// Trending albums (`content.getTrending`).
  ///
  /// This call answers with a bare JSON array holding albums, singles and
  /// playlists; only the albums are kept.
  Future<List<Album>> trendingAlbums({int limit = 24}) async =>
      JiosaavnAlbumModel.listFrom(
            await _getList(const <String, dynamic>{
              '__call': 'content.getTrending',
            }),
          )
          .where((model) => model.isAlbum)
          .take(limit)
          .map(_mapper.album)
          .toList(growable: false);

  /// Mood / genre channels offered by the catalog (`webapi.getLaunchData`).
  ///
  /// The public API has no dedicated genre endpoint, so the channels come from
  /// JioSaavn's own browse catalog (`browse_discover`). Podcast and seasonality
  /// promos are dropped, and the channels carrying a genuine mood / genre tag
  /// are listed first so the filter row opens with the popular filters.
  Future<List<Genre>> genres() async {
    final json = await _launch();
    final models = JiosaavnGenreModel.listFrom(
      json['browse_discover'],
    ).where((model) => model.isBrowsable).toList(growable: false);
    final ordered = <JiosaavnGenreModel>[
      ...models.where((model) => model.isTaggedMoodOrGenre),
      ...models.where((model) => !model.isTaggedMoodOrGenre),
    ];
    return ordered.map(_mapper.genre).toList(growable: false);
  }

  /// Popular artists for the home artist row (`webapi.getLaunchData`).
  ///
  /// The catalog ships no artist-list endpoint, so the row is fed by the
  /// launch payload's own recommendations (`artist_recos`); their ids are
  /// artist-page ids, not radio ids.
  Future<List<Artist>> popularArtists({int limit = 20}) async {
    final json = await _launch();
    return JiosaavnArtistModel.listFrom(
      json['artist_recos'],
    ).take(limit).map(_mapper.artist).toList(growable: false);
  }

  /// Memoised launch payload. The mood row and the artist row both read it, so
  /// they share a single round trip instead of firing two identical calls on
  /// the first Home paint.
  Future<Map<String, dynamic>> _launch() async {
    final cached = _launchCache.get(_launchKey);
    if (cached != null) return cached;
    final pending = _launchPending;
    if (pending != null) return pending;
    final future = _get(const <String, dynamic>{
      '__call': 'webapi.getLaunchData',
    });
    _launchPending = future;
    try {
      final json = await future;
      _launchCache.set(_launchKey, json);
      return json;
    } finally {
      _launchPending = null;
    }
  }

  /// Full album (metadata + ordered songs) by raw JioSaavn [id].
  Future<AlbumDetail> album(String id) async => _mapper.albumDetail(
    JiosaavnAlbumDetailModel.fromJson(
      await _get(<String, dynamic>{
        '__call': 'content.getAlbumDetails',
        'albumid': id,
      }),
    ),
  );

  /// Full playlist (metadata + ordered songs) by raw JioSaavn [id].
  Future<PlaylistDetail> playlist(String id) async => _mapper.playlistDetail(
    JiosaavnPlaylistDetailModel.fromJson(
      await _get(<String, dynamic>{
        '__call': 'playlist.getDetails',
        'listid': id,
      }),
    ),
  );

  /// Full artist page by raw JioSaavn [id].
  ///
  /// The call defaults to a 10-song / 12-album teaser, so the page is asked for
  /// the whole editorial set instead ([_artistSongLimit] / [_artistAlbumLimit]);
  /// the catalog caps it per artist (roughly 33-60 songs).
  Future<ArtistDetail> artist(String id) async => _mapper.artistDetail(
    JiosaavnArtistDetailModel.fromJson(
      await _get(<String, dynamic>{
        '__call': 'artist.getArtistPageDetails',
        'artistId': id,
        'n_song': '$_artistSongLimit',
        'n_album': '$_artistAlbumLimit',
      }),
    ),
  );

  /// Resolves a fresh stream URL for a JioSaavn song [id] (`song.getDetails`).
  ///
  /// Used by the stream-resolver fallback chain when a track lacks an inline
  /// URL. Returns null when the song carries no media URL.
  Future<String?> streamUrlFor(String id) async {
    final songs = JiosaavnSongModel.listFrom(
      (await _get(<String, dynamic>{
        '__call': 'song.getDetails',
        'pids': id,
      }))['songs'],
    );
    if (songs.isEmpty) return null;
    return _mapper.streamUrl(songs.first);
  }

  Map<String, dynamic> _searchCall(String call, String query, int limit) =>
      <String, dynamic>{'__call': call, 'q': query, 'p': '1', 'n': '$limit'};

  List<Track> _tracks(Object? raw) => JiosaavnSongModel.listFrom(
    raw,
  ).map(_mapper.track).toList(growable: false);

  Future<Map<String, dynamic>> _get(Map<String, dynamic> call) async {
    final decoded = await _request(call);
    return decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
  }

  /// Reads a call whose payload is a bare JSON array (`content.getTrending`).
  Future<List<dynamic>> _getList(Map<String, dynamic> call) async {
    final decoded = await _request(call);
    return decoded is List ? decoded : const <dynamic>[];
  }

  Future<Object?> _request(Map<String, dynamic> call) async {
    final Response<String> response;
    try {
      response = await _dio.get<String>(
        '/api.php',
        queryParameters: <String, dynamic>{
          '_format': 'json',
          '_marker': '0',
          'api_version': '4',
          'ctx': 'web6dot0',
          ...call,
        },
        options: Options(headers: _headers, responseType: ResponseType.plain),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
    return _decode(response.data);
  }

  /// Decodes a response body, off the UI isolate for anything sizeable.
  ///
  /// A catalog page is 50-200 KB of very verbose JSON: decoding six of them on
  /// the UI isolate (which is what the parallel home sections used to do) costs
  /// tens of milliseconds per page and drops the frames right as the section
  /// lands. [compute] moves that work to a worker isolate.
  Future<Object?> _decode(String? body) async {
    final text = body?.trim() ?? '';
    if (text.isEmpty) return null;
    final decoded = text.length <= _inlineDecodeLimit
        ? _decodeJson(text)
        : await compute(_decodeJson, text);
    if (decoded == null) {
      throw const ServerException('Malformed catalog response');
    }
    return decoded;
  }

  /// Top-level so an isolate can run it; null marks a malformed body.
  static Object? _decodeJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  AppException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        return NetworkException(error.message ?? 'Network unavailable');
      case DioExceptionType.badResponse:
      case DioExceptionType.transformTimeout:
        return ServerException(
          error.message ?? 'Server error',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return ServerException(error.message ?? 'Request failed');
    }
  }
}
