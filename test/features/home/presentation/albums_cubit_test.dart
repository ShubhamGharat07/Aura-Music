import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_albums.dart';
import 'package:aura_music/features/home/domain/usecases/get_trending_albums.dart';
import 'package:aura_music/features/home/presentation/bloc/albums_cubit.dart';

final class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late _MockHomeRepository repository;

  const mixtape = Album(
    id: '11',
    title: 'Mixtape',
    artist: 'Aurora',
    songCount: 4,
  );

  setUp(() {
    repository = _MockHomeRepository();
    when(
      () => repository.newAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([mixtape]));
    when(
      () => repository.trendingAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([mixtape]));
  });

  AlbumsCubit makeCubit() {
    final cubit = AlbumsCubit(
      GetNewAlbums(repository),
      GetTrendingAlbums(repository),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('loads the new album releases', () async {
    final cubit = makeCubit();

    await cubit.load(AlbumsKind.newAlbums);

    expect(cubit.state.kind, AlbumsKind.newAlbums);
    expect(cubit.state.status, AlbumsStatus.ready);
    expect(cubit.state.albums.single.title, 'Mixtape');
    verify(() => repository.newAlbums(limit: any(named: 'limit'))).called(1);
    verifyNever(() => repository.trendingAlbums(limit: any(named: 'limit')));
  });

  test('loads the trending albums', () async {
    final cubit = makeCubit();

    await cubit.load(AlbumsKind.trending);

    expect(cubit.state.kind, AlbumsKind.trending);
    expect(cubit.state.status, AlbumsStatus.ready);
    verify(
      () => repository.trendingAlbums(limit: any(named: 'limit')),
    ).called(1);
    verifyNever(() => repository.newAlbums(limit: any(named: 'limit')));
  });

  test('an empty feed reports empty instead of ready', () async {
    when(
      () => repository.trendingAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Album>[]));
    final cubit = makeCubit();

    await cubit.load(AlbumsKind.trending);

    expect(cubit.state.status, AlbumsStatus.empty);
    expect(cubit.state.albums, isEmpty);
  });

  test('a failure reports the reason', () async {
    when(
      () => repository.newAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
    final cubit = makeCubit();

    await cubit.load(AlbumsKind.newAlbums);

    expect(cubit.state.status, AlbumsStatus.error);
    expect(cubit.state.error, 'offline');
  });

  test('a slow load does not overwrite a newer one', () async {
    final gate = Completer<Either<Failure, List<Album>>>();
    when(
      () => repository.newAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) => gate.future);
    final cubit = makeCubit();

    unawaited(cubit.load(AlbumsKind.newAlbums));
    await pumpEventQueue();
    await cubit.load(AlbumsKind.trending);

    gate.complete(const Right([mixtape]));
    await pumpEventQueue();

    expect(cubit.state.kind, AlbumsKind.trending);
    expect(cubit.state.albums.single.title, 'Mixtape');
  });

  test('unknown route segments fall back to the new releases', () {
    expect(AlbumsKind.fromSlug('trending'), AlbumsKind.trending);
    expect(AlbumsKind.fromSlug('new'), AlbumsKind.newAlbums);
    expect(AlbumsKind.fromSlug('wat'), AlbumsKind.newAlbums);
  });
}
