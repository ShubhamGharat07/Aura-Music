import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/album/data/repositories/album_repository_impl.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';

import '../../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  AlbumRepositoryImpl repoWith(FakeHttpAdapter adapter) => AlbumRepositoryImpl(
    JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
  );

  test('returns the album with its songs on success', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'id': 'al1',
        'title': 'Bhediya',
        'list': [
          {'id': 's1', 'title': 'Song', 'more_info': <String, dynamic>{}},
        ],
      }),
    );

    final result = await repoWith(adapter).album('al1');

    expect(
      result.getOrElse((_) => fail('expected Right')).songs.single.title,
      'Song',
    );
  });

  test('maps a transport failure to NetworkFailure', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('offline'));

    final result = await repoWith(adapter).album('al1');

    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
