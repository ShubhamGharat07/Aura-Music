import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/utils/des_ecb.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';

import '../../helpers/fake_dio.dart';

/// Encrypts [plain] the way JioSaavn serves `encrypted_media_url`.
String encrypted(String plain) {
  const key = '38346591';
  final bytes = Uint8List.fromList(utf8.encode(plain));
  final pad = 8 - (bytes.length % 8);
  final padded = Uint8List(bytes.length + pad)
    ..setRange(0, bytes.length, bytes);
  for (var i = bytes.length; i < padded.length; i++) {
    padded[i] = pad;
  }
  return base64.encode(
    DesEcb.encryptBytes(padded, Uint8List.fromList(utf8.encode(key))),
  );
}

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  Map<String, dynamic> payload() => {
    'results': [
      {
        'id': 'abc',
        'title': '  Neon   Horizon ',
        'image': 'http://c.saavncdn.com/x/song-150x150.jpg',
        'more_info': {
          'duration': '215',
          'album': 'Nightfall',
          'encrypted_media_url': encrypted(
            'https://aac.saavncdn.com/123/song_96.mp4',
          ),
          'artistMap': {
            'primary_artists': [
              {'id': '1', 'name': 'Aurora Skies'},
            ],
          },
        },
      },
    ],
  };

  JiosaavnRemoteDataSource sourceWith(FakeHttpAdapter adapter) =>
      JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl));

  test(
    'search maps fields, decrypts the 320 kbps stream and sends params',
    () async {
      final adapter = FakeHttpAdapter((_) async => jsonResponse(payload()));
      final source = sourceWith(adapter);

      final tracks = await source.search('neon', limit: 7);

      final track = tracks.single;
      expect(track.id, 'jiosaavn:abc');
      expect(track.title, 'Neon Horizon');
      expect(track.artist, 'Aurora Skies');
      expect(track.album, 'Nightfall');
      expect(track.artUrl, 'https://c.saavncdn.com/x/song-500x500.jpg');
      expect(track.duration, const Duration(seconds: 215));
      expect(track.streamUrl, 'https://aac.saavncdn.com/123/song_320.mp4');

      final request = adapter.requests.single;
      expect(request.path, '/api.php');
      expect(request.queryParameters['__call'], 'search.getResults');
      expect(request.queryParameters['q'], 'neon');
      expect(request.queryParameters['n'], '7');
      expect(request.queryParameters['_format'], 'json');
      expect(request.queryParameters['ctx'], 'web6dot0');
      expect(request.headers['Cookie'], 'explicit_content=1');
    },
  );

  test('trending merges editorial queries and de-duplicates by id', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(payload()));
    final source = sourceWith(adapter);

    final tracks = await source.trending(limit: 40);

    expect(tracks, hasLength(1));
    expect(adapter.requests.length, 2);
    expect(
      adapter.requests.map((r) => r.queryParameters['q']),
      containsAll(<String>['Top Hits', 'Trending Now']),
    );
  });

  test('missing results key yields an empty list', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'results': null}),
    );
    expect(await sourceWith(adapter).search('x'), isEmpty);
  });

  test('parses JSON even when the server mislabels it as text/html', () async {
    final adapter = FakeHttpAdapter(
      (_) async =>
          jsonResponse(payload(), contentType: 'text/html; charset=UTF-8'),
    );

    final tracks = await sourceWith(adapter).search('neon');

    expect(tracks, hasLength(1));
    expect(tracks.single.id, 'jiosaavn:abc');
    expect(
      tracks.single.streamUrl,
      'https://aac.saavncdn.com/123/song_320.mp4',
    );
  });

  test('maps a non-JSON body to ServerException', () async {
    final adapter = FakeHttpAdapter(
      (_) async =>
          jsonResponse('<html>rate limited</html>', contentType: 'text/html'),
    );
    await expectLater(
      sourceWith(adapter).search('x'),
      throwsA(isA<ServerException>()),
    );
  });

  test('maps a 5xx response to ServerException', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'e': 'boom'}, status: 503),
    );
    await expectLater(
      sourceWith(adapter).search('x'),
      throwsA(isA<ServerException>()),
    );
  });

  test('maps a transport failure to NetworkException', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('socket'));
    await expectLater(
      sourceWith(adapter).search('x'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('a song without an encrypted url still maps (null stream)', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'results': [
          {'id': 'z', 'title': 'Plain', 'more_info': <String, dynamic>{}},
        ],
      }),
    );

    final track = (await sourceWith(adapter).search('x')).single;

    expect(track.title, 'Plain');
    expect(track.artist, 'Unknown artist');
    expect(track.streamUrl, isNull);
  });

  test('searchAlbums maps album fields', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'results': [
          {
            'id': 'al1',
            'title': 'Nightfall',
            'image': 'http://c.saavncdn.com/a-150x150.jpg',
            'more_info': {
              'release_date': '2021-08-13',
              'song_count': '9',
              'artistMap': {
                'primary_artists': [
                  {'id': '1', 'name': 'Aurora Skies'},
                ],
              },
            },
          },
        ],
      }),
    );

    final albums = await sourceWith(adapter).searchAlbums('night', limit: 5);

    final album = albums.single;
    expect(album.id, 'al1');
    expect(album.title, 'Nightfall');
    expect(album.artist, 'Aurora Skies');
    expect(album.artUrl, 'https://c.saavncdn.com/a-500x500.jpg');
    expect(album.year, 2021);
    expect(album.songCount, 9);
    expect(
      adapter.requests.single.queryParameters['__call'],
      'search.getAlbumResults',
    );
    expect(adapter.requests.single.queryParameters['n'], '5');
  });

  test('searchArtists maps artist fields', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'results': [
          {
            'id': 'ar1',
            'name': 'Arijit Singh',
            'image': 'http://c.saavncdn.com/ar-150x150.jpg',
            'role': 'Singer',
          },
        ],
      }),
    );

    final artists = await sourceWith(adapter).searchArtists('arijit');

    final artist = artists.single;
    expect(artist.id, 'ar1');
    expect(artist.name, 'Arijit Singh');
    expect(artist.imageUrl, 'https://c.saavncdn.com/ar-500x500.jpg');
    expect(artist.role, 'Singer');
    expect(
      adapter.requests.single.queryParameters['__call'],
      'search.getArtistResults',
    );
  });

  test('searchPlaylists maps playlist fields', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'results': [
          {
            'id': 'pl1',
            'title': 'Romance',
            'image': 'http://c.saavncdn.com/p-150x150.jpg',
            'subtitle': 'Best of',
            'list_count': '20',
          },
        ],
      }),
    );

    final playlists = await sourceWith(adapter).searchPlaylists('romance');

    final playlist = playlists.single;
    expect(playlist.id, 'pl1');
    expect(playlist.title, 'Romance');
    expect(playlist.artUrl, 'https://c.saavncdn.com/p-500x500.jpg');
    expect(playlist.subtitle, 'Best of');
    expect(playlist.songCount, 20);
    expect(
      adapter.requests.single.queryParameters['__call'],
      'search.getPlaylistResults',
    );
  });

  test(
    'newAlbums keeps the album nodes and drops the day\'s singles',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(<String, dynamic>{
          'data': <dynamic>[
            {
              'id': '82064668',
              'type': 'album',
              'title': 'Udta Teer',
              'language': 'hindi',
              'image': 'http://c.saavncdn.com/a-150x150.jpg',
              'more_info': <String, dynamic>{'song_count': '5'},
            },
            {
              'id': 'dt9E21DY',
              'type': 'song',
              'title': 'Do Din Ki Zindagi',
              'language': 'hindi',
            },
          ],
        }),
      );

      final albums = await sourceWith(adapter).newAlbums(limit: 30);

      expect(albums.single.title, 'Udta Teer');
      expect(albums.single.id, '82064668');
      expect(albums.single.language, 'hindi');
      expect(albums.single.songCount, 5);
      final request = adapter.requests.single;
      expect(request.queryParameters['__call'], 'content.getAlbums');
      expect(request.queryParameters['n'], '30');
      expect(request.queryParameters['p'], '1');
    },
  );

  test('trendingAlbums reads the bare array and keeps only albums', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(<dynamic>[
        <String, dynamic>{
          'id': '79121261',
          'type': 'album',
          'title': 'Awarapan 2',
          'language': 'hindi',
          'more_info': <String, dynamic>{'song_count': '8'},
        },
        <String, dynamic>{'id': '99', 'type': 'playlist', 'title': 'Top 50'},
        <String, dynamic>{'id': 'x1', 'type': 'song', 'title': 'Single'},
      ]),
    );

    final albums = await sourceWith(adapter).trendingAlbums();

    expect(albums.map((album) => album.title), ['Awarapan 2']);
    expect(albums.single.songCount, 8);
    expect(
      adapter.requests.single.queryParameters['__call'],
      'content.getTrending',
    );
  });

  test(
    'languagePlaylists filters on languages and reads the data key',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(<String, dynamic>{
          'data': <dynamic>[
            {
              'id': 'pl9',
              'title': "Let's Play - Ajay-Atul - Marathi",
              'image': 'http://c.saavncdn.com/p-150x150.jpg',
              'more_info': <String, dynamic>{'song_count': '50'},
            },
          ],
        }),
      );

      final playlists = await sourceWith(
        adapter,
      ).languagePlaylists('marathi', limit: 5);

      expect(playlists.single.id, 'pl9');
      expect(playlists.single.title, "Let's Play - Ajay-Atul - Marathi");
      expect(playlists.single.songCount, 50);
      final request = adapter.requests.single;
      expect(request.queryParameters['__call'], 'content.getFeaturedPlaylists');
      expect(request.queryParameters['languages'], 'marathi');
      expect(request.queryParameters['n'], '5');
    },
  );

  test(
    'genres keeps mood / genre channels and lists genuine tags first',
    () async {
      Map<String, dynamic> entry(
        String id,
        String title,
        String subType,
        Object? tags,
      ) => <String, dynamic>{
        'id': id,
        'title': title,
        'image': 'http://c.saavncdn.com/g-150x150.jpg',
        'more_info': <String, dynamic>{'sub_type': subType, 'tags': tags},
      };

      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(<String, dynamic>{
          'browse_discover': <dynamic>[
            entry('193', 'Carvaan', 'mood', <String, dynamic>{
              'situation': <dynamic>['Saregama'],
            }),
            entry('46', 'The 1990s', 'mood', <String, dynamic>{
              'seasonality': <dynamic>['1990s'],
            }),
            entry('142', 'Podsnacks', 'music_plus', <dynamic>[]),
            entry('16', '  Chill ', 'mood', <String, dynamic>{
              'mood': <dynamic>['Chill'],
            }),
            entry('15', 'Pop', 'genre', <String, dynamic>{
              'genre': <dynamic>['Pop'],
            }),
          ],
        }),
      );

      final genres = await sourceWith(adapter).genres();

      expect(genres.map((genre) => genre.name), <String>[
        'Chill',
        'Pop',
        'Carvaan',
      ]);
      expect(genres.first.id, '16');
      expect(genres.first.artUrl, 'https://c.saavncdn.com/g-500x500.jpg');
      expect(
        adapter.requests.single.queryParameters['__call'],
        'webapi.getLaunchData',
      );
    },
  );

  Map<String, dynamic> recos(
    String id,
    String title, {
    bool radio = true,
  }) => <String, dynamic>{
    'id': id,
    'title': title,
    'subtitle': 'Artist Radio',
    'type': radio ? 'radio_station' : 'artist',
    'image':
        'http://c.saavncdn.com/artists/${title.replaceAll(' ', '_')}_150x150.jpg',
  };

  test(
    'popularArtists maps the launch recommendations and honours the limit',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(<String, dynamic>{
          'artist_recos': <dynamic>[
            recos('459320', 'Arijit Singh'),
            recos('485956', 'Yo Yo Honey Singh'),
          ],
        }),
      );

      final artists = await sourceWith(adapter).popularArtists(limit: 1);

      final artist = artists.single;
      expect(artist.id, '459320');
      expect(artist.name, 'Arijit Singh');
      expect(
        artist.imageUrl,
        'https://c.saavncdn.com/artists/Arijit_Singh_500x500.jpg',
      );
      expect(
        adapter.requests.single.queryParameters['__call'],
        'webapi.getLaunchData',
      );
    },
  );

  test('the mood row and the artist row share one launch request', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(<String, dynamic>{
        'browse_discover': <dynamic>[
          <String, dynamic>{
            'id': '16',
            'title': 'Chill',
            'image': 'http://c.saavncdn.com/g-150x150.jpg',
            'more_info': <String, dynamic>{
              'sub_type': 'mood',
              'tags': <String, dynamic>{
                'mood': <dynamic>['Chill'],
              },
            },
          },
        ],
        'artist_recos': <dynamic>[recos('459320', 'Arijit Singh')],
      }),
    );
    final source = sourceWith(adapter);

    final genres = await source.genres();
    final artists = await source.popularArtists();

    expect(genres.single.name, 'Chill');
    expect(artists.single.name, 'Arijit Singh');
    expect(adapter.requests, hasLength(1));
  });

  test('album fetches ordered songs from content.getAlbumDetails', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'id': 'al1',
        'title': 'Bhediya',
        'year': '2023',
        'list': [
          {
            'id': 's1',
            'title': 'Thumkeshwari',
            'more_info': <String, dynamic>{},
          },
        ],
      }),
    );

    final detail = await sourceWith(adapter).album('al1');

    expect(detail.album.title, 'Bhediya');
    expect(detail.album.year, 2023);
    expect(detail.songs.single.id, 'jiosaavn:s1');
    expect(detail.songs.single.title, 'Thumkeshwari');
    expect(
      adapter.requests.single.queryParameters['__call'],
      'content.getAlbumDetails',
    );
    expect(adapter.requests.single.queryParameters['albumid'], 'al1');
  });

  test('playlist fetches songs from playlist.getDetails', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'id': 'pl1',
        'title': 'Love',
        'list': [
          {'id': 's1', 'title': 'Song', 'more_info': <String, dynamic>{}},
        ],
      }),
    );

    final detail = await sourceWith(adapter).playlist('pl1');

    expect(detail.playlist.title, 'Love');
    expect(detail.songs, hasLength(1));
    expect(
      adapter.requests.single.queryParameters['__call'],
      'playlist.getDetails',
    );
    expect(adapter.requests.single.queryParameters['listid'], 'pl1');
  });

  test('artist page maps top songs, albums and bio', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'artistId': 'ar1',
        'name': 'Arijit Singh',
        'image': 'http://c.saavncdn.com/a-150x150.jpg',
        'follower_count': '1000',
        'bio': ['Eclectic singer.'],
        'topSongs': [
          {'id': 's1', 'title': 'Kesariya', 'more_info': <String, dynamic>{}},
        ],
        'topAlbums': [
          {'id': 'al1', 'title': 'Brahmastra'},
        ],
      }),
    );

    final detail = await sourceWith(adapter).artist('ar1');

    expect(detail.artist.id, 'ar1');
    expect(detail.artist.name, 'Arijit Singh');
    expect(detail.artist.imageUrl, 'https://c.saavncdn.com/a-500x500.jpg');
    expect(detail.topSongs.single.title, 'Kesariya');
    expect(detail.albums.single.title, 'Brahmastra');
    expect(detail.followerCount, 1000);
    expect(detail.bio, 'Eclectic singer.');
    expect(
      adapter.requests.single.queryParameters['__call'],
      'artist.getArtistPageDetails',
    );
    expect(adapter.requests.single.queryParameters['artistId'], 'ar1');
    expect(adapter.requests.single.queryParameters['n_song'], '500');
    expect(adapter.requests.single.queryParameters['n_album'], '100');
  });
}
