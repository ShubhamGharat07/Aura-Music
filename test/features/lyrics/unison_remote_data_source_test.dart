import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/features/lyrics/data/datasources/unison_remote_data_source.dart';

import '../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://unison.boidu.dev';

  UnisonRemoteDataSource sourceWith(FakeHttpAdapter adapter) =>
      UnisonRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl));

  test('returns lyrics and forwards all query params', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'success': true,
        'data': {'lyrics': '[00:01.00]hi', 'format': 'lrc'},
      }),
    );

    final payload = await sourceWith(adapter).fetch(
      title: 'Neon',
      artist: 'Aurora',
      album: 'Nightfall',
      durationSeconds: 215,
    );

    expect(payload?.lyrics, '[00:01.00]hi');
    expect(payload?.format, 'lrc');
    final request = adapter.requests.single;
    expect(request.path, '/lyrics');
    expect(request.queryParameters['song'], 'Neon');
    expect(request.queryParameters['artist'], 'Aurora');
    expect(request.queryParameters['album'], 'Nightfall');
    expect(request.queryParameters['duration'], 215);
  });

  test('reports the declared format (ttml) lowercased', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'success': true,
        'data': {'lyrics': '<tt/>', 'format': 'TTML'},
      }),
    );

    final payload = await sourceWith(adapter).fetch(title: 'a', artist: 'b');

    expect(payload?.format, 'ttml');
  });

  test('omits optional params when absent', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'success': false}),
    );

    await sourceWith(
      adapter,
    ).fetch(title: 'Neon', artist: 'Aurora', album: '', durationSeconds: 0);

    final params = adapter.requests.single.queryParameters;
    expect(params.containsKey('album'), isFalse);
    expect(params.containsKey('duration'), isFalse);
  });

  test('returns null when success is false or lyrics empty', () async {
    final miss = FakeHttpAdapter((_) async => jsonResponse({'success': false}));
    expect(await sourceWith(miss).fetch(title: 'a', artist: 'b'), isNull);

    final empty = FakeHttpAdapter(
      (_) async => jsonResponse({
        'success': true,
        'data': {'lyrics': '   '},
      }),
    );
    expect(await sourceWith(empty).fetch(title: 'a', artist: 'b'), isNull);
  });

  test('maps a 404 to null (no lyrics, not an error)', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'e': 1}, status: 404),
    );
    expect(await sourceWith(adapter).fetch(title: 'a', artist: 'b'), isNull);
  });

  test('maps a 5xx response to ServerException', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({'e': 1}, status: 500),
    );
    await expectLater(
      sourceWith(adapter).fetch(title: 'a', artist: 'b'),
      throwsA(isA<ServerException>()),
    );
  });

  test('maps a transport failure to NetworkException', () async {
    final adapter = FakeHttpAdapter((_) async => throw Exception('socket'));
    await expectLater(
      sourceWith(adapter).fetch(title: 'a', artist: 'b'),
      throwsA(isA<NetworkException>()),
    );
  });
}
