import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/core/di/injection.dart';
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
import 'package:aura_music/features/search/presentation/pages/search_page.dart';
import 'package:aura_music/features/search/presentation/widgets/search_suggestions_view.dart';

import '../../../helpers/pump_app.dart';

final class _MockSearchRepository extends Mock implements SearchRepository {}

final class _MockSearchHistoryRepository extends Mock
    implements SearchHistoryRepository {}

void main() {
  const track = Track(id: 'jiosaavn:a', title: 'Neon', artist: 'Aurora');

  late _MockSearchRepository searchRepository;
  late _MockSearchHistoryRepository historyRepository;
  late SearchBloc bloc;

  SearchBloc makeBloc({
    Duration suggestionDebounce = AppConstants.searchDebounce,
  }) => SearchBloc(
    SearchCatalog(searchRepository),
    GetSuggestions(searchRepository),
    GetBrowseSuggestions(searchRepository),
    GetRecentSearches(historyRepository),
    SaveRecentSearch(historyRepository),
    ClearRecentSearches(historyRepository),
    RemoveRecentSearch(historyRepository),
    suggestionDebounce: suggestionDebounce,
  );

  setUp(() {
    searchRepository = _MockSearchRepository();
    historyRepository = _MockSearchHistoryRepository();
    when(
      () => historyRepository.recent(),
    ).thenAnswer((_) async => const <String>[]);
    when(() => historyRepository.add(any())).thenAnswer((_) async {});
    when(() => historyRepository.clear()).thenAnswer((_) async {});
    when(() => historyRepository.remove(any())).thenAnswer((_) async {});
    bloc = makeBloc(suggestionDebounce: Duration.zero);
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

  testWidgets(
    'typing debounces live suggestions and the arrow fills the field',
    (tester) async {
      when(
        () => searchRepository.browse(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Right(<Track>[]));
      when(() => searchRepository.suggestions('neo', limit: 6)).thenAnswer(
        (_) async => const Right([
          track,
          Track(id: 'duplicate', title: 'NEON', artist: 'Other'),
        ]),
      );
      when(
        () => searchRepository.suggestions('Neon', limit: 6),
      ).thenAnswer((_) async => const Right([track]));
      when(
        () => searchRepository.search('Neon'),
      ).thenAnswer((_) async => const Right(SearchResults()));
      getIt.registerFactory<SearchBloc>(() => makeBloc());
      addTearDown(() => getIt.unregister<SearchBloc>());

      await pumpApp(tester, const SearchPage());
      final field = find.byType(TextField);
      await tester.enterText(field, 'ne');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'neo');
      await tester.pump();
      expect(find.byType(SearchSuggestionsView), findsOneWidget);
      expect(find.text('Neon'), findsNothing);

      await tester.pump(AppConstants.searchDebounce);
      expect(find.text('Neon'), findsOneWidget);
      expect(find.text('NEON'), findsNothing);
      verifyNever(() => searchRepository.suggestions('ne', limit: 6));

      await tester.tap(find.byTooltip('Fill search with Neon'));
      await tester.pump();
      final textField = tester.widget<TextField>(field);
      expect(textField.controller!.text, 'Neon');
      expect(textField.controller!.selection.baseOffset, 4);
      expect(textField.focusNode!.hasFocus, isTrue);
      verifyNever(() => searchRepository.search(any()));

      await tester.pump(AppConstants.searchDebounce);
      await tester.tap(
        find.descendant(
          of: find.byType(SearchSuggestionsView),
          matching: find.text('Neon'),
        ),
      );
      await tester.pumpAndSettle();
      verify(() => searchRepository.search('Neon')).called(1);

      await tester.enterText(field, 'neo');
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(SearchSuggestionsView),
          matching: find.text('Neon'),
        ),
        findsOneWidget,
      );
      verify(() => searchRepository.suggestions('neo', limit: 6)).called(1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'older suggestions are discarded as soon as the query changes',
    () async {
      final old = Completer<Either<Failure, List<Track>>>();
      final fresh = Completer<Either<Failure, List<Track>>>();
      when(
        () => searchRepository.suggestions('ne', limit: 6),
      ).thenAnswer((_) => old.future);
      when(
        () => searchRepository.suggestions('neo', limit: 6),
      ).thenAnswer((_) => fresh.future);

      bloc.add(const SearchQueryChanged('ne'));
      await pumpEventQueue();
      bloc.add(const SearchQueryChanged('neo'));
      await pumpEventQueue();

      old.complete(const Right([track]));
      await pumpEventQueue();
      expect(bloc.state.query, 'neo');
      expect(bloc.state.suggestions, isEmpty);

      fresh.complete(const Right([track]));
      await pumpEventQueue();
      expect(bloc.state.suggestions, [track]);
    },
  );

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

  test('a debounced echo of the submitted query keeps results', () async {
    when(() => searchRepository.search(any())).thenAnswer(
      (_) async => const Right(SearchResults(songs: <Track>[track])),
    );

    bloc.add(const SearchSubmitted('neon'));
    await pumpEventQueue();
    expect(bloc.state.status, SearchStatus.ready);

    bloc.add(const SearchQueryChanged('neon'));
    await pumpEventQueue();

    expect(bloc.state.status, SearchStatus.ready);
    expect(bloc.state.results.songs, <Track>[track]);
    verifyNever(
      () => searchRepository.suggestions(any(), limit: any(named: 'limit')),
    );
  });

  test('an echo while the submit is in flight does not cancel it', () async {
    final response = Completer<Either<Failure, SearchResults>>();
    when(
      () => searchRepository.search(any()),
    ).thenAnswer((_) => response.future);

    bloc.add(const SearchSubmitted('neon'));
    await pumpEventQueue();
    expect(bloc.state.status, SearchStatus.loading);

    bloc.add(const SearchQueryChanged('neon'));
    await pumpEventQueue();
    expect(bloc.state.status, SearchStatus.loading);

    response.complete(const Right(SearchResults(songs: <Track>[track])));
    await pumpEventQueue();

    expect(bloc.state.status, SearchStatus.ready);
    expect(bloc.state.results.songs, <Track>[track]);
  });

  test('a different query after submit returns to suggestions', () async {
    when(() => searchRepository.search(any())).thenAnswer(
      (_) async => const Right(SearchResults(songs: <Track>[track])),
    );
    when(
      () => searchRepository.suggestions(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Track>[track]));

    bloc.add(const SearchSubmitted('neon'));
    await pumpEventQueue();
    expect(bloc.state.status, SearchStatus.ready);

    bloc.add(const SearchQueryChanged('neonx'));
    await pumpEventQueue();

    expect(bloc.state.status, SearchStatus.suggesting);
    expect(bloc.state.query, 'neonx');
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
