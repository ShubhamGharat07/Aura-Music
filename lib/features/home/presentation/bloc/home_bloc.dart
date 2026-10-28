import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/domain/usecases/get_artist_radio.dart';
import 'package:aura_music/features/home/domain/usecases/get_genre_tracks.dart';
import 'package:aura_music/features/home/domain/usecases/get_home_genres.dart';
import 'package:aura_music/features/home/domain/usecases/get_home_trending.dart';
import 'package:aura_music/features/home/domain/usecases/get_language_tracks.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_albums.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_releases.dart';
import 'package:aura_music/features/home/domain/usecases/get_popular_artists.dart';
import 'package:aura_music/features/home/domain/usecases/get_trending_albums.dart';
import 'package:aura_music/features/home/presentation/bloc/home_event.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Home feed (PRD S03). Loads every section independently; when the device is
/// offline it falls back to local sections (Downloads / Liked / History).

/// Owns the home feed sections.
final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Creates the bloc.
  HomeBloc(
    this._getTrending,
    this._getNewReleases,
    this._getArtistRadio,
    this._getGenres,
    this._getGenreTracks,
    this._getLanguageTracks,
    this._getNewAlbums,
    this._getTrendingAlbums,
    this._getPopularArtists,
    this._watchHistory,
  ) : super(const HomeState()) {
    on<HomeStarted>(_onLoad, transformer: restartable());
    on<HomeRefreshed>(_onLoad, transformer: restartable());
    on<HomeTopPicksStarted>(_onTopPicks, transformer: restartable());
    on<HomeHistoryChanged>(_onHistory);
    on<HomeGenreSelected>(_onGenreSelected, transformer: restartable());
    on<HomeLanguageSelected>(_onLanguageSelected, transformer: restartable());
    _historySub = _watchHistory(limit: 40).listen(
      (entries) => add(HomeHistoryChanged([for (final e in entries) e.track])),
      onError: (_) {},
    );
  }

  final GetHomeTrending _getTrending;
  final GetNewReleases _getNewReleases;
  final GetArtistRadio _getArtistRadio;
  final GetHomeGenres _getGenres;
  final GetGenreTracks _getGenreTracks;
  final GetLanguageTracks _getLanguageTracks;
  final GetNewAlbums _getNewAlbums;
  final GetTrendingAlbums _getTrendingAlbums;
  final GetPopularArtists _getPopularArtists;
  final WatchHistory _watchHistory;

  static const int _limit = 20;
  static const int _continueLimit = 10;

  StreamSubscription<List<HistoryEntry>>? _historySub;
  int _generation = 0;

  /// Reloads every section; completes when the first network pass is done
  /// (used by pull-to-refresh). Bounded so the spinner can never hang.
  Future<void> refresh() async {
    add(const HomeRefreshed());
    await stream
        .firstWhere((s) => !s.isLoading)
        .timeout(const Duration(seconds: 15), onTimeout: () => state);
  }

  /// Loads every section concurrently and emits each one the moment it lands,
  /// so quick picks appear after the fastest call instead of the slowest.
  /// [_generation] discards results from superseded (cancelled) loads.
  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    final generation = ++_generation;
    final seed = state.seedArtist ?? await _readSeed();
    if (generation != _generation) return;
    final genre = state.selectedGenre;
    final language = state.selectedLanguage;
    emit(
      state.copyWith(
        trending: const TrackSection(),
        newReleases: const TrackSection(),
        becauseYou: seed == null
            ? const TrackSection(status: SectionStatus.empty)
            : const TrackSection(),
        genreTracks: genre == null
            ? const TrackSection(status: SectionStatus.empty)
            : const TrackSection(),
        languageTracks: language == null
            ? const TrackSection(status: SectionStatus.empty)
            : const TrackSection(),
        newAlbums: const AlbumSection(),
        trendingAlbums: const AlbumSection(),
        artists: const ArtistSection(),
        seedArtist: seed,
        offline: false,
      ),
    );

    await Future.wait([
      _loadTrending(emit, generation),
      _loadNewReleases(emit, generation),
      _loadArtistRadio(emit, seed, generation),
      _loadGenres(emit, generation),
      _loadNewAlbums(emit, generation),
      _loadTrendingAlbums(emit, generation),
      _loadArtists(emit, generation),
      if (genre != null) _loadGenreTracks(emit, genre),
      if (language != null) _loadLanguageTracks(emit, language),
    ]);
  }

  /// Loads only the chart shown by the Top picks page.
  Future<void> _onTopPicks(
    HomeTopPicksStarted event,
    Emitter<HomeState> emit,
  ) async {
    final generation = ++_generation;
    emit(state.copyWith(trending: const TrackSection()));
    await _loadTrending(emit, generation);
  }

  /// Loads the mood / genre chips. A refresh keeps the chips already on screen
  /// (no flicker) and only swaps them once the catalog answers.
  Future<void> _loadGenres(Emitter<HomeState> emit, int generation) async {
    final result = await _getGenres(const NoParams());
    if (generation != _generation) return;
    if (state.genres.isNotEmpty) return;
    result.fold(
      (failure) => emit(state.copyWith(genresStatus: SectionStatus.error)),
      (genres) => emit(
        state.copyWith(
          genres: genres,
          genresStatus: genres.isEmpty
              ? SectionStatus.empty
              : SectionStatus.ready,
        ),
      ),
    );
  }

  /// Switches the feed to one mood / genre (null = back to "All").
  Future<void> _onGenreSelected(
    HomeGenreSelected event,
    Emitter<HomeState> emit,
  ) async {
    final genre = event.genre;
    if (genre == null) {
      emit(
        state.copyWith(
          clearGenre: true,
          genreTracks: const TrackSection(status: SectionStatus.empty),
        ),
      );
      return;
    }
    if (state.selectedGenre?.id == genre.id &&
        state.genreTracks.status != SectionStatus.error) {
      return;
    }
    emit(
      state.copyWith(selectedGenre: genre, genreTracks: const TrackSection()),
    );
    await _loadGenreTracks(emit, genre);
  }

  /// Loads the songs of [genre]. Results are dropped when the selection moved
  /// on while the request was in flight.
  Future<void> _loadGenreTracks(Emitter<HomeState> emit, Genre genre) async {
    final result = await _getGenreTracks(genre);
    if (state.selectedGenre?.id != genre.id) return;
    result.fold(
      (failure) => emit(
        state.copyWith(genreTracks: TrackSection.failed(failure.message)),
      ),
      (tracks) => emit(state.copyWith(genreTracks: TrackSection.ready(tracks))),
    );
  }

  /// Opens / collapses one language section. Unlike the mood row, the language
  /// row sits at the bottom of the feed, so re-tapping the open chip closes it
  /// instead of reloading.
  Future<void> _onLanguageSelected(
    HomeLanguageSelected event,
    Emitter<HomeState> emit,
  ) async {
    final language = event.language;
    final open = state.selectedLanguage;
    if (language == null ||
        (open?.code == language.code &&
            state.languageTracks.status != SectionStatus.error)) {
      emit(
        state.copyWith(
          clearLanguage: true,
          languageTracks: const TrackSection(status: SectionStatus.empty),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        selectedLanguage: language,
        languageTracks: const TrackSection(),
      ),
    );
    await _loadLanguageTracks(emit, language);
  }

  /// Loads the songs of [language], dropping results for a closed / replaced
  /// section.
  Future<void> _loadLanguageTracks(
    Emitter<HomeState> emit,
    CatalogLanguage language,
  ) async {
    final result = await _getLanguageTracks(language);
    if (state.selectedLanguage?.code != language.code) return;
    result.fold(
      (failure) => emit(
        state.copyWith(languageTracks: TrackSection.failed(failure.message)),
      ),
      (tracks) =>
          emit(state.copyWith(languageTracks: TrackSection.ready(tracks))),
    );
  }

  Future<void> _loadTrending(Emitter<HomeState> emit, int generation) async {
    final result = await _getTrending(_limit);
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          trending: TrackSection.failed(failure.message),
          offline: failure is NetworkFailure,
        ),
      ),
      (tracks) => emit(state.copyWith(trending: TrackSection.ready(tracks))),
    );
  }

  Future<void> _loadNewReleases(Emitter<HomeState> emit, int generation) async {
    final result = await _getNewReleases(_limit);
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        state.copyWith(newReleases: TrackSection.failed(failure.message)),
      ),
      (tracks) => emit(state.copyWith(newReleases: TrackSection.ready(tracks))),
    );
  }

  Future<void> _loadNewAlbums(Emitter<HomeState> emit, int generation) async {
    final result = await _getNewAlbums(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(newAlbums: AlbumSection.failed(failure.message))),
      (albums) => emit(state.copyWith(newAlbums: AlbumSection.ready(albums))),
    );
  }

  Future<void> _loadTrendingAlbums(
    Emitter<HomeState> emit,
    int generation,
  ) async {
    final result = await _getTrendingAlbums(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        state.copyWith(trendingAlbums: AlbumSection.failed(failure.message)),
      ),
      (albums) =>
          emit(state.copyWith(trendingAlbums: AlbumSection.ready(albums))),
    );
  }

  Future<void> _loadArtists(Emitter<HomeState> emit, int generation) async {
    final result = await _getPopularArtists(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(artists: ArtistSection.failed(failure.message))),
      (artists) => emit(state.copyWith(artists: ArtistSection.ready(artists))),
    );
  }

  Future<void> _loadArtistRadio(
    Emitter<HomeState> emit,
    String? seed,
    int generation,
  ) async {
    if (seed == null) return;
    final result = await _getArtistRadio(seed);
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        state.copyWith(becauseYou: TrackSection.failed(failure.message)),
      ),
      (tracks) => emit(state.copyWith(becauseYou: TrackSection.ready(tracks))),
    );
  }

  void _onHistory(HomeHistoryChanged event, Emitter<HomeState> emit) {
    final seen = <String>{};
    final tracks = <Track>[];
    for (final track in event.tracks) {
      if (track.id.isEmpty || !seen.add(track.id)) continue;
      tracks.add(track);
      if (tracks.length >= _continueLimit) break;
    }
    emit(state.copyWith(continueListening: List.unmodifiable(tracks)));
  }

  Future<String?> _readSeed() async {
    try {
      final recent = await _watchHistory(limit: 1).first;
      if (recent.isEmpty) return null;
      final artist = recent.first.track.artist.trim();
      return artist.isEmpty ? null : artist;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _historySub?.cancel();
    return super.close();
  }
}
