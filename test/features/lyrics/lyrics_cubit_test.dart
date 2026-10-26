import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:aura_music/features/lyrics/domain/usecases/get_lyrics.dart';
import 'package:aura_music/features/lyrics/presentation/bloc/lyrics_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockLyricsRepository extends Mock implements LyricsRepository {}

void main() {
  late _MockLyricsRepository repository;
  late LyricsCubit cubit;

  const track = Track(
    id: 'audius:1',
    title: 'Neon Horizon',
    artist: 'Aurora Skies',
  );

  setUpAll(() {
    registerFallbackValue(
      const Track(id: 'fallback', title: 'Fallback', artist: 'x'),
    );
  });

  setUp(() {
    repository = _MockLyricsRepository();
    cubit = LyricsCubit(GetLyrics(repository));
  });

  test('blank title resets to idle without a request', () async {
    await cubit.load(const Track(id: 'x', title: '   ', artist: 'y'));

    expect(cubit.state.status, LyricsStatus.idle);
    verifyNever(() => repository.forTrack(any()));
  });

  test('emits loading then ready when lyrics are found', () async {
    const lyrics = Lyrics(
      synced: true,
      lines: [LyricLine(text: 'hi', time: Duration(seconds: 1))],
    );
    when(
      () => repository.forTrack(any()),
    ).thenAnswer((_) async => const Right(lyrics));

    final statuses = <LyricsStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));

    await cubit.load(track);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(statuses, [LyricsStatus.loading, LyricsStatus.ready]);
    expect(cubit.state.lyrics, lyrics);
    expect(cubit.state.trackId, track.id);
  });

  test('emits empty when there are no lyrics', () async {
    when(
      () => repository.forTrack(any()),
    ).thenAnswer((_) async => const Right(null));

    await cubit.load(track);

    expect(cubit.state.status, LyricsStatus.empty);
  });

  test('emits empty for empty lyrics', () async {
    when(
      () => repository.forTrack(any()),
    ).thenAnswer((_) async => const Right(Lyrics(synced: false, lines: [])));

    await cubit.load(track);

    expect(cubit.state.status, LyricsStatus.empty);
  });

  test('emits error with message on failure', () async {
    when(
      () => repository.forTrack(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await cubit.load(track);

    expect(cubit.state.status, LyricsStatus.error);
    expect(cubit.state.error, 'offline');
  });
}
