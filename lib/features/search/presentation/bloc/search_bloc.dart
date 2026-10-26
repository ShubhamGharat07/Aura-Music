import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/entities/search_results.dart';
import 'package:aura_music/features/search/domain/usecases/clear_recent_searches.dart';
import 'package:aura_music/features/search/domain/usecases/get_browse_suggestions.dart';
import 'package:aura_music/features/search/domain/usecases/get_recent_searches.dart';
import 'package:aura_music/features/search/domain/usecases/remove_recent_search.dart';
import 'package:aura_music/features/search/domain/usecases/get_suggestions.dart';
import 'package:aura_music/features/search/domain/usecases/save_recent_search.dart';
import 'package:aura_music/features/search/domain/usecases/search_catalog.dart';
import 'package:aura_music/features/search/presentation/bloc/search_event.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';

/// Search feature BLoC (PRD S04/S05). Depends on use cases only. Type-ahead and
/// submit share a monotonic token so stale responses are dropped (mimics
/// `restartable()` without an extra dependency).

/// Drives the search page.
final class SearchBloc extends Bloc<SearchEvent, SearchState> {
  /// Creates the bloc.
  SearchBloc(
    this._searchCatalog,
    this._getSuggestions,
    this._getBrowseSuggestions,
    this._getRecent,
    this._saveRecent,
    this._clearRecent,
    this._removeRecent,
  ) : super(const SearchState()) {
    on<SearchRecentRequested>(_onRecentRequested);
    on<SearchBrowseRequested>(_onBrowseRequested);
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchHistoryCleared>(_onHistoryCleared);
    on<SearchRecentRemoved>(_onRecentRemoved);
  }

  final SearchCatalog _searchCatalog;
  final GetSuggestions _getSuggestions;
  final GetBrowseSuggestions _getBrowseSuggestions;
  final GetRecentSearches _getRecent;
  final SaveRecentSearch _saveRecent;
  final ClearRecentSearches _clearRecent;
  final RemoveRecentSearch _removeRecent;

  int _token = 0;

  Future<void> _onRecentRequested(
    SearchRecentRequested event,
    Emitter<SearchState> emit,
  ) async {
    final result = await _getRecent(const NoParams());
    result.fold((_) {}, (terms) => emit(state.copyWith(recent: terms)));
  }

  Future<void> _onBrowseRequested(
    SearchBrowseRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(browseStatus: BrowseStatus.loading, browseError: null));
    final result = await _getBrowseSuggestions(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          browseStatus: BrowseStatus.error,
          browseError: failure.message,
        ),
      ),
      (tracks) => emit(
        state.copyWith(browse: tracks, browseStatus: BrowseStatus.ready),
      ),
    );
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      _token++;
      emit(
        state.copyWith(
          status: SearchStatus.idle,
          query: '',
          suggestions: const [],
          results: const SearchResults(),
          error: null,
        ),
      );
      return;
    }
    final token = ++_token;
    emit(
      state.copyWith(
        status: SearchStatus.suggesting,
        query: trimmed,
        error: null,
      ),
    );
    final result = await _getSuggestions(trimmed);
    if (token != _token) return;
    result.fold(
      (_) => emit(state.copyWith(suggestions: const [])),
      (tracks) => emit(state.copyWith(suggestions: tracks)),
    );
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final trimmed = event.query.trim();
    if (trimmed.isEmpty) return;
    final token = ++_token;
    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: trimmed,
        filter: SearchFilter.all,
        suggestions: const [],
        error: null,
      ),
    );
    final result = await _searchCatalog(trimmed);
    if (token != _token) return;
    await result.fold(
      (failure) async => emit(
        state.copyWith(status: SearchStatus.error, error: failure.message),
      ),
      (results) async {
        emit(state.copyWith(status: SearchStatus.ready, results: results));
        await _saveRecent(trimmed);
        final recent = await _getRecent(const NoParams());
        if (token != _token) return;
        recent.fold((_) {}, (terms) => emit(state.copyWith(recent: terms)));
      },
    );
  }

  void _onFilterChanged(SearchFilterChanged event, Emitter<SearchState> emit) =>
      emit(state.copyWith(filter: event.filter));

  Future<void> _onHistoryCleared(
    SearchHistoryCleared event,
    Emitter<SearchState> emit,
  ) async {
    await _clearRecent(const NoParams());
    emit(state.copyWith(recent: const []));
  }

  Future<void> _onRecentRemoved(
    SearchRecentRemoved event,
    Emitter<SearchState> emit,
  ) async {
    await _removeRecent(event.query);
    final result = await _getRecent(const NoParams());
    result.fold((_) {}, (terms) => emit(state.copyWith(recent: terms)));
  }
}
