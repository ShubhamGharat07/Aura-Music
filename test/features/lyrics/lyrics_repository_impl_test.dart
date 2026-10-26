import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/lyrics/data/datasources/lrclib_remote_data_source.dart';
import 'package:aura_music/features/lyrics/data/datasources/unison_remote_data_source.dart';
import 'package:aura_music/features/lyrics/data/repositories/lyrics_repository_impl.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

import '../../helpers/fake_dio.dart';

void main() {
  const track = Track(
    id: 'jiosaavn:1',
    title: 'Neon',
    artist: 'Aurora',
    duration: Duration(seconds: 215),
  );

  LyricsRepositoryImpl repoWith(
    FakeHttpAdapter lrclib,
    FakeHttpAdapter unison,
  ) => LyricsRepositoryImpl(
    LrclibRemoteDataSource(
      dioWithAdapter(lrclib, baseUrl: 'https://lrclib.net'),
    ),
    UnisonRemoteDataSource(
      dioWithAdapter(unison, baseUrl: 'https://unison.boidu.dev'),
    ),
  );

  FakeHttpAdapter lrclibReturning(Object body, {int status = 200}) =>
      FakeHttpAdapter((_) async => jsonResponse(body, status: status));

  FakeHttpAdapter unisonReturning(Object body, {int status = 200}) =>
      FakeHttpAdapter((_) async => jsonResponse(body, status: status));

  FakeHttpAdapter unisonWithLyrics(String lyrics) => FakeHttpAdapter(
    (_) async => jsonResponse({
      'success': true,
      'data': {'lyrics': lyrics, 'format': 'lrc'},
    }),
  );

  FakeHttpAdapter unisonWithTtml(String ttml) => FakeHttpAdapter(
    (_) async => jsonResponse({
      'success': true,
      'data': {'lyrics': ttml, 'format': 'ttml'},
    }),
  );

  test('returns synced lyrics from LRCLIB without touching Unison', () async {
    final repo = repoWith(
      lrclibReturning({'syncedLyrics': '[00:01.00]timed'}),
      FakeHttpAdapter(
        (_) async => throw StateError('Unison should not be queried'),
      ),
    );

    final result = await repo.forTrack(track);

    expect(result.isRight(), isTrue);
    final lyrics = result.getOrElse((_) => null);
    expect(lyrics, isNotNull);
    expect(lyrics!.synced, isTrue);
    expect(lyrics.lines.single.text, 'timed');
  });

  test('falls back to Unison when LRCLIB has no match', () async {
    final repo = repoWith(
      lrclibReturning({'e': 1}, status: 404),
      unisonWithLyrics('[00:02.00]from unison'),
    );

    final result = await repo.forTrack(track);

    final lyrics = result.getOrElse((_) => null);
    expect(lyrics!.lines.single.text, 'from unison');
  });

  test('falls back to Unison when LRCLIB errors', () async {
    final repo = repoWith(
      lrclibReturning({'e': 1}, status: 500),
      unisonWithLyrics('[00:03.00]still here'),
    );

    final result = await repo.forTrack(track);

    expect(result.isRight(), isTrue);
    expect(result.toNullable()!.lines.single.text, 'still here');
  });

  test('parses Unison richsync TTML into synced lines', () async {
    const ttml =
        '<tt><body><div>'
        '<p begin="1.5" end="3"><span begin="1.5">Kayar</span> <span>jo</span></p>'
        '<p begin="30.262" end="32.291"><span>Woh</span> shayar</p>'
        '</div></body></tt>';
    final repo = repoWith(
      lrclibReturning({'e': 1}, status: 404),
      unisonWithTtml(ttml),
    );

    final result = await repo.forTrack(track);

    final lyrics = result.toNullable()!;
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.map((line) => line.text), <String>[
      'Kayar jo',
      'Woh shayar',
    ]);
    expect(lyrics.lines.first.time, const Duration(milliseconds: 1500));
  });

  test('returns Right(null) when both providers miss', () async {
    final repo = repoWith(
      lrclibReturning({'e': 1}, status: 404),
      unisonReturning({'success': false}),
    );

    final result = await repo.forTrack(track);

    expect(result.isRight(), isTrue);
    expect(result.toNullable(), isNull);
  });

  test('maps a failure to a Failure when both providers error', () async {
    final repo = repoWith(
      lrclibReturning({'e': 1}, status: 500),
      unisonReturning({'e': 1}, status: 500),
    );

    final result = await repo.forTrack(track);

    result.match(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps a transport failure to NetworkFailure', () async {
    final repo = repoWith(
      FakeHttpAdapter((_) async => throw Exception('offline')),
      FakeHttpAdapter((_) async => throw Exception('offline')),
    );

    final result = await repo.forTrack(track);

    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
