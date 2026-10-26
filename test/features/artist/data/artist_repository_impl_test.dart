import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/artist/data/repositories/artist_repository_impl.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';

import '../../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  ArtistRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      ArtistRepositoryImpl(
        JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
      );

  test('returns the artist page with top songs and albums', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'artistId': 'ar1',
        'name': 'Arijit Singh',
        'topSongs': [
          {'id': 's1', 'title': 'Kesariya', 'more_info': <String, dynamic>{}},
        ],
        'topAlbums': [
          {'id': 'al1', 'title': 'Brahmastra'},
        ],
      }),
    );

    final result = await repoWith(adapter).artist('ar1');

    final detail = result.getOrElse((_) => fail('expected Right'));
    expect(detail.artist.name, 'Arijit Singh');
    expect(detail.topSongs.single.title, 'Kesariya');
    expect(detail.albums.single.title, 'Brahmastra');
  });

  test('maps a transport failure to NetworkFailure', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('offline'));

    final result = await repoWith(adapter).artist('ar1');

    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
