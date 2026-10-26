import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';
import 'package:aura_music/features/library/domain/usecases/add_track_to_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/create_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/watch_playlists.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockUserPlaylistRepository extends Mock
    implements UserPlaylistRepository {}

void main() {
  late _MockUserPlaylistRepository repository;
  late PlaylistsCubit cubit;

  final playlists = [
    UserPlaylist(
      id: 'p1',
      name: 'Chill',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  setUp(() {
    registerFallbackValue(const Track(id: 'fallback', title: 'T', artist: 'A'));
    repository = _MockUserPlaylistRepository();
    cubit = PlaylistsCubit(
      WatchPlaylists(repository),
      CreatePlaylist(repository),
      AddTrackToPlaylist(repository),
    );
    addTearDown(cubit.close);
  });

  test('load streams playlists into the ready state', () async {
    when(
      () => repository.watchAll(),
    ).thenAnswer((_) => Stream.value(playlists));

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, PlaylistsStatus.ready);
    expect(cubit.state.playlists, playlists);
  });

  test('an empty stream yields the empty state', () async {
    when(() => repository.watchAll()).thenAnswer((_) => Stream.value(const []));

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, PlaylistsStatus.empty);
  });

  test('create returns the new id', () async {
    when(
      () => repository.create('Focus', description: any(named: 'description')),
    ).thenAnswer((_) async => 'p2');

    expect(await cubit.create('Focus'), 'p2');
  });

  test('addTrack delegates to the repository', () async {
    const track = Track(id: 'a', title: 'A', artist: 'X');
    when(() => repository.addTrack('p1', track)).thenAnswer((_) async {});

    await cubit.addTrack('p1', track);

    verify(() => repository.addTrack('p1', track)).called(1);
  });
}
