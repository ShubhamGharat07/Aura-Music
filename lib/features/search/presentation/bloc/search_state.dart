import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/domain/entities/search_results.dart';

/// Search phase (drives which view the page shows).
enum SearchStatus {
  /// Empty query: recent searches + browse grid.
  idle,

  /// Type-ahead suggestions in flight / shown.
  suggesting,

  /// Submitted query in flight.
  loading,

  /// Grouped results ready.
  ready,

  /// Submitted query failed.
  error,
}

/// Load state of the idle "Suggestions" list (PRD S04).
enum BrowseStatus {
  /// Fetch in flight.
  loading,

  /// Loaded (list may be empty).
  ready,

  /// Fetch failed.
  error,
}

/// Result-group filter (PRD S05 filter chips).
enum SearchFilter {
  /// Everything.
  all('All'),

  /// Songs only.
  songs('Songs'),

  /// Albums only.
  albums('Albums'),

  /// Artists only.
  artists('Artists'),

  /// Playlists only.
  playlists('Playlists');

  const SearchFilter(this.label);

  /// Chip label.
  final String label;
}

const Object _unset = Object();

/// Immutable search state.
final class SearchState extends Equatable {
  /// Creates the state.
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.suggestions = const <Track>[],
    this.results = const SearchResults(),
    this.filter = SearchFilter.all,
    this.recent = const <String>[],
    this.browse = const <Track>[],
    this.browseStatus = BrowseStatus.loading,
    this.error,
    this.browseError,
  });

  /// Current phase.
  final SearchStatus status;

  /// Active query text.
  final String query;

  /// Type-ahead suggestions for [query].
  final List<Track> suggestions;

  /// Grouped results for the submitted query.
  final SearchResults results;

  /// Active result filter.
  final SearchFilter filter;

  /// Recent terms, newest first.
  final List<String> recent;

  /// Ranked top songs for the idle "Suggestions" list.
  final List<Track> browse;

  /// Load state of [browse].
  final BrowseStatus browseStatus;

  /// Error message (when [status] is [SearchStatus.error]).
  final String? error;

  /// Error message (when [browseStatus] is [BrowseStatus.error]).
  final String? browseError;

  /// Match count backing [filter]'s chip badge.
  int countFor(SearchFilter filter) => switch (filter) {
    SearchFilter.all =>
      results.songs.length +
          results.albums.length +
          results.artists.length +
          results.playlists.length,
    SearchFilter.songs => results.songs.length,
    SearchFilter.albums => results.albums.length,
    SearchFilter.artists => results.artists.length,
    SearchFilter.playlists => results.playlists.length,
  };

  /// Copies with overrides; `error` / `browseError` are cleared only when
  /// passed an explicit `null`.
  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Track>? suggestions,
    SearchResults? results,
    SearchFilter? filter,
    List<String>? recent,
    List<Track>? browse,
    BrowseStatus? browseStatus,
    Object? error = _unset,
    Object? browseError = _unset,
  }) => SearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    suggestions: suggestions ?? this.suggestions,
    results: results ?? this.results,
    filter: filter ?? this.filter,
    recent: recent ?? this.recent,
    browse: browse ?? this.browse,
    browseStatus: browseStatus ?? this.browseStatus,
    error: identical(error, _unset) ? this.error : error as String?,
    browseError: identical(browseError, _unset)
        ? this.browseError
        : browseError as String?,
  );

  @override
  List<Object?> get props => [
    status,
    query,
    suggestions,
    results,
    filter,
    recent,
    browse,
    browseStatus,
    error,
    browseError,
  ];
}
