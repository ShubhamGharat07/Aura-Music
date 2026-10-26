import 'package:equatable/equatable.dart';

import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Home events (PRD S03): start on first build, refresh on pull-to-refresh.

/// Base home event.
sealed class HomeEvent extends Equatable {
  /// Creates a home event.
  const HomeEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the feed for the first time.
final class HomeStarted extends HomeEvent {
  /// Creates the started event.
  const HomeStarted();
}

/// Reloads every section (pull-to-refresh).
final class HomeRefreshed extends HomeEvent {
  /// Creates the refreshed event.
  const HomeRefreshed();
}

/// New play-history snapshot arrived (drives "Continue listening").
final class HomeHistoryChanged extends HomeEvent {
  /// Creates the history-changed event.
  const HomeHistoryChanged(this.tracks);

  /// Played tracks, newest first.
  final List<Track> tracks;

  @override
  List<Object?> get props => [tracks];
}

/// A mood / genre chip was tapped (null = the "All" chip).
final class HomeGenreSelected extends HomeEvent {
  /// Creates the genre-selected event.
  const HomeGenreSelected(this.genre);

  /// Selected mood / genre, or null to clear the filter.
  final Genre? genre;

  @override
  List<Object?> get props => [genre];
}

/// A language chip was tapped (null collapses the section).
final class HomeLanguageSelected extends HomeEvent {
  /// Creates the language-selected event.
  const HomeLanguageSelected(this.language);

  /// Selected language, or null to collapse the section.
  final CatalogLanguage? language;

  @override
  List<Object?> get props => [language];
}
