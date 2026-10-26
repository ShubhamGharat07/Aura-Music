import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/features/lyrics/data/datasources/lrclib_remote_data_source.dart';

import '../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://lrclib.net';

  test('returns synced and plain lyrics and sends all query params', () async {
    final adapter = FakeHttpAdapter(
      (_) async =>
          jsonResponse({'syncedLyrics': '[00:01.00]hi', 'plainLyrics': 'hi'}),
    );
    final ds = LrclibRemoteDataSource(
      dioWithAdapter(adapter, baseUrl: baseUrl),
    );

    final payload = await ds.fetch(
      trackName: 'Neon',
      artistName: 'Aurora',
      albumName: 'Nightfall',
      durationSeconds: 215,
    );

    expect(payload?.syncedLyrics, '[00:01.00]hi');
    expect(payload?.plainLyrics, 'hi');

    final request = adapter.requests.single;
    expect(request.path, '/api/get');
    expect(request.queryParameters['track_name'], 'Neon');
    expect(request.queryParameters['artist_name'], 'Aurora');
    expect(request.queryParameters['album_name'], 'Nightfall');
    expect(request.queryParameters['duration'], 215);
  });

  test('omits optional params when absent', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'plainLyrics': 'x'}),
    );
    final ds = LrclibRemoteDataSource(
      dioWithAdapter(adapter, baseUrl: baseUrl),
    );

    await ds.fetch(
      trackName: 'Neon',
      artistName: 'Aurora',
      albumName: '',
      durationSeconds: 0,
    );

    final params = adapter.requests.single.queryParameters;
    expect(params.containsKey('album_name'), isFalse);
    expect(params.containsKey('duration'), isFalse);
  });

  test('maps a 404 to null (no lyrics, not an error)', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'error': 'not found'}, status: 404),
    );
    final ds = LrclibRemoteDataSource(
      dioWithAdapter(adapter, baseUrl: baseUrl),
    );

    expect(await ds.fetch(trackName: 'x', artistName: 'y'), isNull);
  });

  test('maps a 5xx response to ServerException', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'e': 1}, status: 500),
    );
    final ds = LrclibRemoteDataSource(
      dioWithAdapter(adapter, baseUrl: baseUrl),
    );

    await expectLater(
      ds.fetch(trackName: 'x', artistName: 'y'),
      throwsA(isA<ServerException>()),
    );
  });

  test('maps a transport failure to NetworkException', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('socket'));
    final ds = LrclibRemoteDataSource(
      dioWithAdapter(adapter, baseUrl: baseUrl),
    );

    await expectLater(
      ds.fetch(trackName: 'x', artistName: 'y'),
      throwsA(isA<NetworkException>()),
    );
  });
}
