import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/domain/entities/search_results.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';
import 'package:aura_music/features/search/domain/usecases/clear_recent_searches.dart';
import 'package:aura_music/features/search/domain/usecases/get_browse_suggestions.dart';
import 'package:aura_music/features/search/domain/usecases/get_recent_searches.dart';
import 'package:aura_music/features/search/domain/usecases/get_suggestions.dart';
import 'package:aura_music/features/search/domain/usecases/remove_recent_search.dart';
import 'package:aura_music/features/search/domain/usecases/save_recent_search.dart';
import 'package:aura_music/features/search/domain/usecases/search_catalog.dart';
import 'package:aura_music/features/search/presentation/bloc/search_bloc.dart';
import 'package:aura_music/features/search/presentation/bloc/search_event.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';

final class _MockSearchRepository extends Mock implements SearchRepository {}

final class _MockSearchHistoryRepository extends Mock
    implements SearchHistoryRepository {}

void main() {
  const track = Track(id: 'jiosaavn:a', title: 'Neon', artist: 'Aurora');

  late _MockSearchRepository searchRepository;
  late _MockSearchHistoryRepository historyRepository;
  late SearchBloc bloc;

  setUp(() {
    searchRepository = _MockSearchRepository();
    historyRepository = _MockSearchHistoryRepository();
    when(
      () => historyRepository.recent(),
    ).thenAnswer((_) async => const <String>[]);
    when(() => historyRepository.add(any())).thenAnswer((_) async {});
    when(() => historyRepository.clear()).thenAnswer((_) async {});
    when(() => historyRepository.remove(any())).thenAnswer((_) async {});
    bloc = SearchBloc(
      SearchCatalog(searchRepository),
      GetSuggestions(searchRepository),
      GetBrowseSuggestions(searchRepository),
      GetRecentSearches(historyRepository),
      SaveRecentSearch(historyRepository),
      ClearRecentSearches(historyRepository),
      RemoveRecentSearch(historyRepository),
    );
  });

  tearDown(() => bloc.close());

  test('blank query resets to idle without searching', () async {
    bloc.add(const SearchQueryChanged('   '));
    await pumpEventQueue();

    expect(bloc.state.status, SearchStatus.idle);
    verifyNever(() => searchRepository.search(any()));
  });

  test('typing loads suggestions', () async {
    when(
      () => searchRepository.suggestions(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Track>[track]));

    bloc.add(const SearchQueryChanged('neon'));
    await pumpEventQueue();

    expect(bloc.state.status, SearchStatus.suggesting);
    expect(bloc.state.suggestions, <Track>[track]);
  });

  test('submitting emits loading then ready and records history', () async {
    when(() => searchRepository.search(any())).thenAnswer(
      (_) async => const Right(SearchResults(songs: <Track>[track])),
    );

    final statuses = <SearchStatus>[];
    final sub = bloc.stream.listen((state) => statuses.add(state.status));
    bloc.add(const SearchSubmitted('neon'));
    await pumpEventQueue();
    await sub.cancel();

    expect(
      statuses,
      containsAllInOrder(<SearchStatus>[
        SearchStatus.loading,
        SearchStatus.ready,
      ]),
    );
    expect(bloc.state.results.songs, <Track>[track]);
    verify(() => historyRepository.add('neon')).called(1);
  });

  test('a failing submit emits error', () async {
    when(
      () => searchRepository.search(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    bloc.add(const SearchSubmitted('neon'));
    await pumpEventQueue();

    expect(bloc.state.status, SearchStatus.error);
    expect(bloc.state.error, 'boom');
  });

  test('browse request loads ranked suggestions', () async {
    when(
      () => searchRepository.browse(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Track>[track]));

    bloc.add(const SearchBrowseRequested());
    await pumpEventQueue();

    expect(bloc.state.browseStatus, BrowseStatus.ready);
    expect(bloc.state.browse, <Track>[track]);
  });

  test('a failing browse request emits an error', () async {
    when(
      () => searchRepository.browse(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Left(ServerFailure('offline')));

    bloc.add(const SearchBrowseRequested());
    await pumpEventQueue();

    expect(bloc.state.browseStatus, BrowseStatus.error);
    expect(bloc.state.browseError, 'offline');
  });

  test('recent searches load from history', () async {
    when(
      () => historyRepository.recent(),
    ).thenAnswer((_) async => const <String>['neon', 'aurora']);

    bloc.add(const SearchRecentRequested());
    await pumpEventQueue();

    expect(bloc.state.recent, <String>['neon', 'aurora']);
  });

  test('clearing history empties recent', () async {
    when(
      () => historyRepository.recent(),
    ).thenAnswer((_) async => const <String>['neon']);
    bloc.add(const SearchRecentRequested());
    await pumpEventQueue();

    bloc.add(const SearchHistoryCleared());
    await pumpEventQueue();

    expect(bloc.state.recent, isEmpty);
    verify(() => historyRepository.clear()).called(1);
  });
}
