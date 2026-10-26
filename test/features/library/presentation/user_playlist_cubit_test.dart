import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';
import 'package:aura_music/features/library/domain/usecases/delete_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/get_user_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/remove_track_from_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/rename_playlist.dart';
import 'package:aura_music/features/library/presentation/bloc/user_playlist_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockUserPlaylistRepository extends Mock
    implements UserPlaylistRepository {}

void main() {
  late _MockUserPlaylistRepository repository;
  late UserPlaylistCubit cubit;

  const track = Track(id: 'jiosaavn:1', title: 'Neon', artist: 'Aurora');
  final playlist = UserPlaylist(
    id: 'p1',
    name: 'Chill',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final detail = UserPlaylistDetail(playlist: playlist, songs: const [track]);

  setUp(() {
    repository = _MockUserPlaylistRepository();
    cubit = UserPlaylistCubit(
      GetUserPlaylist(repository),
      RenamePlaylist(repository),
      DeletePlaylist(repository),
      RemoveTrackFromPlaylist(repository),
    );
    addTearDown(cubit.close);
  });

  test('load puts the detail into the ready state', () async {
    when(() => repository.detail('p1')).thenAnswer((_) async => detail);

    await cubit.load('p1');

    expect(cubit.state.status, UserPlaylistStatus.ready);
    expect(cubit.state.detail, detail);
  });

  test('a missing playlist yields the missing state', () async {
    when(() => repository.detail('p1')).thenAnswer((_) async => null);

    await cubit.load('p1');

    expect(cubit.state.status, UserPlaylistStatus.missing);
  });

  test('rename updates then reloads', () async {
    when(() => repository.detail('p1')).thenAnswer((_) async => detail);
    when(() => repository.rename('p1', 'Focus')).thenAnswer((_) async {});
    await cubit.load('p1');

    await cubit.rename('Focus');

    verify(() => repository.rename('p1', 'Focus')).called(1);
    verify(() => repository.detail('p1')).called(2);
  });

  test('delete delegates to the repository', () async {
    when(() => repository.detail('p1')).thenAnswer((_) async => detail);
    when(() => repository.delete('p1')).thenAnswer((_) async {});
    await cubit.load('p1');

    await cubit.delete();

    verify(() => repository.delete('p1')).called(1);
  });

  test('removeTrack removes then reloads', () async {
    when(() => repository.detail('p1')).thenAnswer((_) async => detail);
    when(
      () => repository.removeTrack('p1', 'jiosaavn:1'),
    ).thenAnswer((_) async {});
    await cubit.load('p1');

    await cubit.removeTrack('jiosaavn:1');

    verify(() => repository.removeTrack('p1', 'jiosaavn:1')).called(1);
    verify(() => repository.detail('p1')).called(2);
  });
}
