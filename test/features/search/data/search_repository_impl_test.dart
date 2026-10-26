import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/search/data/repositories/search_repository_impl.dart';

import '../../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  SearchRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      SearchRepositoryImpl(
        JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
      );

  FakeHttpAdapter fullAdapter() => FakeHttpAdapter(
    (options) async => switch (options.queryParameters['__call']) {
      'search.getResults' => jsonResponse({
        'results': [
          {'id': 's1', 'title': 'Song', 'more_info': <String, dynamic>{}},
        ],
      }),
      'search.getAlbumResults' => jsonResponse({
        'results': [
          {'id': 'a1', 'title': 'Album'},
        ],
      }),
      'search.getArtistResults' => jsonResponse({
        'results': [
          {'id': 'ar1', 'name': 'Artist'},
        ],
      }),
      'search.getPlaylistResults' => jsonResponse({
        'results': [
          {'id': 'p1', 'title': 'Playlist'},
        ],
      }),
      _ => jsonResponse({'results': const []}),
    },
  );

  test('combines the four type queries into grouped results', () async {
    final adapter = fullAdapter();

    final result = await repoWith(adapter).search('neon');

    final results = result.getOrElse((_) => fail('expected Right'));
    expect(results.songs.single.title, 'Song');
    expect(results.albums.single.title, 'Album');
    expect(results.artists.single.name, 'Artist');
    expect(results.playlists.single.title, 'Playlist');
    expect(adapter.requests, hasLength(4));
  });

  test('blank query returns empty results without a request', () async {
    final adapter = FakeHttpAdapter(
      (_) async => throw StateError('no request expected'),
    );

    final result = await repoWith(adapter).search('   ');

    expect(result.getOrElse((_) => fail('expected Right')).isEmpty, isTrue);
    expect(adapter.requests, isEmpty);
  });

  test('suggestions returns songs and forwards the limit', () async {
    final adapter = fullAdapter();

    final result = await repoWith(adapter).suggestions('neon', limit: 5);

    expect(result.getOrElse((_) => fail('expected Right')), hasLength(1));
    expect(adapter.requests.single.queryParameters['n'], '5');
  });

  test('browse ranks trending songs by play count', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'results': [
          {
            'id': 'low',
            'title': 'Low',
            'play_count': '10',
            'more_info': <String, dynamic>{},
          },
          {
            'id': 'high',
            'title': 'High',
            'play_count': '900',
            'more_info': <String, dynamic>{},
          },
        ],
      }),
    );

    final tracks = (await repoWith(
      adapter,
    ).browse(limit: 2)).getOrElse((_) => fail('expected Right'));

    expect(tracks.map((track) => track.title), <String>['High', 'Low']);
    expect(tracks.first.playCount, 900);
  });

  test('maps a transport failure to NetworkFailure', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('offline'));

    final result = await repoWith(adapter).search('neon');

    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
