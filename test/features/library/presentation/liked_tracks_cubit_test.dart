import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';
import 'package:aura_music/features/library/domain/usecases/remove_liked_track.dart';
import 'package:aura_music/features/library/domain/usecases/toggle_like.dart';
import 'package:aura_music/features/library/domain/usecases/watch_liked_tracks.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockLikedSongsRepository extends Mock
    implements LikedSongsRepository {}

void main() {
  late _MockLikedSongsRepository repository;
  late LikedTracksCubit cubit;

  const liked = [
    Track(id: 'l1', title: 'Neon', artist: 'Aurora'),
    Track(id: 'l2', title: 'Glass', artist: 'Lumen'),
  ];

  setUp(() {
    registerFallbackValue(const Track(id: 'fallback', title: 'T', artist: 'A'));
    repository = _MockLikedSongsRepository();
    cubit = LikedTracksCubit(
      WatchLikedTracks(repository),
      ToggleLike(repository),
      RemoveLikedTrack(repository),
    );
    addTearDown(cubit.close);
  });

  test('load streams liked tracks into the ready state', () async {
    when(() => repository.watchLiked()).thenAnswer((_) => Stream.value(liked));

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, LikedTracksStatus.ready);
    expect(cubit.state.tracks, liked);
  });

  test('an empty stream yields the empty state', () async {
    when(
      () => repository.watchLiked(),
    ).thenAnswer((_) => Stream.value(const []));

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, LikedTracksStatus.empty);
  });

  test('search filters the visible list', () async {
    when(() => repository.watchLiked()).thenAnswer((_) => Stream.value(liked));
    await cubit.load();
    await pumpEventQueue();

    cubit.search('lumen');

    expect(cubit.state.visible.single.id, 'l2');
  });

  test('cycleSort rotates recent -> title -> artist -> recent', () {
    expect(cubit.state.sort, LikedSort.recent);
    cubit.cycleSort();
    expect(cubit.state.sort, LikedSort.title);
    cubit.cycleSort();
    expect(cubit.state.sort, LikedSort.artist);
    cubit.cycleSort();
    expect(cubit.state.sort, LikedSort.recent);
  });

  test('unlike and toggle delegate to the repository', () async {
    when(() => repository.remove('l1')).thenAnswer((_) async {});
    when(() => repository.toggle(any())).thenAnswer((_) async => true);

    await cubit.unlike('l1');
    await cubit.toggle(liked.first);

    verify(() => repository.remove('l1')).called(1);
    verify(() => repository.toggle(liked.first)).called(1);
  });
}
