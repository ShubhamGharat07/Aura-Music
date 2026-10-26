import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/data/repositories/home_repository_impl.dart';

import '../../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  HomeRepositoryImpl repoWith(FakeHttpAdapter adapter) => HomeRepositoryImpl(
    JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
  );

  Map<String, dynamic> results(String title) => {
    'results': [
      {'id': 's1', 'title': title, 'more_info': <String, dynamic>{}},
    ],
  };

  test('trending maps tracks and merges the editorial queries', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(results('Neon')));

    final result = await repoWith(adapter).trending(limit: 10);

    expect(
      result.getOrElse((_) => fail('expected Right')).single.title,
      'Neon',
    );
    expect(adapter.requests, hasLength(2));
  });

  test('newReleases queries the catalog for fresh songs', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(results('Fresh')),
    );

    final result = await repoWith(adapter).newReleases(limit: 5);

    expect(
      result.getOrElse((_) => fail('expected Right')).single.title,
      'Fresh',
    );
    expect(adapter.requests.single.queryParameters['q'], 'New Releases');
    expect(adapter.requests.single.queryParameters['n'], '5');
  });

  test('byArtist searches for the seed artist', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(results('Neon')));

    final result = await repoWith(adapter).byArtist('Aurora');

    expect(result.getOrElse((_) => fail('expected Right')), hasLength(1));
    expect(adapter.requests.single.queryParameters['q'], 'Aurora');
  });

  test('byArtist short-circuits a blank artist without a request', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(results('x')));

    final result = await repoWith(adapter).byArtist('   ');

    expect(result.getOrElse((_) => fail('expected Right')), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('maps a transport failure to NetworkFailure', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('offline'));

    final result = await repoWith(adapter).trending();

    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test(
    'serves a repeated call from the cache without a second request',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(results('Fresh')),
      );
      final repo = repoWith(adapter);

      await repo.newReleases(limit: 5);
      final second = await repo.newReleases(limit: 5);

      expect(
        second.getOrElse((_) => fail('expected Right')).single.title,
        'Fresh',
      );
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'coalesces concurrent calls for the same key into one request',
    () async {
      final adapter = FakeHttpAdapter((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return jsonResponse(results('Fresh'));
      });
      final repo = repoWith(adapter);

      final responses = await Future.wait([
        repo.newReleases(limit: 5),
        repo.newReleases(limit: 5),
      ]);

      expect(responses.every((r) => r.isRight()), isTrue);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('does not cache failures', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('offline'));
    final repo = repoWith(adapter);

    await repo.newReleases(limit: 5);
    await repo.newReleases(limit: 5);

    expect(adapter.requests, hasLength(2));
  });

  test('genres maps the browse channels and caches them', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(<String, dynamic>{
        'browse_discover': <dynamic>[
          <String, dynamic>{
            'id': '16',
            'title': 'Chill',
            'more_info': <String, dynamic>{
              'sub_type': 'mood',
              'tags': <String, dynamic>{
                'mood': <dynamic>['Chill'],
              },
            },
          },
        ],
      }),
    );
    final repo = repoWith(adapter);

    final first = await repo.genres();
    final second = await repo.genres();

    expect(first.getOrElse((_) => fail('expected Right')).single.name, 'Chill');
    expect(second.isRight(), isTrue);
    expect(adapter.requests, hasLength(1));
  });

  test('byGenre loads the songs of the top curated playlist', () async {
    final adapter = FakeHttpAdapter((request) async {
      if (request.queryParameters['__call'] == 'search.getPlaylistResults') {
        return jsonResponse(<String, dynamic>{
          'results': <dynamic>[
            <String, dynamic>{'id': 'pl1', 'title': 'Chill Maaro'},
          ],
        });
      }
      return jsonResponse(<String, dynamic>{
        'id': 'pl1',
        'title': 'Chill Maaro',
        'list': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'title': 'Lo-Fi',
            'more_info': <String, dynamic>{},
          },
          <String, dynamic>{
            'id': 's2',
            'title': 'Retro',
            'more_info': <String, dynamic>{},
          },
        ],
      });
    });
    final repo = repoWith(adapter);

    final result = await repo.byGenre(
      const Genre(id: '16', name: 'Chill'),
      limit: 1,
    );

    expect(
      result.getOrElse((_) => fail('expected Right')).single.title,
      'Lo-Fi',
    );
    expect(
      adapter.requests.map((request) => request.queryParameters['__call']),
      <String>['search.getPlaylistResults', 'playlist.getDetails'],
    );
    expect(adapter.requests.first.queryParameters['q'], 'Chill');
    expect(adapter.requests.last.queryParameters['listid'], 'pl1');
  });

  test('byGenre serves a repeated genre from the cache', () async {
    final adapter = FakeHttpAdapter((request) async {
      if (request.queryParameters['__call'] == 'search.getPlaylistResults') {
        return jsonResponse(<String, dynamic>{
          'results': <dynamic>[
            <String, dynamic>{'id': 'pl1'},
          ],
        });
      }
      return jsonResponse(<String, dynamic>{
        'id': 'pl1',
        'list': <dynamic>[
          <String, dynamic>{'id': 's1', 'title': 'Lo-Fi'},
        ],
      });
    });
    final repo = repoWith(adapter);
    const chill = Genre(id: '16', name: 'Chill');

    await repo.byGenre(chill);
    await repo.byGenre(chill);

    expect(adapter.requests, hasLength(2));
  });

  test('byGenre short-circuits a blank name without a request', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(results('x')));

    final result = await repoWith(
      adapter,
    ).byGenre(const Genre(id: 'x', name: '  '));

    expect(result.getOrElse((_) => fail('expected Right')), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test(
    'byGenre returns empty when the catalog has no matching playlist',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(<String, dynamic>{'results': <dynamic>[]}),
      );

      final result = await repoWith(
        adapter,
      ).byGenre(const Genre(id: 'x', name: 'Nope'));

      expect(result.getOrElse((_) => fail('expected Right')), isEmpty);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('byLanguage loads the songs of the top language playlist', () async {
    final adapter = FakeHttpAdapter((request) async {
      if (request.queryParameters['__call'] == 'content.getFeaturedPlaylists') {
        return jsonResponse(<String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{
              'id': 'pl9',
              'title': "Let's Play - Ajay-Atul - Marathi",
            },
          ],
        });
      }
      return jsonResponse(<String, dynamic>{
        'id': 'pl9',
        'title': 'Marathi',
        'list': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'title': 'Yad Lagla',
            'more_info': <String, dynamic>{},
          },
        ],
      });
    });
    final repo = repoWith(adapter);

    final result = await repo.byLanguage(
      const CatalogLanguage(code: 'marathi', name: 'Marathi'),
    );

    expect(
      result.getOrElse((_) => fail('expected Right')).single.title,
      'Yad Lagla',
    );
    expect(adapter.requests.first.queryParameters['languages'], 'marathi');
    expect(adapter.requests.last.queryParameters['listid'], 'pl9');
  });

  test('byLanguage writes the language code into the cache key', () async {
    final adapter = FakeHttpAdapter((request) async {
      if (request.queryParameters['__call'] == 'content.getFeaturedPlaylists') {
        return jsonResponse(<String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{'id': 'pl9'},
          ],
        });
      }
      return jsonResponse(<String, dynamic>{
        'id': 'pl9',
        'list': <dynamic>[
          <String, dynamic>{'id': 's1', 'title': 'Yad Lagla'},
        ],
      });
    });
    final repo = repoWith(adapter);
    const marathi = CatalogLanguage(code: 'marathi', name: 'Marathi');
    const hindi = CatalogLanguage(code: 'hindi', name: 'Hindi');

    await repo.byLanguage(marathi);
    await repo.byLanguage(marathi);
    await repo.byLanguage(hindi);

    expect(adapter.requests, hasLength(4));
  });

  test('byLanguage short-circuits a blank code without a request', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(results('x')));

    final result = await repoWith(
      adapter,
    ).byLanguage(const CatalogLanguage(code: ' ', name: ''));

    expect(result.getOrElse((_) => fail('expected Right')), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('byLanguage returns empty when the language has no playlists', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(<String, dynamic>{'data': <dynamic>[]}),
    );

    final result = await repoWith(
      adapter,
    ).byLanguage(const CatalogLanguage(code: 'konkani', name: 'Konkani'));

    expect(result.getOrElse((_) => fail('expected Right')), isEmpty);
    expect(adapter.requests, hasLength(1));
  });

  Map<String, dynamic> albumFeed(String title, {String type = 'album'}) =>
      <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 'a1',
            'type': type,
            'title': title,
            'language': 'hindi',
          },
        ],
      };

  test('newAlbums maps the release feed and caches it', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(albumFeed('Udta Teer')),
    );
    final repo = repoWith(adapter);

    final first = await repo.newAlbums();
    final second = await repo.newAlbums();

    expect(
      first.getOrElse((_) => fail('expected Right')).single.title,
      'Udta Teer',
    );
    expect(
      second.getOrElse((_) => fail('expected Right')).single.title,
      'Udta Teer',
    );
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.queryParameters['__call'],
      'content.getAlbums',
    );
  });

  test(
    'trendingAlbums maps the trending array and caches it separately',
    () async {
      final adapter = FakeHttpAdapter(
        (request) async =>
            request.queryParameters['__call'] == 'content.getTrending'
            ? jsonResponse(<dynamic>[
                <String, dynamic>{
                  'id': 'a2',
                  'type': 'album',
                  'title': 'Awarapan 2',
                },
              ])
            : jsonResponse(albumFeed('Udta Teer')),
      );
      final repo = repoWith(adapter);

      await repo.trendingAlbums();
      final result = await repo.trendingAlbums();
      await repo.newAlbums();

      expect(
        result.getOrElse((_) => fail('expected Right')).single.title,
        'Awarapan 2',
      );
      expect(adapter.requests, hasLength(2));
    },
  );

  test(
    'popularArtists maps the launch recommendations and caches them',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(<String, dynamic>{
          'artist_recos': <dynamic>[
            <String, dynamic>{
              'id': '459320',
              'title': 'Arijit Singh',
              'image': 'http://c.saavncdn.com/artists/Arijit_150x150.jpg',
            },
          ],
        }),
      );
      final repo = repoWith(adapter);

      final first = await repo.popularArtists();
      final second = await repo.popularArtists();

      expect(
        first.getOrElse((_) => fail('expected Right')).single.name,
        'Arijit Singh',
      );
      expect(
        second.getOrElse((_) => fail('expected Right')).single.id,
        '459320',
      );
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.queryParameters['__call'],
        'webapi.getLaunchData',
      );
    },
  );

  test('popularArtists failures are not cached', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(<String, dynamic>{}, status: 500),
    );
    final repo = repoWith(adapter);

    expect((await repo.popularArtists()).isLeft(), isTrue);
    expect((await repo.popularArtists()).isLeft(), isTrue);
    expect(adapter.requests, hasLength(2));
  });

  test('album feeds take the album nodes only', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(albumFeed('Single', type: 'song')),
    );

    final result = await repoWith(adapter).newAlbums();

    expect(result.getOrElse((_) => fail('expected Right')), isEmpty);
  });

  test('album feed failures are not cached', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(<String, dynamic>{}, status: 500),
    );
    final repo = repoWith(adapter);

    final first = await repo.newAlbums();
    final second = await repo.newAlbums();

    expect(first.isLeft(), isTrue);
    expect(second.isLeft(), isTrue);
    expect(adapter.requests, hasLength(2));
  });
}
