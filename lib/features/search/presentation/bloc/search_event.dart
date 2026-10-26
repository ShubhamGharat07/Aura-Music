import 'package:equatable/equatable.dart';

import 'package:aura_music/features/search/presentation/bloc/search_state.dart';

/// Base search event (PRD S04/S05).
sealed class SearchEvent extends Equatable {
  /// Creates an event.
  const SearchEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads recent searches (page init).
final class SearchRecentRequested extends SearchEvent {
  /// Creates the event.
  const SearchRecentRequested();
}

/// Loads the idle "Suggestions" list (page becomes visible).
final class SearchBrowseRequested extends SearchEvent {
  /// Creates the event.
  const SearchBrowseRequested();
}

/// Query text changed (drives type-ahead).
final class SearchQueryChanged extends SearchEvent {
  /// Creates the event.
  const SearchQueryChanged(this.query);

  /// New text.
  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Query submitted (enter / suggestion tap).
final class SearchSubmitted extends SearchEvent {
  /// Creates the event.
  const SearchSubmitted(this.query);

  /// Submitted text.
  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Result filter chip changed.
final class SearchFilterChanged extends SearchEvent {
  /// Creates the event.
  const SearchFilterChanged(this.filter);

  /// New filter.
  final SearchFilter filter;

  @override
  List<Object?> get props => <Object?>[filter];
}

/// Removes one recent term.
final class SearchRecentRemoved extends SearchEvent {
  /// Creates the event.
  const SearchRecentRemoved(this.query);

  /// Term to forget.
  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Clears recent history.
final class SearchHistoryCleared extends SearchEvent {
  /// Creates the event.
  const SearchHistoryCleared();
}
