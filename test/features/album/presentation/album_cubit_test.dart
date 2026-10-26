import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/album/domain/repositories/album_repository.dart';
import 'package:aura_music/features/album/domain/usecases/get_album.dart';
import 'package:aura_music/features/album/presentation/bloc/album_cubit.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

final class _MockAlbumRepository extends Mock implements AlbumRepository {}

void main() {
  late _MockAlbumRepository repository;
  late AlbumCubit cubit;

  setUp(() {
    repository = _MockAlbumRepository();
    cubit = AlbumCubit(GetAlbum(repository));
  });

  tearDown(() => cubit.close());

  test('load emits loading then ready', () async {
    when(() => repository.album('al1')).thenAnswer(
      (_) async => const Right(
        AlbumDetail(
          album: Album(id: 'al1', title: 'T', artist: 'A'),
        ),
      ),
    );

    expect(cubit.state.status, AlbumStatus.loading);

    await cubit.load('al1');

    expect(cubit.state.status, AlbumStatus.ready);
    expect(cubit.state.detail!.album.id, 'al1');
  });

  test('load emits error on failure', () async {
    when(
      () => repository.album('al1'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    await cubit.load('al1');

    expect(cubit.state.status, AlbumStatus.error);
    expect(cubit.state.error, 'boom');
  });
}
