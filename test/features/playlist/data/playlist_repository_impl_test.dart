import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/playlist/data/repositories/playlist_repository_impl.dart';

import '../../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  PlaylistRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      PlaylistRepositoryImpl(
        JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
      );

  test('returns the playlist with its songs on success', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'id': 'pl1',
        'title': 'Love',
        'list': [
          {'id': 's1', 'title': 'Song', 'more_info': <String, dynamic>{}},
        ],
      }),
    );

    final result = await repoWith(adapter).playlist('pl1');

    expect(
      result.getOrElse((_) => fail('expected Right')).songs.single.title,
      'Song',
    );
  });

  test('maps a transport failure to NetworkFailure', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('offline'));

    final result = await repoWith(adapter).playlist('pl1');

    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
