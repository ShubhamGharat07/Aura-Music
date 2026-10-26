import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:aura_music/features/playlist/domain/usecases/get_playlist.dart';
import 'package:aura_music/features/playlist/presentation/bloc/playlist_cubit.dart';

final class _MockPlaylistRepository extends Mock
    implements PlaylistRepository {}

void main() {
  late _MockPlaylistRepository repository;
  late PlaylistCubit cubit;

  setUp(() {
    repository = _MockPlaylistRepository();
    cubit = PlaylistCubit(GetPlaylist(repository));
  });

  tearDown(() => cubit.close());

  test('load emits loading then ready', () async {
    when(() => repository.playlist('pl1')).thenAnswer(
      (_) async => const Right(
        PlaylistDetail(
          playlist: Playlist(id: 'pl1', title: 'Love'),
        ),
      ),
    );

    expect(cubit.state.status, PlaylistStatus.loading);

    await cubit.load('pl1');

    expect(cubit.state.status, PlaylistStatus.ready);
    expect(cubit.state.detail!.playlist.id, 'pl1');
  });

  test('load emits error on failure', () async {
    when(
      () => repository.playlist('pl1'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    await cubit.load('pl1');

    expect(cubit.state.status, PlaylistStatus.error);
    expect(cubit.state.error, 'boom');
  });
}
