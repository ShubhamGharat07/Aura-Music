import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura_music/features/catalog/domain/usecases/get_trending_tracks.dart';
import 'package:aura_music/features/library/presentation/bloc/library_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late _MockCatalogRepository repository;
  late LibraryCubit cubit;

  const discover = [
    Track(id: 'd1', title: 'Neon', artist: 'Aurora'),
    Track(id: 'd2', title: 'Glass', artist: 'Lumen'),
  ];

  setUp(() {
    repository = _MockCatalogRepository();
    cubit = LibraryCubit(GetTrendingTracks(repository));
    addTearDown(cubit.close);
  });

  test('load emits loading then ready with the discover feed', () async {
    when(
      () => repository.trending(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(discover));

    final states = <LibraryStatus>[];
    final sub = cubit.stream.listen((s) => states.add(s.status));

    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states, [LibraryStatus.loading, LibraryStatus.ready]);
    expect(cubit.state.discover, discover);
  });

  test('load surfaces a failure message', () async {
    when(
      () => repository.trending(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await cubit.load();

    expect(cubit.state.status, LibraryStatus.error);
    expect(cubit.state.error, 'offline');
  });

  test('selectFilter switches chip and clears the selection', () {
    cubit.select('album:neon');

    cubit.selectFilter(LibraryFilter.albums);

    expect(cubit.state.filter, LibraryFilter.albums);
    expect(cubit.state.selectedId, isNull);
  });

  test('toggleView flips grid and list', () {
    expect(cubit.state.view, LibraryView.grid);

    cubit.toggleView();

    expect(cubit.state.view, LibraryView.list);
  });

  test('cycleSort rotates recent and title', () {
    cubit.cycleSort();
    expect(cubit.state.sort, LibrarySortOrder.title);

    cubit.cycleSort();
    expect(cubit.state.sort, LibrarySortOrder.recent);
  });

  test('select sets then clears the selected id', () {
    cubit.select('album:neon');
    expect(cubit.state.selectedId, 'album:neon');

    cubit.select(null);
    expect(cubit.state.selectedId, isNull);
  });
}
